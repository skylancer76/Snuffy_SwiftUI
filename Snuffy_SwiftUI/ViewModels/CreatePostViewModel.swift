//
//  CreatePostViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
class CreatePostViewModel: ObservableObject {

    // MARK: - Published
    @Published var selectedMediaType: CommunityMediaType = .text
    @Published var caption: String = ""
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var didPost = false

    // Event fields
    @Published var eventTitle: String = ""
    @Published var eventTag: String = "Dog Show"
    @Published var eventLocation: String = ""
    @Published var eventDate: Date = Date()
    @Published var eventContactInfo: String = ""
    @Published var eventImage: UIImage?

    let availableEventTags = ["Dog Show", "Health", "Run", "Training", "Adoption", "General"]

    // MARK: - Private
    private let db      = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Upload Post

    func uploadPost() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to post."
            return
        }
        guard !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || selectedMediaType != .text else {
            errorMessage = "Please write a caption or select media."
            return
        }

        isUploading = true
        let postId = UUID().uuidString
        let userId = user.uid

        // 1. Fetch user's name from Firestore
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            let fetchedName = snapshot?.data()?["name"] as? String
            // Fallback: displayName -> "User Name"
            let finalUserName = fetchedName ?? user.displayName ?? "User Name"

            if self.selectedMediaType == .image, let image = self.selectedImage {
                self.uploadImage(image, path: "community/\(postId)/media.jpg") { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let url):
                        self.savePost(postId: postId, userId: userId,
                                      userName: finalUserName,
                                      avatarURL: user.photoURL?.absoluteString,
                                      mediaURL: url, mediaType: .image)
                    case .failure(let err):
                        self.errorMessage = err.localizedDescription
                        self.isUploading = false
                    }
                }
            } else if self.selectedMediaType == .video, let videoURL = self.selectedVideoURL {
                self.uploadVideo(videoURL, path: "community/\(postId)/media.mp4") { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let url):
                        self.savePost(postId: postId, userId: userId,
                                      userName: finalUserName,
                                      avatarURL: user.photoURL?.absoluteString,
                                      mediaURL: url, mediaType: .video)
                    case .failure(let err):
                        self.errorMessage = err.localizedDescription
                        self.isUploading = false
                    }
                }
            } else {
                // Text only
                self.savePost(postId: postId, userId: userId,
                              userName: finalUserName,
                              avatarURL: user.photoURL?.absoluteString,
                              mediaURL: nil, mediaType: .text)
            }
        }
    }

    private func savePost(postId: String, userId: String, userName: String,
                          avatarURL: String?, mediaURL: String?, mediaType: CommunityMediaType) {
        let post = CommunityPost(
            id: postId,
            userId: userId,
            userName: userName,
            authorAvatarURL: avatarURL,
            caption: caption,
            mediaURL: mediaURL,
            mediaType: mediaType
        )
        db.collection("communityPosts").document(postId).setData(post.toDictionary()) { [weak self] error in
            guard let self else { return }
            self.isUploading = false
            if let error { self.errorMessage = error.localizedDescription }
            else { self.didPost = true }
        }
    }

    // MARK: - Upload Event

    func uploadEvent() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in."
            return
        }
        guard !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an event title."
            return
        }

        isUploading = true
        let eventId = UUID().uuidString
        let userId = user.uid

        db.collection("users").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self else { return }
            let fetchedName = snapshot?.data()?["name"] as? String
            let organizerName = fetchedName ?? user.displayName ?? "Organizer"

            if let image = self.eventImage {
                self.uploadImage(image, path: "community/events/\(eventId)/banner.jpg") { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let url):
                        self.saveEvent(eventId: eventId, userId: userId, organizerName: organizerName, imageURL: url)
                    case .failure(let err):
                        self.errorMessage = err.localizedDescription
                        self.isUploading = false
                    }
                }
            } else {
                self.saveEvent(eventId: eventId, userId: userId, organizerName: organizerName, imageURL: nil)
            }
        }
    }

    private func saveEvent(eventId: String, userId: String, organizerName: String, imageURL: String?) {
        let event = CommunityEvent(
            id: eventId,
            title: eventTitle,
            tag: eventTag,
            location: eventLocation,
            eventDate: eventDate,
            imageURL: imageURL,
            contactInfo: eventContactInfo.isEmpty ? nil : eventContactInfo,
            userId: userId,
            userName: organizerName
        )
        db.collection("communityEvents").document(eventId).setData(event.toDictionary()) { [weak self] error in
            guard let self else { return }
            self.isUploading = false
            if let error { self.errorMessage = error.localizedDescription }
            else { self.didPost = true }
        }
    }

    // MARK: - Firebase Storage Helpers

    private func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "ImageError", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Could not compress image."])))
            return
        }
        let ref = storage.reference(withPath: path)
        let task = ref.putData(data, metadata: nil) { [weak self] _, error in
            if let error { completion(.failure(error)); return }
            ref.downloadURL { url, error in
                if let error { completion(.failure(error)); return }
                completion(.success(url?.absoluteString ?? ""))
                self?.uploadProgress = 0
            }
        }
        task.observe(.progress) { [weak self] snapshot in
            let pct = Double(snapshot.progress?.completedUnitCount ?? 0)
                    / Double(snapshot.progress?.totalUnitCount ?? 1)
            DispatchQueue.main.async { self?.uploadProgress = pct }
        }
    }

    private func uploadVideo(_ url: URL, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = storage.reference(withPath: path)
        let task = ref.putFile(from: url, metadata: nil) { [weak self] _, error in
            if let error { completion(.failure(error)); return }
            ref.downloadURL { url, error in
                if let error { completion(.failure(error)); return }
                completion(.success(url?.absoluteString ?? ""))
                self?.uploadProgress = 0
            }
        }
        task.observe(.progress) { [weak self] snapshot in
            let pct = Double(snapshot.progress?.completedUnitCount ?? 0)
                    / Double(snapshot.progress?.totalUnitCount ?? 1)
            DispatchQueue.main.async { self?.uploadProgress = pct }
        }
    }

    // MARK: - Reset
    func reset() {
        caption = ""
        selectedImage = nil
        selectedVideoURL = nil
        selectedMediaType = .text
        eventTitle = ""
        eventTag = "Dog Show"
        eventLocation = ""
        eventDate = Date()
        eventContactInfo = ""
        eventImage = nil
        errorMessage = nil
        didPost = false
        isUploading = false
        uploadProgress = 0
    }
}
