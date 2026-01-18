//
//  FirebaseManager.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreLocation
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // MARK: - Pet Data Functions
    
    /// Save pet data to Firestore with a unique petId.
    func savePetDataToFirebase(data: [String: Any], petId: String, completion: @escaping (Error?) -> Void) {
        let collection = db.collection("Pets")
        collection.document(petId).setData(data) { error in
            if let error = error {
                print("Failed to save pet data: \(error.localizedDescription)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Caretaker Data Functions
    
    func saveCaretakerData(caretakers: [Caretakers], completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        
        for caretaker in caretakers {
            let caretakerRef = db.collection("caretakers").document(caretaker.caretakerId)
            group.enter()
            
            // Provide a default if caretaker.profilePic is nil
            let imageName = caretaker.profilePic ?? "placeholder_image"
            
            // Upload the profile image
            uploadProfileImage(imageName: imageName, caretakerId: caretaker.caretakerId) { profileImageUrl, error in
                if let error = error {
                    completion(error)
                    group.leave()
                    return
                }
                
                // Update caretaker object with the uploaded image URL (if any)
                let updatedCaretaker = caretaker
                updatedCaretaker.profilePic = profileImageUrl ?? ""
                
                // Now save the caretaker to Firestore
                self.saveCaretakerToFirestore(caretaker: updatedCaretaker, caretakerRef: caretakerRef) { error in
                    completion(error)
                    group.leave()
                }
            }
        }
        
        // Once all uploads/saves are done, notify the caller
        group.notify(queue: .main) {
            completion(nil)
        }
    }


    
    /// Helper function to encode and save a caretaker object.
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
    
    /// Upload a caretaker's profile image to Firebase Storage.
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
    
    // MARK: - Schedule Caretaker Request Functions
    
    /// Save caretaker schedule request data to Firestore.
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
    
    /// Auto-assign a caretaker based on the provided petName, requestId, and optionally the user's location.
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
            
            // If userLocation is provided, use it. Otherwise, fetch from user's doc.
            if let providedLocation = userLocation {
                self.assignCaretaker(using: providedLocation, requestId: requestId, completion: completion)
            } else {
                // Fallback: fetch location from user doc
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
                    
                    var fetchedLocation: CLLocation?
                    if let userGeoPoint = userData["location"] as? GeoPoint {
                        fetchedLocation = CLLocation(latitude: userGeoPoint.latitude, longitude: userGeoPoint.longitude)
                    } else if let locationMap = userData["location"] as? [String: Any],
                              let lat = locationMap["latitude"] as? Double,
                              let lon = locationMap["longitude"] as? Double {
                        fetchedLocation = CLLocation(latitude: lat, longitude: lon)
                    } else if let locationArray = userData["location"] as? [Double],
                              locationArray.count >= 2 {
                        fetchedLocation = CLLocation(latitude: locationArray[0], longitude: locationArray[1])
                    }
                    
                    guard let loc = fetchedLocation else {
                        completion(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "User location not found"]))
                        return
                    }
                    
                    self.assignCaretaker(using: loc, requestId: requestId, completion: completion)
                }
            }
        }
    }
    
    /// Helper function to perform caretaker assignment using a given location.
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
                
                // Score caretakers by (experience / distance).
                let sortedCaretakers = caretakerDocs.compactMap { doc -> (DocumentReference, Caretakers, Double)? in
                    let data = doc.data()
                    guard let caretaker = try? Firestore.Decoder().decode(Caretakers.self, from: data) else {
                        print("Decoding caretaker failed for doc: \(doc.documentID)")
                        return nil
                    }
                    
                    var caretakerLocation: CLLocation?
                    
                    // Attempt to parse caretaker location from Firestore
                    if let caretakerGeoPoint = data["location"] as? GeoPoint {
                        caretakerLocation = CLLocation(latitude: caretakerGeoPoint.latitude,
                                                       longitude: caretakerGeoPoint.longitude)
                    } else if let locationMap = data["location"] as? [String: Any],
                              let lat = locationMap["latitude"] as? Double,
                              let lon = locationMap["longitude"] as? Double {
                        caretakerLocation = CLLocation(latitude: lat, longitude: lon)
                    } else if let locationArray = data["location"] as? [Double],
                              locationArray.count >= 2 {
                        caretakerLocation = CLLocation(latitude: locationArray[0],
                                                       longitude: locationArray[1])
                    }
                    
                    guard let caretakerLoc = caretakerLocation else {
                        print("No location found for caretaker: \(caretaker.caretakerId)")
                        return nil
                    }
                    
                    let distanceInMeters = userLocation.distance(from: caretakerLoc)
                    let distanceInKm = distanceInMeters / 1000.0
                    let safeDistance = max(distanceInKm, 0.001) // avoid dividing by zero
                    let score = Double(caretaker.experience) / safeDistance
                    return (doc.reference, caretaker, score)
                }
                .sorted { $0.2 > $1.2 }
                
                guard let (selectedCaretakerRef, selectedCaretaker, _) = sortedCaretakers.first else {
                    completion(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No suitable caretakers found"]))
                    return
                }
                
                print("Assigning request \(requestId) to caretaker: \(selectedCaretaker.name) (Exp: \(selectedCaretaker.experience))")
                
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
                        if let error = error {
                            completion(error)
                        } else {
                            print("Request successfully assigned to \(selectedCaretaker.name)")
                            completion(nil)
                        }
                    }
                }
            }
    }
    
    // MARK: - Dogwalker Data Functions
    
    func saveDogWalkerData(dogWalkers: [DogWalker], completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var overallError: Error?  // To capture any error that occurs

        for dogWalker in dogWalkers {
            group.enter()
            let dogWalkerRef = db.collection("dogwalkers").document(dogWalker.dogWalkerId)
            
            // If the profilePic string is already a URL, assume the image has been uploaded.
            if let pic = dogWalker.profilePic, pic.starts(with: "http") {
                self.saveDogWalkerToFirestore(dogWalker: dogWalker, dogWalkerRef: dogWalkerRef) { error in
                    if let error = error {
                        overallError = error
                    }
                    group.leave()
                }
            } else {
                // Upload the local image (profilePic holds the local asset name).
                uploadDogWalkerProfileImage(imageName: dogWalker.profilePic ?? "placeholder",
                                                dogWalkerId: dogWalker.dogWalkerId) { profileImageUrl, error in
                    if let error = error {
                        overallError = error
                        group.leave()
                        return
                    }
                    
                    // Update the dog walker object with the obtained download URL.
                    let updatedDogWalker = dogWalker
                    updatedDogWalker.profilePic = profileImageUrl ?? ""
                    
                    self.saveDogWalkerToFirestore(dogWalker: updatedDogWalker, dogWalkerRef: dogWalkerRef) { error in
                        if let error = error {
                            overallError = error
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(overallError)
        }
    }

    /// Helper function to encode and save a DogWalker object in Firestore.
    func saveDogWalkerToFirestore(dogWalker: DogWalker, dogWalkerRef: DocumentReference, completion: @escaping (Error?) -> Void) {
        do {
            let data = try Firestore.Encoder().encode(dogWalker)
            dogWalkerRef.setData(data, completion: completion)
        } catch {
            completion(error)
        }
    }

    /// Upload a dog walker's profile image (from local assets) to Firebase Storage.
    func uploadDogWalkerProfileImage(imageName: String, dogWalkerId: String, completion: @escaping (String?, Error?) -> Void) {
        // Load the local image from your assets.
        guard let image = UIImage(named: imageName) else {
            let error = NSError(domain: "ImageError",
                                code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Image not found in assets"])
            completion(nil, error)
            return
        }
        
        let storageRef = Storage.storage().reference().child("dogwalker_profile_pictures/\(dogWalkerId).jpg")
        
        // Convert the image to JPEG data.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "ImageError",
                                code: 500,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            completion(nil, error)
            return
        }
        
        // Upload the image data.
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Retrieve the download URL for the uploaded image.
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(url?.absoluteString, nil)
                }
            }
        }
    }
    
    // MARK: - Dog Walker Request Functions
    
    /// Save dog walker request data to Firestore.
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
    
    /// Auto-assign a dog walker (analogous to auto-assigning a caretaker).
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
                    
                    var fetchedLocation: CLLocation?
                    if let userGeoPoint = userData["location"] as? GeoPoint {
                        fetchedLocation = CLLocation(latitude: userGeoPoint.latitude, longitude: userGeoPoint.longitude)
                    } else if let locationMap = userData["location"] as? [String: Any],
                              let lat = locationMap["latitude"] as? Double,
                              let lon = locationMap["longitude"] as? Double {
                        fetchedLocation = CLLocation(latitude: lat, longitude: lon)
                    } else if let locationArray = userData["location"] as? [Double],
                              locationArray.count >= 2 {
                        fetchedLocation = CLLocation(latitude: locationArray[0], longitude: locationArray[1])
                    }
                    
                    guard let loc = fetchedLocation else {
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
                
                // Compute a combined score for each dog walker.
                // Here, lower distance is better and higher rating is better.
                // We'll normalize the distance score as: 1/(distance+1) and the rating score as: rating/5.
                // We then combine these scores with weights (70% distance, 30% rating).
                let weightedWalkers = walkerDocs.compactMap { doc -> (DocumentReference, DogWalker, Double)? in
                    let data = doc.data()
                    guard let dogWalker = try? Firestore.Decoder().decode(DogWalker.self, from: data) else {
                        print("Decoding dog walker failed for doc: \(doc.documentID)")
                        return nil
                    }
                    
                    var walkerLocation: CLLocation?
                    if let geo = data["location"] as? GeoPoint {
                        walkerLocation = CLLocation(latitude: geo.latitude, longitude: geo.longitude)
                    } else if let locMap = data["location"] as? [String: Any],
                              let lat = locMap["latitude"] as? Double,
                              let lon = locMap["longitude"] as? Double {
                        walkerLocation = CLLocation(latitude: lat, longitude: lon)
                    } else if let locArray = data["location"] as? [Double], locArray.count >= 2 {
                        walkerLocation = CLLocation(latitude: locArray[0], longitude: locArray[1])
                    }
                    
                    guard let wLoc = walkerLocation else { return nil }
                    let distance = userLocation.distance(from: wLoc) // in meters
                    
                    // Normalize distance score (higher is better)
                    let distanceScore = 1.0 / (distance + 1.0)
                    
                    // Normalize rating (assuming maximum rating is 5)
                    let ratingValue = Double(dogWalker.rating ?? "4.0") ?? 4.0
                    let ratingScore = ratingValue / 5.0
                    
                    // Combine scores with weights (adjust these weights as needed)
                    let combinedScore = (distanceScore * 0.7) + (ratingScore * 0.3)
                    
                    return (doc.reference, dogWalker, combinedScore)
                }
                .sorted { $0.2 > $1.2 } // Highest combined score first
                
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
                        if let error = error {
                            completion(error)
                        } else {
                            print("Request successfully assigned to dog walker: \(selectedWalker.name)")
                            completion(nil)
                        }
                    }
                }
            }
    }


    // Accept Dog Walker Request – simply update the status to "accepted" and mark the dog walker as assigned.
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


    // Reject Dog Walker Request – update the current request status to "rejected" for the rejecting dog walker,
    // then remove that walker from the sorted list and assign the next best candidate (if available).
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
            // Remove the rejecting dog walker (assumed to be the first in the sorted list)
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
                        if let error = error {
                            completion(error)
                        } else {
                            print("Request reassigned to dog walker: \(nextWalker.name)")
                            completion(nil)
                        }
                    }
                }
            } else {
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "No dog walkers available for reassignment"]))
            }
        }
    }


    // MARK: - Fetch Requests & Bookings
    
    /// Fetch assigned requests for a caretaker.
    func fetchAssignedRequests(for caretakerId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) {
        db.collection("scheduleRequests")
            .whereField("caretakerId", isEqualTo: caretakerId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching schedule requests: \(error.localizedDescription)")
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
                            if let error = error {
                                print("Error fetching pet ID for \(petName): \(error.localizedDescription)")
                                group.leave()
                                return
                            }
                            
                            guard let petDocument = petSnapshot?.documents.first else {
                                print("No pet found for name: \(petName)")
                                group.leave()
                                return
                            }
                            
                            let petId = petDocument.documentID
                            requestData["petId"] = petId
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
    
    // fetch for dogwalkersRequests
    func fetchAssignedDogWalkerRequests(for dogWalkerId: String, completion: @escaping ([ScheduleDogWalkerRequest]) -> Void) {
        db.collection("dogWalkerRequests")
            .whereField("dogWalkerId", isEqualTo: dogWalkerId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching dog walker requests: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var requests: [ScheduleDogWalkerRequest] = []
                let group = DispatchGroup()
                
                for document in snapshot?.documents ?? [] {
                    var requestData = document.data()
                    requestData["requestId"] = document.documentID
                    
                    // Ensure petName exists to look up additional pet details.
                    guard let petName = requestData["petName"] as? String else { continue }
                    
                    group.enter()
                    self.db.collection("Pets")
                        .whereField("petName", isEqualTo: petName)
                        .getDocuments { petSnapshot, error in
                            if let error = error {
                                print("Error fetching pet info for \(petName): \(error.localizedDescription)")
                                group.leave()
                                return
                            }
                            
                            guard let petDocument = petSnapshot?.documents.first else {
                                print("No pet found for name: \(petName)")
                                group.leave()
                                return
                            }
                            
                            let petId = petDocument.documentID
                            requestData["petId"] = petId
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

    /// Fetch booking details for a pet owner (both caretaker & dogwalker requests, if stored in same collection).
    func fetchOwnerBookings(for userId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) {
        db.collection("scheduleRequests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching bookings: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var requests: [ScheduleCaretakerRequest] = []
                for document in snapshot?.documents ?? [] {
                    var requestData = document.data()
                    requestData["requestId"] = document.documentID
                    // Convert to ScheduleCaretakerRequest model
                    if let scheduleRequest = ScheduleCaretakerRequest(from: requestData) {
                        requests.append(scheduleRequest)
                    }
                }
                completion(requests)
            }
    }
    
    /// Observe the owner's bookings in real-time (caretaker or dogwalker).
    func observeOwnerBookings(for userId: String, completion: @escaping ([ScheduleCaretakerRequest]) -> Void) -> ListenerRegistration {
        let query = db.collection("scheduleRequests").whereField("userId", isEqualTo: userId)
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching bookings: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var requests: [ScheduleCaretakerRequest] = []
            for document in snapshot?.documents ?? [] {
                var requestData = document.data()
                requestData["requestId"] = document.documentID  // Include the document ID
                if let scheduleRequest = ScheduleCaretakerRequest(from: requestData) {
                    requests.append(scheduleRequest)
                }
            }
            completion(requests)
        }
    }

    /// Update the booking status (e.g., "pending" -> "accepted", etc.).
    func updateBookingStatus(requestId: String, newStatus: String, completion: @escaping (Error?) -> Void) {
        db.collection("scheduleRequests").document(requestId).updateData([
            "status": newStatus
        ]) { error in
            completion(error)
        }
    }
    
    /// Accept a request and update caretaker status accordingly.
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
    
    /// Fetch available caretakers and sort them by a score (experience / distance).
    func fetchAvailableCaretakers(completion: @escaping ([(DocumentReference, Caretakers, Double)]) -> Void) {
        db.collection("caretakers").whereField("status", isEqualTo: "available").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching available caretakers: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let caretakers = snapshot?.documents.compactMap { doc -> (DocumentReference, Caretakers, Double)? in
                let data = doc.data()
                guard let caretaker = try? Firestore.Decoder().decode(Caretakers.self, from: data) else {
                    return nil
                }
                
                let experience = caretaker.experience
                let distance = caretaker.distanceAway
                guard distance > 0 else { return nil }
                
                let score = Double(experience) / distance
                return (doc.reference, caretaker, score)
            }.sorted { $0.2 > $1.2 } ?? []
            
            completion(caretakers)
        }
    }
    
    /// Reject a request and reassign it to the next caretaker in the sorted list.
    func rejectRequest(caretakerId: String,
                       requestId: String,
                       sortedCaretakers: [(DocumentReference, Caretakers, Double)],
                       completion: @escaping (Error?) -> Void)
    {
        let requestRef = db.collection("scheduleRequests").document(requestId)
        
        requestRef.updateData(["status": "rejected"]) { error in
            if let error = error {
                completion(error)
                return
            }
            
            var remainingCaretakers = sortedCaretakers
            remainingCaretakers.removeFirst() // remove the caretaker who rejected
            
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
                        if let error = error {
                            completion(error)
                        } else {
                            print("Request reassigned to caretaker: \(nextCaretaker.name)")
                            completion(nil)
                        }
                    }
                }
            } else {
                print("No more caretakers available.")
                completion(NSError(domain: "", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "No caretakers available."]))
            }
        }
    }
    
    // MARK: - Vaccination Functions
    
//    func saveVaccinationData(petId: String, vaccination: VaccinationDetails, completion: @escaping (Error?) -> Void) {
//        let data: [String: Any] = [
//            "vaccineName": vaccination.vaccineName,
//            "vaccineType": vaccination.vaccineType,
//            "dateOfVaccination": vaccination.dateOfVaccination,
//            "expiryDate": vaccination.expiryDate,
//            "nextDueDate": vaccination.nextDueDate
//        ]
//
//        print("Saving vaccination data to Firestore...")
//        db.collection("Pets").document(petId).collection("Vaccinations").addDocument(data: data) { error in
//            if let error = error {
//                print("Error saving vaccination: \(error.localizedDescription)")
//                completion(error)
//            } else {
//                print("Vaccination saved successfully!")
//                completion(nil)
//            }
//        }
//    }
//
    func saveVaccinationData(petId: String, vaccination: VaccinationDetails, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "vaccineName": vaccination.vaccineName,
            "dateOfVaccination": vaccination.dateOfVaccination,
            "expires": vaccination.expires,
            "expiryDate": vaccination.expiryDate ?? "",
            "notifyUponExpiry": vaccination.notifyUponExpiry,
            "notes": vaccination.notes ?? ""
        ]
        
        print("Saving vaccination data to Firestore...")
        
        db.collection("Pets").document(petId).collection("Vaccinations").addDocument(data: data) { error in
            if let error = error {
                print("Error saving vaccination: \(error.localizedDescription)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }


    func deleteVaccinationData(petId: String, vaccineId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("Vaccinations").document(vaccineId).delete { error in
            if let error = error {
                print("Error deleting vaccination: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Vaccination deleted successfully!")
                completion(nil)
            }
        }
    }
    
    // MARK: - Pet Diet Functions
    
    func savePetDietData(petId: String, diet: PetDietDetails, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "mealType": diet.mealType,
            "foodName": diet.foodName,
            "foodCategory": diet.foodCategory,
            "portionSize": diet.portionSize,
            "feedingFrequency": diet.feedingFrequency,
            "servingTime": diet.servingTime
        ]
        
        print("Saving pet diet data to Firestore...")
        db.collection("Pets").document(petId).collection("PetDiet").addDocument(data: data) { error in
            if let error = error {
                print("Error saving pet diet: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Pet diet saved successfully!")
                completion(nil)
            }
        }
    }
    
    func deletePetDietData(petId: String, dietId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("PetDiet").document(dietId).delete { error in
            if let error = error {
                print("Error deleting pet diet: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Pet diet deleted successfully!")
                completion(nil)
            }
        }
    }
    
    // MARK: - Pet Medication Functions
    
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
        
        print("Saving pet medication data to Firestore...")
        db.collection("Pets").document(petId).collection("PetMedication").addDocument(data: data) { error in
            if let error = error {
                print("Error saving pet medication: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Pet medication saved successfully!")
                completion(nil)
            }
        }
    }
    
    func deletePetMedicationData(petId: String, medicationId: String, completion: @escaping (Error?) -> Void) {
        db.collection("Pets").document(petId).collection("PetMedication").document(medicationId).delete { error in
            if let error = error {
                print("Error deleting pet medication: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Pet medication deleted successfully!")
                completion(nil)
            }
        }
    }
    
    // MARK: - Fetch Pet Names
    
    func fetchPetNames(completion: @escaping ([String]) -> Void) {
        db.collection("Pets").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching pets: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No pet documents found in Firestore.")
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
}
