//
//  CaretakerHomeViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class CaretakerHomeViewModel: ObservableObject {
    @Published var scheduleRequests: [ScheduleCaretakerRequest] = []
    @Published var dogWalkerRequests: [ScheduleDogWalkerRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userInitials: String = "U"
    @Published var shouldNavigateToProfile: Bool = false
    
    var caretakerId: String?
    var dogWalkerId: String?
    
    private let db = Firestore.firestore()
    
    func checkUserRoleAndFetchRequests() {
        guard let currentUser = Auth.auth().currentUser else {
            self.errorMessage = "No user logged in"
            return
        }
        
        let userId = currentUser.uid
        isLoading = true
        
        // Check if user is caretaker
        db.collection("caretakers").whereField("caretakerId", isEqualTo: userId).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self.caretakerId = userId
                self.fetchCaretakerRequests()
            } else {
                // Check if user is dog walker
                self.db.collection("dogwalkers").whereField("dogWalkerId", isEqualTo: userId).getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        self.dogWalkerId = userId
                        self.fetchDogWalkerRequests()
                    } else {
                        self.errorMessage = "User role not recognized"
                    }
                }
            }
        }
    }
    
    func fetchCaretakerRequests() {
        guard let caretakerId = caretakerId else { return }
        isLoading = true
        FirebaseManager.shared.fetchAssignedRequests(for: caretakerId) { [weak self] requests in
            DispatchQueue.main.async {
                self?.scheduleRequests = requests
                self?.isLoading = false
            }
        }
    }
    
    func fetchDogWalkerRequests() {
        guard let dogWalkerId = dogWalkerId else { return }
        isLoading = true
        FirebaseManager.shared.fetchAssignedDogWalkerRequests(for: dogWalkerId) { [weak self] requests in
            DispatchQueue.main.async {
                self?.dogWalkerRequests = requests
                self?.isLoading = false
            }
        }
    }
    
    func acceptCaretakerRequest(request: ScheduleCaretakerRequest) {
        guard let caretakerId = self.caretakerId else { return }
        
        FirebaseManager.shared.acceptRequest(caretakerId: caretakerId, requestId: request.requestId) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.scheduleRequests.removeAll { $0.requestId == request.requestId }
            }
        }
    }
    
    func acceptDogWalkerRequest(request: ScheduleDogWalkerRequest) {
        guard let dogWalkerId = self.dogWalkerId else { return }
        
        FirebaseManager.shared.acceptDogWalkerRequest(dogWalkerId: dogWalkerId, requestId: request.requestId) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.dogWalkerRequests.removeAll { $0.requestId == request.requestId }
            }
        }
    }
    
    // MARK: - Profile & Auth
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Try caretakers first
        db.collection("caretakers").whereField("caretakerId", isEqualTo: userId).getDocuments { [weak self] snapshot, _ in
            if let doc = snapshot?.documents.first {
                let data = doc.data()
                self?.updateProfileData(name: data["name"] as? String, email: data["email"] as? String)
            } else {
                // Try dogwalkers
                self?.db.collection("dogwalkers").whereField("dogWalkerId", isEqualTo: userId).getDocuments { [weak self] snapshot, _ in
                    if let doc = snapshot?.documents.first {
                        let data = doc.data()
                        self?.updateProfileData(name: data["name"] as? String, email: data["email"] as? String)
                    } else {
                        // Fallback to general users collection
                        self?.db.collection("users").document(userId).getDocument { doc, _ in
                            if let data = doc?.data() {
                                self?.updateProfileData(name: data["name"] as? String, email: data["email"] as? String)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateProfileData(name: String?, email: String?) {
        DispatchQueue.main.async {
            self.userName = name ?? "Unknown User"
            self.userEmail = email ?? Auth.auth().currentUser?.email ?? ""
            self.userInitials = self.getInitials(from: self.userName)
        }
    }
    
    private func getInitials(from name: String) -> String {
        let nameParts = name.split(separator: " ")
        let initials = nameParts.compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
