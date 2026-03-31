//
//  CommunityCommentsViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class CommunityCommentsViewModel: ObservableObject {

    @Published var comments: [CommunityComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newCommentText: String = ""
    @Published var isPosting = false

    var postId: String
    var onCommentAdded: (() -> Void)?

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    init(postId: String, onCommentAdded: (() -> Void)? = nil) {
        self.postId = postId
        self.onCommentAdded = onCommentAdded
        fetchComments()
    }

    deinit {
        listener?.remove()
    }

    func fetchComments() {
        isLoading = true
        listener = db.collection("communityPosts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error { self.errorMessage = error.localizedDescription; return }
                self.comments = snapshot?.documents.compactMap {
                    CommunityComment(from: $0.data(), id: $0.documentID)
                } ?? []
            }
    }

    func addComment(postId: String) {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to comment."
            return
        }

        isPosting = true
        let commentId = UUID().uuidString
        let userId = user.uid

        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            let fetchedName = snapshot?.data()?["name"] as? String
            let finalUserName = fetchedName ?? user.displayName ?? "User Name"

            let comment = CommunityComment(
                id: commentId,
                postId: postId,
                userId: userId,
                userName: finalUserName,
                text: text
            )

            // We need to write the new comment AND increment the post's commentCount
            let commentRef = self.db.collection("communityPosts")
                .document(postId)
                .collection("comments")
                .document(commentId)
            let postRef = self.db.collection("communityPosts").document(postId)

            let batch = self.db.batch()
            batch.setData(comment.toDictionary(), forDocument: commentRef)
            batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: postRef)

            batch.commit { [weak self] error in
                guard let self else { return }
                self.isPosting = false
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.newCommentText = ""
                    self.onCommentAdded?()
                }
            }
        }
    }
}
