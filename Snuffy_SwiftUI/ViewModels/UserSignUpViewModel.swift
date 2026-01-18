//
//  UserSignUpViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 13/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

enum UserRole: Int, CaseIterable {
    case petOwner = 0
    case caretaker = 1
    case dogWalker = 2
    
    var title: String {
        switch self {
        case .petOwner: return "Pet Owner"
        case .caretaker: return "Pet Caretaker"
        case .dogWalker: return "Pet Walker"
        }
    }
}

class UserSignUpViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var hasAgreedToTerms = false
    @Published var selectedRole: UserRole = .petOwner
    @Published var emailErrorMessage: String?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var shouldNavigateToHome = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Email Validation
    func validateEmail() {
        if email.isEmpty {
            emailErrorMessage = nil
            return
        }
        
        let emailRegEx = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        
        if predicate.evaluate(with: email) {
            emailErrorMessage = nil
        } else {
            emailErrorMessage = "Invalid email format"
        }
    }
    
    // MARK: - Sign Up Method
    func signUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        guard hasAgreedToTerms else {
            alertMessage = "You must agree to the terms and conditions."
            showAlert = true
            return
        }
        
        guard emailErrorMessage == nil else {
            alertMessage = "Please enter a valid email"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // TODO: Connect to Firebase Manager
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
                return
            }
            
            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Save user data based on role
            switch self.selectedRole {
            case .petOwner:
                self.saveUserDataToFirestore(uid: user.uid)
            case .caretaker:
                self.saveCaretakerDataToFirestore(uid: user.uid)
            case .dogWalker:
                self.saveDogWalkerDataToFirestore(uid: user.uid)
            }
        }
    }
    
    // MARK: - Firebase Save Methods (to be connected to Firebase Manager later)
    private func saveUserDataToFirestore(uid: String) {
        let userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "role": "Pet Owner",
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.alertMessage = "Failed to save user data: \(error.localizedDescription)"
                    self.showAlert = true
                } else {
                    self.shouldNavigateToHome = true
                }
            }
        }
    }
    
    private func saveCaretakerDataToFirestore(uid: String) {
        let data: [String: Any] = [
            "caretakerId": uid,
            "name": name,
            "email": email,
            "password": password,
            "profilePic": "",
            "bio": "",
            "experience": 0,
            "address": "",
            "location": [0.0, 0.0],
            "distanceAway": 0.0,
            "status": "available",
            "pendingRequests": [],
            "completedRequests": 0,
            "createdAt": Timestamp()
        ]
        
        db.collection("caretakers").document(uid).setData(data) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                } else {
                    self.shouldNavigateToHome = true
                }
            }
        }
    }
    
    private func saveDogWalkerDataToFirestore(uid: String) {
        let data: [String: Any] = [
            "dogWalkerId": uid,
            "name": name,
            "email": email,
            "password": password,
            "profilePic": "",
            "rating": "0.0",
            "address": "",
            "location": [0.0, 0.0],
            "distanceAway": 0.0,
            "status": "available",
            "pendingRequests": [],
            "completedRequests": 0,
            "phoneNumber": "",
            "createdAt": Timestamp()
        ]
        
        db.collection("dogWalkers").document(uid).setData(data) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                } else {
                    self.shouldNavigateToHome = true
                }
            }
        }
    }
}
