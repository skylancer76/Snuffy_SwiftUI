//
//  UserRoleViewModel.swift
//  Snuffy_SwiftUI
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// NOTE: UserRole enum is defined in UserSignUpViewModel.swift
// (.petOwner = 0, .caretaker = 1, .dogWalker = 2)

class UserRoleViewModel: ObservableObject {
    @Published var role: UserRole = .petOwner
    @Published var isLoading = true
    private let db = Firestore.firestore()

    init() {
        detectRole()
    }

    func detectRole() {
        guard let uid = Auth.auth().currentUser?.uid else {
            role = .petOwner
            isLoading = false
            return
        }

        isLoading = true

        // Check caretaker
        db.collection("caretakers")
            .whereField("caretakerId", isEqualTo: uid)
            .getDocuments { [weak self] snap, _ in
                guard let self = self else { return }
                if let s = snap, !s.documents.isEmpty {
                    DispatchQueue.main.async {
                        self.role = .caretaker
                        self.isLoading = false
                    }
                    return
                }
                // Check dogwalker
                self.db.collection("dogwalkers")
                    .whereField("dogWalkerId", isEqualTo: uid)
                    .getDocuments { [weak self] snap2, _ in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            if let s2 = snap2, !s2.documents.isEmpty {
                                self.role = .dogWalker
                            } else {
                                self.role = .petOwner
                            }
                            self.isLoading = false
                        }
                    }
            }
    }
}
