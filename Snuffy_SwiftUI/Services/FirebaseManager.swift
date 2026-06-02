import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreLocation
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()

    // MARK: - Pet Data

    func savePetDataToFirebase(data: [String: Any], petId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).setData(data) { error in
            completion(error)
        }
    }

    // MARK: - Caretaker Data

    func saveCaretakerData(caretakers: [Caretakers], completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()

        for caretaker in caretakers {
            let caretakerRef = db.collection("caretakers").document(caretaker.caretakerId)
            group.enter()

            let imageName = caretaker.profilePic ?? "placeholder_image"

            uploadProfileImage(imageName: imageName, caretakerId: caretaker.caretakerId) { profileImageUrl, error in
                if let error = error {
                    completion(error)
                    group.leave()
                    return
                }

                let updatedCaretaker = caretaker
                updatedCaretaker.profilePic = profileImageUrl ?? ""

                self.saveCaretakerToFirestore(caretaker: updatedCaretaker, caretakerRef: caretakerRef) { error in
                    completion(error)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(nil)
        }
    }

    func saveCaretakerToFirestore(caretaker: Caretakers, caretakerRef: DocumentReference, completion: @escaping (Error?) -> Void) {
        do {
            let data = try Firestore.Encoder().encode(caretaker)
            caretakerRef.setData(data) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func uploadProfileImage(imageName: String, caretakerId: String, completion: @escaping (String?, Error?) -> Void) {
        guard let image = UIImage(named: imageName) else {
            completion(nil, NSError(domain: "ImageError",
                                    code: 404,
                                    userInfo: [NSLocalizedDescriptionKey: "Image not found in assets"]))
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(caretakerId).jpg")

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(nil, error)
                    } else {
                        completion(url?.absoluteString, nil)
                    }
                }
            }
        } else {
            completion(nil, NSError(domain: "ImageError",
                                    code: 500,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
        }
    }

    // MARK: - Caretaker Schedule Requests

    func saveScheduleRequestData(data: [String: Any], completion: @escaping (Error?) -> Void) {
        let collection = db.collection("scheduleRequests")
        if let requestId = data["requestId"] as? String {
            collection.document(requestId).setData(data) { error in
                completion(error)
            }
        } else {
            completion(NSError(domain: "",
                               code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "Missing requestId in data"]))
        }
    }

    func autoAssignCaretaker(petName: String, requestId: String, userLocation: CLLocation?, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").whereField("petName", isEqualTo: petName).getDocuments { (snapshot, error) in
            if let error = error {
                completion(error)
                return
            }

            guard let petDoc = snapshot?.documents.first else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Pet not found"]))
                return
            }

            guard let ownerId = petDoc.data()["ownerID"] as? String else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Owner ID not found in pet document"]))
                return
            }

            guard let currentUserId = Auth.auth().currentUser?.uid, currentUserId == ownerId else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Current user is not the owner of the pet"]))
                return
            }

            if let providedLocation = userLocation {
                self.assignCaretaker(using: providedLocation, requestId: requestId, completion: completion)
            } else {
                self.db.collection("users").document(ownerId).getDocument { (userSnapshot, error) in
                    if let error = error {
                        completion(error)
                        return
                    }

                    guard let userData = userSnapshot?.data() else {
                        completion(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
                        return
                    }

                    guard let loc = Self.parseLocation(from: userData) else {
                        completion(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "User location not found"]))
                        return
                    }

                    self.assignCaretaker(using: loc, requestId: requestId, completion: completion)
                }
            }
        }
    }

    private func assignCaretaker(using userLocation: CLLocation,
                                 requestId: String,
                                 completion: @escaping (Error?) -> Void) {
        db.collection("caretakers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { (caretakerSnapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }

                guard let caretakerDocs = caretakerSnapshot?.documents else {
                    completion(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No available caretakers found"]))
                    return
                }

                let sortedCaretakers = caretakerDocs.compactMap { doc -> (DocumentReference, Caretakers, Double)? in
                    let data = doc.data()
                    guard let caretaker = try? Firestore.Decoder().decode(Caretakers.self, from: data) else {
                        return nil
                    }

                    guard let caretakerLoc = Self.parseLocation(from: data) else {
                        return nil
                    }

                    let distanceInKm = max(userLocation.distance(from: caretakerLoc) / 1000.0, 0.001)
                    let score = Double(caretaker.experience) / distanceInKm
                    return (doc.reference, caretaker, score)
                }
                .sorted { $0.2 > $1.2 }

                guard let (selectedCaretakerRef, selectedCaretaker, _) = sortedCaretakers.first else {
                    completion(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No suitable caretakers found"]))
                    return
                }

                let requestRef = self.db.collection("scheduleRequests").document(requestId)
                requestRef.updateData([
                    "caretakerId": selectedCaretaker.caretakerId,
                    "status": "pending"
                ]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }

                    selectedCaretakerRef.updateData([
                        "pendingRequests": FieldValue.arrayUnion([requestId])
                    ]) { error in
                        completion(error)
                    }
                }
            }
    }

    // MARK: - Dog Walker Data

    func saveDogWalkerData(dogWalkers: [DogWalker], completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var overallError: Error?

        for dogWalker in dogWalkers {
            group.enter()
            let dogWalkerRef = db.collection("dogwalkers").document(dogWalker.dogWalkerId)

            if let pic = dogWalker.profilePic, pic.starts(with: "http") {
                self.saveDogWalkerToFirestore(dogWalker: dogWalker, dogWalkerRef: dogWalkerRef) { error in
                    if let error = error { overallError = error }
                    group.leave()
                }
            } else {
                uploadDogWalkerProfileImage(imageName: dogWalker.profilePic ?? "placeholder",
                                            dogWalkerId: dogWalker.dogWalkerId) { profileImageUrl, error in
                    if let error = error {
                        overallError = error
                        group.leave()
                        return
                    }

                    let updatedDogWalker = dogWalker
                    updatedDogWalker.profilePic = profileImageUrl ?? ""

                    self.saveDogWalkerToFirestore(dogWalker: updatedDogWalker, dogWalkerRef: dogWalkerRef) { error in
                        if let error = error { overallError = error }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(overallError)
        }
    }

    func saveDogWalkerToFirestore(dogWalker: DogWalker, dogWalkerRef: DocumentReference, completion: @escaping (Error?) -> Void) {
        do {
            let data = try Firestore.Encoder().encode(dogWalker)
            dogWalkerRef.setData(data, completion: completion)
        } catch {
            completion(error)
        }
    }

    func uploadDogWalkerProfileImage(imageName: String, dogWalkerId: String, completion: @escaping (String?, Error?) -> Void) {
        guard let image = UIImage(named: imageName) else {
            completion(nil, NSError(domain: "ImageError",
                                    code: 404,
                                    userInfo: [NSLocalizedDescriptionKey: "Image not found in assets"]))
            return
        }

        let storageRef = Storage.storage().reference().child("dogwalker_profile_pictures/\(dogWalkerId).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil, NSError(domain: "ImageError",
                                    code: 500,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(nil, error)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(url?.absoluteString, nil)
                }
            }
        }
    }

    // MARK: - Dog Walker Requests

    func saveDogWalkerRequestData(data: [String: Any], completion: @escaping (Error?) -> Void) {
        let collection = db.collection("dogWalkerRequests")
        guard let requestId = data["requestId"] as? String else {
            completion(NSError(domain: "",
                               code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "Missing requestId in data"]))
            return
        }
        collection.document(requestId).setData(data) { error in
            completion(error)
        }
    }

    func autoAssignDogWalker(petName: String,
                             requestId: String,
                             userLocation: CLLocation?,
                             completion: @escaping (Error?) -> Void) {
        db.collection("Pets").whereField("petName", isEqualTo: petName).getDocuments { (snapshot, error) in
            if let error = error {
                completion(error)
                return
            }

            guard let petDoc = snapshot?.documents.first else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Pet not found"]))
                return
            }

            guard let ownerId = petDoc.data()["ownerID"] as? String else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Owner ID not found in pet document"]))
                return
            }

            guard let currentUserId = Auth.auth().currentUser?.uid, currentUserId == ownerId else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Current user is not the owner of the pet"]))
                return
            }

            if let providedLocation = userLocation {
                self.assignDogWalker(using: providedLocation, requestId: requestId, completion: completion)
            } else {
                self.db.collection("users").document(ownerId).getDocument { (userSnapshot, error) in
                    if let error = error {
                        completion(error)
                        return
                    }

                    guard let userData = userSnapshot?.data() else {
                        completion(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
                        return
                    }

                    guard let loc = Self.parseLocation(from: userData) else {
                        completion(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "User location not found"]))
                        return
                    }

                    self.assignDogWalker(using: loc, requestId: requestId, completion: completion)
                }
            }
        }
    }

    private func assignDogWalker(using userLocation: CLLocation,
                                   requestId: String,
                                   completion: @escaping (Error?) -> Void) {
        db.collection("dogwalkers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { (walkerSnapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }

                guard let walkerDocs = walkerSnapshot?.documents, !walkerDocs.isEmpty else {
                    completion(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No available dog walkers found"]))
                    return
                }

                // Score: 70% proximity (inverse distance) + 30% rating (normalized to 5.0)
                let weightedWalkers = walkerDocs.compactMap { doc -> (DocumentReference, DogWalker, Double)? in
                    let data = doc.data()
                    guard let dogWalker = try? Firestore.Decoder().decode(DogWalker.self, from: data) else {
                        return nil
                    }

                    guard let wLoc = Self.parseLocation(from: data) else { return nil }
                    let distance = userLocation.distance(from: wLoc)
                    let distanceScore = 1.0 / (distance + 1.0)
                    let ratingValue = Double(dogWalker.rating ?? "4.0") ?? 4.0
                    let ratingScore = ratingValue / 5.0
                    let combinedScore = (distanceScore * 0.7) + (ratingScore * 0.3)

                    return (doc.reference, dogWalker, combinedScore)
                }
                .sorted { $0.2 > $1.2 }

                guard let (selectedWalkerRef, selectedWalker, _) = weightedWalkers.first else {
                    completion(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No suitable dog walkers found"]))
                    return
                }

                let requestRef = self.db.collection("dogWalkerRequests").document(requestId)
                requestRef.updateData([
                    "dogWalkerId": selectedWalker.dogWalkerId,
                    "status": "pending"
                ]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }

                    selectedWalkerRef.updateData([
                        "pendingRequests": FieldValue.arrayUnion([requestId])
                    ]) { error in
                        completion(error)
                    }
                }
            }
    }

    // MARK: - Accept / Reject Dog Walker

    func acceptDogWalkerRequest(dogWalkerId: String, requestId: String, completion: @escaping (Error?) -> Void) {
        let dogWalkerRef = db.collection("dogwalkers").document(dogWalkerId)
        let requestRef = db.collection("dogWalkerRequests").document(requestId)

        requestRef.updateData(["status": "accepted"]) { error in
            if let error = error {
                completion(error)
                return
            }
            dogWalkerRef.setData(["status": "assigned"], merge: true) { error in
                completion(error)
            }
        }
    }

    func rejectDogWalkerRequest(dogWalkerId: String,
                                requestId: String,
                                sortedDogWalkers: [(DocumentReference, DogWalker, CLLocationDistance)],
                                completion: @escaping (Error?) -> Void) {
        let requestRef = db.collection("dogWalkerRequests").document(requestId)

        requestRef.updateData(["status": "rejected"]) { error in
            if let error = error {
                completion(error)
                return
            }

            var remainingDogWalkers = sortedDogWalkers
            remainingDogWalkers.removeFirst()

            if let (nextWalkerRef, nextWalker, _) = remainingDogWalkers.first {
                requestRef.updateData([
                    "dogWalkerId": nextWalker.dogWalkerId,
                    "status": "pending"
                ]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    nextWalkerRef.updateData([
                        "pendingRequests": FieldValue.arrayUnion([requestId])
                    ]) { error in
                        completion(error)
                    }
                }
            } else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "No dog walkers available for reassignment"]))
            }
        }
    }

    // MARK: - Fetch Requests & Bookings

    func fetchAssignedRequests(for caretakerId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) {
        db.collection("scheduleRequests")
            .whereField("caretakerId", isEqualTo: caretakerId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }

                var requests: [ScheduleCaretakerRequest] = []
                let group = DispatchGroup()

                for document in snapshot?.documents ?? [] {
                    var requestData = document.data()
                    requestData["requestId"] = document.documentID

                    guard let petName = requestData["petName"] as? String else { continue }

                    group.enter()
                    self.db.collection("Pets")
                        .whereField("petName", isEqualTo: petName)
                        .getDocuments { petSnapshot, error in
                            if error != nil {
                                group.leave()
                                return
                            }

                            guard let petDocument = petSnapshot?.documents.first else {
                                group.leave()
                                return
                            }

                            requestData["petId"] = petDocument.documentID
                            let petData = petDocument.data()
                            requestData["petBreed"] = petData["petBreed"] as? String ?? "Unknown"
                            requestData["petImageUrl"] = petData["petImage"] as? String ?? ""

                            if let scheduleRequest = ScheduleCaretakerRequest(from: requestData) {
                                requests.append(scheduleRequest)
                            }

                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(requests)
                }
            }
    }

    func fetchAssignedDogWalkerRequests(for dogWalkerId: String, completion: @escaping ([ScheduleDogWalkerRequest]) -> Void) {
        db.collection("dogWalkerRequests")
            .whereField("dogWalkerId", isEqualTo: dogWalkerId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }

                var requests: [ScheduleDogWalkerRequest] = []
                let group = DispatchGroup()

                for document in snapshot?.documents ?? [] {
                    var requestData = document.data()
                    requestData["requestId"] = document.documentID

                    guard let petName = requestData["petName"] as? String else { continue }

                    group.enter()
                    self.db.collection("Pets")
                        .whereField("petName", isEqualTo: petName)
                        .getDocuments { petSnapshot, error in
                            if error != nil {
                                group.leave()
                                return
                            }

                            guard let petDocument = petSnapshot?.documents.first else {
                                group.leave()
                                return
                            }

                            requestData["petId"] = petDocument.documentID
                            let petData = petDocument.data()
                            requestData["petBreed"] = petData["petBreed"] as? String ?? "Unknown"
                            requestData["petImageUrl"] = petData["petImage"] as? String ?? ""

                            if let scheduleRequest = ScheduleDogWalkerRequest(from: requestData) {
                                requests.append(scheduleRequest)
                            }

                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(requests)
                }
            }
    }

    func fetchOwnerBookings(for userId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) {
        db.collection("scheduleRequests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }

                var requests: [ScheduleCaretakerRequest] = []
                for document in snapshot?.documents ?? [] {
                    var requestData = document.data()
                    requestData["requestId"] = document.documentID
                    if let scheduleRequest = ScheduleCaretakerRequest(from: requestData) {
                        requests.append(scheduleRequest)
                    }
                }
                completion(requests)
            }
    }

    func observeOwnerBookings(for userId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) -> ListenerRegistration {
        let query = db.collection("scheduleRequests").whereField("userId", isEqualTo: userId)
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion([])
                return
            }

            var requests: [ScheduleCaretakerRequest] = []
            for document in snapshot?.documents ?? [] {
                var requestData = document.data()
                requestData["requestId"] = document.documentID
                if let scheduleRequest = ScheduleCaretakerRequest(from: requestData) {
                    requests.append(scheduleRequest)
                }
            }
            completion(requests)
        }
    }

    func updateBookingStatus(requestId: String, newStatus: String, completion: @escaping (Error?) -> Void) {
        db.collection("scheduleRequests").document(requestId).updateData([
            "status": newStatus
        ]) { error in
            completion(error)
        }
    }

    // MARK: - Accept / Reject Caretaker

    func acceptRequest(caretakerId: String, requestId: String, completion: @escaping (Error?) -> Void) {
        let caretakerRef = db.collection("caretakers").document(caretakerId)
        let requestRef = db.collection("scheduleRequests").document(requestId)

        requestRef.updateData(["status": "accepted"]) { error in
            if let error = error {
                completion(error)
                return
            }

            caretakerRef.setData(["status": "assigned"], merge: true) { error in
                completion(error)
            }
        }
    }

    func fetchAvailableCaretakers(completion: @escaping ([(DocumentReference, Caretakers, Double)]) -> Void) {
        db.collection("caretakers").whereField("status", isEqualTo: "available").getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }

            let caretakers = snapshot?.documents.compactMap { doc -> (DocumentReference, Caretakers, Double)? in
                let data = doc.data()
                guard let caretaker = try? Firestore.Decoder().decode(Caretakers.self, from: data) else {
                    return nil
                }

                let distance = caretaker.distanceAway
                guard distance > 0 else { return nil }

                let score = Double(caretaker.experience) / distance
                return (doc.reference, caretaker, score)
            }.sorted { $0.2 > $1.2 } ?? []

            completion(caretakers)
        }
    }

    func rejectRequest(caretakerId: String,
                       requestId: String,
                       sortedCaretakers: [(DocumentReference, Caretakers, Double)],
                       completion: @escaping (Error?) -> Void) {
        let requestRef = db.collection("scheduleRequests").document(requestId)

        requestRef.updateData(["status": "rejected"]) { error in
            if let error = error {
                completion(error)
                return
            }

            var remainingCaretakers = sortedCaretakers
            remainingCaretakers.removeFirst()

            if let (caretakerRef, nextCaretaker, _) = remainingCaretakers.first {
                requestRef.updateData([
                    "caretakerId": nextCaretaker.caretakerId,
                    "status": "pending"
                ]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }

                    caretakerRef.updateData([
                        "pendingRequests": FieldValue.arrayUnion([requestId])
                    ]) { error in
                        completion(error)
                    }
                }
            } else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "No caretakers available."]))
            }
        }
    }

    // MARK: - Reject & Reassign

    func rejectAndReassignCaretakerRequest(rejectingCaretakerId: String,
                                           requestId: String,
                                           completion: @escaping (Error?) -> Void) {
        let requestRef = db.collection("scheduleRequests").document(requestId)
        requestRef.getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err { completion(err); return }
            guard let data = snap?.data() else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request not found"]))
                return
            }
            let userLoc = Self.parseLocation(from: data)

            self.findNextCaretaker(excludingId: rejectingCaretakerId, userLocation: userLoc) { result in
                switch result {
                case .success(let (nextRef, next)):
                    requestRef.updateData([
                        "caretakerId": next.caretakerId,
                        "status": "pending"
                    ]) { err in
                        if let err = err { completion(err); return }
                        nextRef.updateData([
                            "pendingRequests": FieldValue.arrayUnion([requestId])
                        ]) { completion($0) }
                    }
                case .failure:
                    requestRef.updateData([
                        "status": "rejected",
                        "caretakerId": ""
                    ]) { completion($0) }
                }
            }
        }
    }

    func rejectAndReassignDogWalkerRequest(rejectingDogWalkerId: String,
                                           requestId: String,
                                           completion: @escaping (Error?) -> Void) {
        let requestRef = db.collection("dogWalkerRequests").document(requestId)
        requestRef.getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err { completion(err); return }
            guard let data = snap?.data() else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request not found"]))
                return
            }
            let userLoc = Self.parseLocation(from: data)

            self.findNextDogWalker(excludingId: rejectingDogWalkerId, userLocation: userLoc) { result in
                switch result {
                case .success(let (nextRef, next)):
                    requestRef.updateData([
                        "dogWalkerId": next.dogWalkerId,
                        "status": "pending"
                    ]) { err in
                        if let err = err { completion(err); return }
                        nextRef.updateData([
                            "pendingRequests": FieldValue.arrayUnion([requestId])
                        ]) { completion($0) }
                    }
                case .failure:
                    requestRef.updateData([
                        "status": "rejected",
                        "dogWalkerId": ""
                    ]) { completion($0) }
                }
            }
        }
    }

    private func findNextCaretaker(excludingId: String,
                                   userLocation: CLLocation?,
                                   completion: @escaping (Result<(DocumentReference, Caretakers), Error>) -> Void) {
        db.collection("caretakers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { snap, err in
                if let err = err { completion(.failure(err)); return }
                let docs = (snap?.documents ?? []).filter { ($0.data()["caretakerId"] as? String) != excludingId }
                let scored = docs.compactMap { doc -> (DocumentReference, Caretakers, Double)? in
                    let data = doc.data()
                    guard let ct = try? Firestore.Decoder().decode(Caretakers.self, from: data) else { return nil }
                    let score: Double = {
                        if let userLoc = userLocation, let ctLoc = Self.parseLocation(from: data) {
                            let km = max(userLoc.distance(from: ctLoc) / 1000.0, 0.001)
                            return Double(ct.experience) / km
                        }
                        let cached = max(ct.distanceAway, 0.001)
                        return Double(ct.experience) / cached
                    }()
                    return (doc.reference, ct, score)
                }.sorted { $0.2 > $1.2 }
                guard let top = scored.first else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more caretakers available"])))
                    return
                }
                completion(.success((top.0, top.1)))
            }
    }

    private func findNextDogWalker(excludingId: String,
                                   userLocation: CLLocation?,
                                   completion: @escaping (Result<(DocumentReference, DogWalker), Error>) -> Void) {
        db.collection("dogwalkers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { snap, err in
                if let err = err { completion(.failure(err)); return }
                let docs = (snap?.documents ?? []).filter { ($0.data()["dogWalkerId"] as? String) != excludingId }
                let scored = docs.compactMap { doc -> (DocumentReference, DogWalker, Double)? in
                    let data = doc.data()
                    guard let dw = try? Firestore.Decoder().decode(DogWalker.self, from: data) else { return nil }
                    let rating = Double(dw.rating ?? "4.0") ?? 4.0
                    let ratingScore = rating / 5.0
                    let distanceScore: Double = {
                        if let userLoc = userLocation, let dwLoc = Self.parseLocation(from: data) {
                            return 1.0 / (userLoc.distance(from: dwLoc) + 1.0)
                        }
                        return 0.0
                    }()
                    let combined = (distanceScore * 0.7) + (ratingScore * 0.3)
                    return (doc.reference, dw, combined)
                }.sorted { $0.2 > $1.2 }
                guard let top = scored.first else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more dog walkers available"])))
                    return
                }
                completion(.success((top.0, top.1)))
            }
    }

    // MARK: - Location Parser

    private static func parseLocation(from data: [String: Any]) -> CLLocation? {
        if let geo = data["location"] as? GeoPoint {
            return CLLocation(latitude: geo.latitude, longitude: geo.longitude)
        }
        if let map = data["location"] as? [String: Any],
           let lat = map["latitude"] as? Double,
           let lon = map["longitude"] as? Double {
            return CLLocation(latitude: lat, longitude: lon)
        }
        if let arr = data["location"] as? [Double], arr.count >= 2 {
            return CLLocation(latitude: arr[0], longitude: arr[1])
        }
        if let lat = data["latitude"] as? Double, let lon = data["longitude"] as? Double {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }

    // MARK: - Vaccination

    func saveVaccinationData(petId: String, vaccination: VaccinationDetails, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "vaccineName": vaccination.vaccineName,
            "dateOfVaccination": vaccination.dateOfVaccination,
            "expires": vaccination.expires,
            "expiryDate": vaccination.expiryDate ?? "",
            "notifyUponExpiry": vaccination.notifyUponExpiry,
            "notes": vaccination.notes ?? ""
        ]

        db.collection("Pets").document(petId).collection("Vaccinations").addDocument(data: data) { error in
            completion(error)
        }
    }

    func deleteVaccinationData(petId: String, vaccineId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("Vaccinations").document(vaccineId).delete { error in
            completion(error)
        }
    }

    // MARK: - Pet Diet

    func savePetDietData(petId: String, diet: PetDietDetails, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "mealType": diet.mealType,
            "foodName": diet.foodName,
            "foodCategory": diet.foodCategory,
            "portionSize": diet.portionSize,
            "feedingFrequency": diet.feedingFrequency,
            "servingTime": diet.servingTime
        ]

        db.collection("Pets").document(petId).collection("PetDiet").addDocument(data: data) { error in
            completion(error)
        }
    }

    func deletePetDietData(petId: String, dietId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("PetDiet").document(dietId).delete { error in
            completion(error)
        }
    }

    // MARK: - Pet Medication

    func savePetMedicationData(petId: String, medication: PetMedicationDetails, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "medicineName": medication.medicineName,
            "medicineType": medication.medicineType,
            "purpose": medication.purpose,
            "frequency": medication.frequency,
            "dosage": medication.dosage,
            "startDate": medication.startDate,
            "endDate": medication.endDate
        ]

        db.collection("Pets").document(petId).collection("PetMedication").addDocument(data: data) { error in
            completion(error)
        }
    }

    func deletePetMedicationData(petId: String, medicationId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("PetMedication").document(medicationId).delete { error in
            completion(error)
        }
    }

    // MARK: - Fetch Pet Names

    func fetchPetNames(completion: @escaping ([String]) -> Void) {
        db.collection("Pets").getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let petNames: [String] = documents.compactMap { doc in
                return doc.data()["petName"] as? String
            }

            DispatchQueue.main.async {
                completion(petNames)
            }
        }
    }

    // MARK: - Storage URL Resolution

    func getDownloadURL(from path: String, completion: @escaping (URL?, Error?) -> Void) {
        if path.starts(with: "http") {
            completion(URL(string: path), nil)
            return
        }

        let storageRef = Storage.storage().reference().child(path)
        storageRef.downloadURL { url, error in
            completion(url, error)
        }
    }

    // MARK: - Distance Update

    func updateDistanceInFirestore(collection: String, id: String, distance: Double) {
        db.collection(collection).document(id).updateData(["distanceAway": distance])
    }
}
