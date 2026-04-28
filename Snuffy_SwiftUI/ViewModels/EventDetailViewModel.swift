//
//  EventDetailViewModel.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma 

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct EventParticipant: Identifiable {
    let id: String         // userId
    let userName: String
    let registeredAt: Date

    init?(from data: [String: Any], id: String) {
        guard
            let userName = data["userName"] as? String,
            let ts       = data["registeredAt"] as? Timestamp
        else { return nil }
        self.id           = id
        self.userName     = userName
        self.registeredAt = ts.dateValue()
    }
}

@MainActor
class EventDetailViewModel: ObservableObject {

    // MARK: - Published
    @Published var organizerName: String = ""
    @Published var isOrganizer: Bool = false
    @Published var isRegistered: Bool = false
    @Published var isLoading: Bool = false
    @Published var isRegistering: Bool = false
    @Published var participants: [EventParticipant] = []
    @Published var isLoadingParticipants: Bool = false

    private let event: CommunityEvent
    private let db = Firestore.firestore()

    init(event: CommunityEvent) {
        self.event = event
        let uid = Auth.auth().currentUser?.uid ?? ""
        self.isOrganizer = uid == event.userId
    }

    // MARK: - Load

    func loadDetail() async {
        isLoading = true
        defer { isLoading = false }

        // Resolve organizer name: use stored userName, fall back to Firestore lookup
        if let name = event.userName, !name.isEmpty {
            organizerName = name
        } else {
            if let doc = try? await db.collection("users").document(event.userId).getDocument(),
               let name = doc.data()?["name"] as? String {
                organizerName = name
            }
        }

        // Check if current user is already registered
        guard !isOrganizer, let uid = Auth.auth().currentUser?.uid else { return }
        let regDoc = try? await db
            .collection("communityEvents").document(event.id)
            .collection("registrations").document(uid)
            .getDocument()
        isRegistered = regDoc?.exists == true
    }

    // MARK: - Register

    func register() async {
        guard let user = Auth.auth().currentUser, !isRegistered else { return }
        isRegistering = true
        defer { isRegistering = false }

        let doc = try? await db.collection("users").document(user.uid).getDocument()
        let userName = doc?.data()?["name"] as? String ?? user.displayName ?? "User"

        let data: [String: Any] = [
            "userId":       user.uid,
            "userName":     userName,
            "registeredAt": Timestamp(date: Date())
        ]

        try? await db
            .collection("communityEvents").document(event.id)
            .collection("registrations").document(user.uid)
            .setData(data)

        isRegistered = true
    }

    // MARK: - Load Participants (organizer only)

    func loadParticipants() async {
        isLoadingParticipants = true
        defer { isLoadingParticipants = false }

        let snapshot = try? await db
            .collection("communityEvents").document(event.id)
            .collection("registrations")
            .order(by: "registeredAt", descending: false)
            .getDocuments()

        participants = snapshot?.documents.compactMap {
            EventParticipant(from: $0.data(), id: $0.documentID)
        } ?? []
    }
}
