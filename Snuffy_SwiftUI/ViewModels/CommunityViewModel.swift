//
//  CommunityViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class CommunityViewModel: ObservableObject {

    // MARK: - Published State
    @Published var posts: [CommunityPost] = []
    @Published var events: [CommunityEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateMenu = false
    @Published var showCreatePost = false
    @Published var showCreateEvent = false
    @Published var selectedPostForComments: CommunityPost?

    // MARK: - Private
    private var postsListener: ListenerRegistration?
    private var eventsListener: ListenerRegistration?
    private let db = Firestore.firestore()

    // MARK: - Init
    init() {
        startListeners()
    }

    deinit {
        postsListener?.remove()
        eventsListener?.remove()
    }

    // MARK: - Real-time Listeners

    func startListeners() {
        isLoading = true
        fetchPosts()
        fetchEvents()
    }

    private func fetchPosts() {
        postsListener = db.collection("communityPosts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error { self.errorMessage = error.localizedDescription; return }

                let docs = snapshot?.documents ?? []
                let currentUserId = Auth.auth().currentUser?.uid ?? ""

                var parsed: [CommunityPost] = docs.compactMap { doc in
                    CommunityPost(from: doc.data(), id: doc.documentID)
                }

                let group = DispatchGroup()
                for i in parsed.indices {
                    let postId = parsed[i].id
                    group.enter()
                    self.db.collection("communityPosts")
                        .document(postId)
                        .collection("likes")
                        .document(currentUserId)
                        .getDocument { snap, _ in
                            if snap?.exists == true {
                                parsed[i].isLikedByCurrentUser = true
                            }
                            group.leave()
                        }
                }
                group.notify(queue: .main) {
                    self.posts = parsed
                }
            }
    }

    private func fetchEvents() {
        eventsListener = db.collection("communityEvents")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.events = snapshot?.documents.compactMap {
                    CommunityEvent(from: $0.data(), id: $0.documentID)
                } ?? []
            }
    }

    // MARK: - Like / Unlike

    func toggleLike(post: CommunityPost) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let postRef = db.collection("communityPosts").document(post.id)
        let likeRef = postRef.collection("likes").document(currentUserId)
        let isLiked = post.isLikedByCurrentUser
        let delta   = isLiked ? -1 : 1

        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
            posts[idx].isLikedByCurrentUser = !isLiked
            posts[idx].likesCount = max(0, posts[idx].likesCount + delta)
        }

        let batch = db.batch()
        if isLiked {
            batch.deleteDocument(likeRef)
        } else {
            batch.setData(["uid": currentUserId], forDocument: likeRef)
        }
        batch.updateData(["likesCount": FieldValue.increment(Int64(delta))], forDocument: postRef)
        batch.commit { [weak self] error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Delete Post

    func deletePost(_ post: CommunityPost) {
        guard Auth.auth().currentUser?.uid == post.userId else { return }
        db.collection("communityPosts").document(post.id).delete { [weak self] error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }
}
