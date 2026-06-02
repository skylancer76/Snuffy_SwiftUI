import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// Unified booking item for the caregiver (seen from caretaker/dogwalker side)
struct CaregiverBookingItem: Identifiable {
    let id: String
    let petId: String?
    let petName: String
    let ownerName: String
    let petBreed: String
    let petImageUrl: String?
    let durationLabel: String
    let status: String
    let type: BookingType
    // Underlying data for detail view
    let caretakerRequest: ScheduleCaretakerRequest?
    let dogWalkerRequest: ScheduleDogWalkerRequest?

    var displayStatus: String { status.capitalized }

    var isUpcoming: Bool {
        let s = status.lowercased()
        return s == "accepted" || s == "ongoing" || s == "pending"
    }
}

class CaregiverBookingsViewModel: ObservableObject {
    @Published var upcomingBookings: [CaregiverBookingItem] = []
    @Published var completedBookings: [CaregiverBookingItem] = []
    @Published var isLoading = true
    @Published var isCaretaker = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { checkRoleAndFetch() }

    deinit { listener?.remove() }

    func checkRoleAndFetch() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        db.collection("caretakers")
            .whereField("caretakerId", isEqualTo: uid)
            .getDocuments { [weak self] snap, _ in
                guard let self = self else { return }
                if let s = snap, !s.documents.isEmpty {
                    DispatchQueue.main.async { self.isCaretaker = true }
                    self.observeCaretakerBookings(uid: uid)
                } else {
                    self.db.collection("dogwalkers")
                        .whereField("dogWalkerId", isEqualTo: uid)
                        .getDocuments { [weak self] snap2, _ in
                            guard let self = self else { return }
                            if let s2 = snap2, !s2.documents.isEmpty {
                                self.observeDogWalkerBookings(uid: uid)
                            } else {
                                DispatchQueue.main.async { self.isLoading = false }
                            }
                        }
                }
            }
    }

    private func observeCaretakerBookings(uid: String) {
        listener = db.collection("scheduleRequests")
            .whereField("caretakerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }
                var upcoming: [CaregiverBookingItem] = []
                var completed: [CaregiverBookingItem] = []
                let group = DispatchGroup()

                for doc in snap?.documents ?? [] {
                    var data = doc.data()
                    data["requestId"] = doc.documentID
                    guard let petName = data["petName"] as? String else { continue }
                    group.enter()
                    self.db.collection("Pets")
                        .whereField("petName", isEqualTo: petName)
                        .getDocuments { petSnap, _ in
                            if let petDoc = petSnap?.documents.first {
                                data["petId"] = petDoc.documentID
                                data["petBreed"] = petDoc.data()["petBreed"] as? String ?? "Unknown"
                                data["petImageUrl"] = petDoc.data()["petImage"] as? String ?? ""
                            }
                            if let req = ScheduleCaretakerRequest(from: data) {
                                let item = CaregiverBookingItem(
                                    id: req.requestId,
                                    petId: data["petId"] as? String,
                                    petName: req.petName,
                                    ownerName: req.userName,
                                    petBreed: req.petBreed ?? "Unknown",
                                    petImageUrl: req.petImageUrl,
                                    durationLabel: req.duration,
                                    status: req.status,
                                    type: .caretaker,
                                    caretakerRequest: req,
                                    dogWalkerRequest: nil
                                )
                                if req.status.lowercased() == "completed" {
                                    completed.append(item)
                                } else {
                                    upcoming.append(item)
                                }
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    self.upcomingBookings = upcoming
                    self.completedBookings = completed
                    self.isLoading = false
                }
            }
    }

    private func observeDogWalkerBookings(uid: String) {
        listener = db.collection("dogWalkerRequests")
            .whereField("dogWalkerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }
                var upcoming: [CaregiverBookingItem] = []
                var completed: [CaregiverBookingItem] = []
                let group = DispatchGroup()

                for doc in snap?.documents ?? [] {
                    var data = doc.data()
                    data["requestId"] = doc.documentID
                    guard let petName = data["petName"] as? String else { continue }
                    group.enter()
                    self.db.collection("Pets")
                        .whereField("petName", isEqualTo: petName)
                        .getDocuments { petSnap, _ in
                            if let petDoc = petSnap?.documents.first {
                                data["petId"] = petDoc.documentID
                                data["petBreed"] = petDoc.data()["petBreed"] as? String ?? "Unknown"
                                data["petImageUrl"] = petDoc.data()["petImage"] as? String ?? ""
                            }
                            if let req = ScheduleDogWalkerRequest(from: data) {
                                let item = CaregiverBookingItem(
                                    id: req.requestId,
                                    petId: data["petId"] as? String,
                                    petName: req.petName,
                                    ownerName: req.userName,
                                    petBreed: req.petBreed ?? "Unknown",
                                    petImageUrl: req.petImageUrl,
                                    durationLabel: req.duration,
                                    status: req.status,
                                    type: .dogWalker,
                                    caretakerRequest: nil,
                                    dogWalkerRequest: req
                                )
                                if req.status.lowercased() == "completed" {
                                    completed.append(item)
                                } else {
                                    upcoming.append(item)
                                }
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    self.upcomingBookings = upcoming
                    self.completedBookings = completed
                    self.isLoading = false
                }
            }
    }

    func markAsCompleted(booking: CaregiverBookingItem) {
        let collection = booking.type == .caretaker ? "scheduleRequests" : "dogWalkerRequests"
        db.collection(collection).document(booking.id).updateData(["status": "completed"]) { error in
            if let error = error { _ = error }
        }
    }
}
