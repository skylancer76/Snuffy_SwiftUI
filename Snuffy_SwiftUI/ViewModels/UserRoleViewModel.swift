//
//  UserRoleViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class UserRoleViewModel: ObservableObject {
    @Published var role: UserRole = .petOwner
    @Published var isLoading = true
    @Published var isVerified = false
    @Published var isProfileComplete = false

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    init() {
        detectRole()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    func detectRole() {
        guard let uid = Auth.auth().currentUser?.uid else {
            role = .petOwner
            isLoading = false
            return
        }

        isLoading = true

        // 1. Listen to Caretakers
        let ctListener = db.collection("caretakers").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let snap = snap, snap.exists, let data = snap.data() else { return }
                DispatchQueue.main.async {
                    self.role = .caretaker
                    self.isVerified = data["isVerified"] as? Bool ?? false
                    self.isProfileComplete = data["isProfileComplete"] as? Bool ?? false
                    self.isLoading = false
                }
            }

        // 2. Listen to Dog Walkers
        let dwListener = db.collection("dogwalkers").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let snap = snap, snap.exists, let data = snap.data() else { return }
                DispatchQueue.main.async {
                    self.role = .dogWalker
                    self.isVerified = data["isVerified"] as? Bool ?? false
                    self.isProfileComplete = data["isProfileComplete"] as? Bool ?? false
                    self.isLoading = false
                }
            }

        // 3. Fallback for pure Pet Owners
        let poListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let snap = snap, snap.exists else { return }
                DispatchQueue.main.async {
                    // Only stop loading if we haven't already resolved a higher role
                    if self.isLoading && self.role == .petOwner {
                        self.isLoading = false
                    }
                }
            }

        listeners.append(contentsOf: [ctListener, dwListener, poListener])

        // Safety timeout in case of network lag
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            if self.isLoading {
                self.isLoading = false
            }
        }
    }

    func refresh() {
        // Just let the active snapshot listeners do their job
    }
}
