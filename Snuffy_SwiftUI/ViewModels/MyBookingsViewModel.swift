//
//  MyBookingsViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham on 19/01/26.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

enum BookingType {
    case caretaker
    case dogWalker
}

enum DynamicBookingStatus: String {
    case requested = "Requested"
    case accepted = "Accepted"
    case ongoing = "Ongoing"
    case completed = "Completed"
    case rejected = "Rejected"
    
    var colorName: String {
        switch self {
        case .requested: return "CardBadgeYellow"
        case .accepted: return "CardBadgeBlue"
        case .ongoing: return "CardBadgePink"
        case .completed: return "CardBadgeGreen"
        case .rejected: return "CardBadgeRed"
        }
    }
}

struct BookingItem: Identifiable {
    let id: String
    let petName: String
    let petImageUrl: String?
    let startDate: Date
    let endDate: Date
    let status: String
    let type: BookingType
    let durationString: String
    
    let caretakerRequest: ScheduleCaretakerRequest?
    let dogWalkerRequest: ScheduleDogWalkerRequest?
    
    var dynamicStatus: DynamicBookingStatus {
        let now = Date()
        let normalizedStatus = status.lowercased()
        
        switch normalizedStatus {
        case "rejected":
            return .rejected
        case "completed":
            return .completed
        case "accepted", "ongoing":
            if now < startDate {
                return .accepted
            } else if now >= startDate && now <= endDate {
                return .ongoing
            } else {
                return .completed
            }
        case "requested", "available":
            if now >= startDate {
                return .rejected
            } else {
                return .requested
            }
        default:
            return .requested
        }
    }
}

class MyBookingsViewModel: ObservableObject {
    @Published var caretakerBookings: [BookingItem] = []
    @Published var dogWalkerBookings: [BookingItem] = []
    
    private var caretakerListener: ListenerRegistration?
    private var dogWalkerListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        setupListeners()
    }
    
    deinit {
        caretakerListener?.remove()
        dogWalkerListener?.remove()
    }
    
    func setupListeners() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No user logged in to fetch bookings")
            return
        }
        
        // MARK: - Caretaker Listener
        caretakerListener = db.collection("scheduleRequests")
            .whereField("userId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching caretaker bookings: \(error.localizedDescription)")
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let group = DispatchGroup()
                var items: [BookingItem] = []
                
                for document in documents {
                    var data = document.data()
                    data["requestId"] = document.documentID
                    
                    guard let request = ScheduleCaretakerRequest(from: data) else { continue }
                    
                    self.checkAutoReject(
                        requestId: request.requestId,
                        collection: "scheduleRequests",
                        status: request.status,
                        startDate: request.startDate ?? Date()
                    )
                    
                    group.enter()
                    
                    self.fetchPetImage(for: request.petName) { imageUrl in
                        let item = BookingItem(
                            id: request.requestId,
                            petName: request.petName,
                            petImageUrl: imageUrl ?? request.petImageUrl, // fallback to whatever is on the request
                            startDate: request.startDate ?? Date(),
                            endDate: request.endDate ?? Date(),
                            status: request.status,
                            type: .caretaker,
                            durationString: request.duration,
                            caretakerRequest: request,
                            dogWalkerRequest: nil
                        )
                        items.append(item)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.caretakerBookings = items.sorted { $0.startDate < $1.startDate }
                }
            }
        
        // MARK: - Dog Walker Listener
        dogWalkerListener = db.collection("dogWalkerRequests")
            .whereField("userId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching dog walker bookings: \(error.localizedDescription)")
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let group = DispatchGroup()
                var items: [BookingItem] = []
                
                for document in documents {
                    var data = document.data()
                    data["requestId"] = document.documentID
                    
                    guard let request = ScheduleDogWalkerRequest(from: data) else { continue }
                    
                    self.checkAutoReject(
                        requestId: request.requestId,
                        collection: "dogWalkerRequests",
                        status: request.status,
                        startDate: request.startTime
                    )
                    
                    group.enter()
                    
                    // ✅ FIX: Same pet image lookup for dog walker requests
                    self.fetchPetImage(for: request.petName) { imageUrl in
                        let item = BookingItem(
                            id: request.requestId,
                            petName: request.petName,
                            petImageUrl: imageUrl ?? request.petImageUrl,
                            startDate: request.startTime,
                            endDate: request.endTime,
                            status: request.status,
                            type: .dogWalker,
                            durationString: request.duration,
                            caretakerRequest: nil,
                            dogWalkerRequest: request
                        )
                        items.append(item)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.dogWalkerBookings = items.sorted { $0.startDate < $1.startDate }
                }
            }
    }
    
    // MARK: - Pet Image Lookup
    private func fetchPetImage(for petName: String, completion: @escaping (String?) -> Void) {
        db.collection("Pets")
            .whereField("petName", isEqualTo: petName)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching pet image for \(petName): \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                let imageUrl = snapshot?.documents.first?.data()["petImage"] as? String
                completion(imageUrl)
            }
    }
    
    // MARK: - Auto Reject Logic
    private func checkAutoReject(requestId: String, collection: String, status: String, startDate: Date) {
        let normalizedStatus = status.lowercased()
        if (normalizedStatus == "requested" || normalizedStatus == "available") && Date() >= startDate {
            db.collection(collection).document(requestId).updateData([
                "status": "Rejected"
            ]) { error in
                if let error = error {
                    print("Error auto-rejecting \(requestId): \(error.localizedDescription)")
                } else {
                    print("Auto-rejected request \(requestId) because start date passed")
                }
            }
        }
    }
}
