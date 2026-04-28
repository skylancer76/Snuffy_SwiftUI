//
//  RatingViewModel.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma 

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class RatingViewModel: ObservableObject {
    @Published var hasRated          = false
    @Published var existingStars: Int = 0
    @Published var isChecking        = false
    @Published var isSubmitting      = false
    @Published var errorMessage: String?
    @Published var didSubmit         = false

    private let db             = Firestore.firestore()
    private var targetId:       String            // may be updated after doc-ID resolution
    private let collectionName: String            // "dogwalkers" or "caretakers"
    private let bookingId:      String

    init(targetId: String, collectionName: String, bookingId: String) {
        self.targetId       = targetId
        self.collectionName = collectionName
        self.bookingId      = bookingId
    }

    /// Call this when the real Firestore document ID is known (e.g. caretaker fetched via whereField).
    func setTargetDocumentId(_ id: String) {
        guard !id.isEmpty, id != targetId else { return }
        targetId  = id
        hasRated  = false   // re-check against correct document
    }

    // MARK: - Check whether the current user already rated this booking

    func checkExistingRating() async {
        guard !targetId.isEmpty else { return }
        isChecking = true
        defer { isChecking = false }

        let ref = db.collection(collectionName).document(targetId)
            .collection("ratings").document(bookingId)

        if let data = try? await ref.getDocument().data() {
            hasRated      = true
            existingStars = data["stars"] as? Int ?? 0
        } else {
            hasRated = false
        }
    }

    // MARK: - Submit rating + recalculate provider average

    func submitRating(stars: Int, comment: String) async {
        guard stars > 0, !targetId.isEmpty else { return }
        isSubmitting  = true
        errorMessage  = nil
        defer { isSubmitting = false }

        let userId = Auth.auth().currentUser?.uid ?? ""
        let payload: [String: Any] = [
            "userId":    userId,
            "stars":     stars,
            "comment":   comment.trimmingCharacters(in: .whitespacesAndNewlines),
            "createdAt": Timestamp(date: Date()),
            "bookingId": bookingId
        ]

        let ratingsRef = db.collection(collectionName).document(targetId)
            .collection("ratings")

        do {
            // One rating per booking — use bookingId as document ID
            try await ratingsRef.document(bookingId).setData(payload)

            // Recalculate running average across ALL ratings for this provider
            let snapshot  = try await ratingsRef.getDocuments()
            let allStars  = snapshot.documents.compactMap { $0.data()["stars"] as? Int }
            if !allStars.isEmpty {
                let avg    = Double(allStars.reduce(0, +)) / Double(allStars.count)
                let avgStr = String(format: "%.1f", avg)
                try await db.collection(collectionName).document(targetId)
                    .updateData(["rating": avgStr])
            }

            hasRated      = true
            existingStars = stars
            didSubmit     = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
