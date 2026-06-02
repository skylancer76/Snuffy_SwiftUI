import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Error Type

enum DeleteAccountError: Error, LocalizedError {
    case notAuthenticated
    case requiresRecentLogin
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You're not signed in."
        case .requiresRecentLogin:
            return "For security, please sign out, sign back in, and try deleting your account again."
        case .underlying(let err):
            return err.localizedDescription
        }
    }
}

// MARK: - Delete Account Service

final class DeleteAccountService {
    static let shared = DeleteAccountService()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Cascade-deletes user data (Firestore + Storage) before removing the Auth account.
    /// Order matters: data first, auth last — prevents orphan auth accounts on partial failure.
    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw DeleteAccountError.notAuthenticated
        }
        let uid = user.uid

        do {
            try await deletePets(ownerId: uid)
            try await deleteRequests(ownerId: uid)
            try await deleteCaregiverDocs(uid: uid)
            try await deleteCommunityArtifacts(uid: uid)
            try await deleteUserDocument(uid: uid)
            try await deleteStorageArtifacts(uid: uid)
        } catch {
            throw DeleteAccountError.underlying(error)
        }

        do {
            try await user.delete()
        } catch let err as NSError {
            if err.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw DeleteAccountError.requiresRecentLogin
            }
            throw DeleteAccountError.underlying(err)
        }

        try? Auth.auth().signOut()
    }

    // MARK: - Pets & Subcollections

    private func deletePets(ownerId: String) async throws {
        let snapshot = try await db.collection("Pets")
            .whereField("ownerID", isEqualTo: ownerId)
            .getDocuments()

        for petDoc in snapshot.documents {
            for sub in ["Vaccinations", "PetMedication", "PetDiet"] {
                let subSnap = try await petDoc.reference.collection(sub).getDocuments()
                for d in subSnap.documents {
                    try await d.reference.delete()
                }
            }
            try await petDoc.reference.delete()
        }
    }

    // MARK: - Booking Requests

    private func deleteRequests(ownerId: String) async throws {
        for collection in ["scheduleRequests", "dogWalkerRequests"] {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: ownerId)
                .getDocuments()
            for doc in snap.documents {
                try await doc.reference.delete()
            }
        }
    }

    // MARK: - Caregiver Records

    private func deleteCaregiverDocs(uid: String) async throws {
        for collection in ["caretakers", "dogwalkers"] {
            let ref = db.collection(collection).document(uid)
            let snap = try? await ref.getDocument()
            if snap?.exists == true {
                try await ref.delete()
            }
        }
        let notif = try await db.collection("admin_notifications")
            .whereField("uid", isEqualTo: uid)
            .getDocuments()
        for doc in notif.documents {
            try await doc.reference.delete()
        }
    }

    // MARK: - Community Content

    private func deleteCommunityArtifacts(uid: String) async throws {
        for (collection, field) in [
            ("communityPosts", "authorId"),
            ("communityEvents", "authorId"),
            ("communityComments", "authorId"),
            ("ratings", "authorId")
        ] {
            let snap = try? await db.collection(collection)
                .whereField(field, isEqualTo: uid)
                .getDocuments()
            for doc in snap?.documents ?? [] {
                try await doc.reference.delete()
            }
        }
    }

    // MARK: - User Document

    private func deleteUserDocument(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }

    // MARK: - Storage (Best-Effort)

    private func deleteStorageArtifacts(uid: String) async throws {
        let paths = [
            "user_profile_pictures/\(uid).jpg",
            "profile_pictures/\(uid).jpg",
            "dogwalker_profile_pictures/\(uid).jpg"
        ]
        for path in paths {
            let ref = storage.reference().child(path)
            do {
                try await ref.delete()
            } catch {
                let nsErr = error as NSError
                let isObjectNotFound = nsErr.domain == StorageErrorDomain
                    && nsErr.code == StorageErrorCode.objectNotFound.rawValue
                if !isObjectNotFound {
                    throw error
                }
            }
        }
    }
}
