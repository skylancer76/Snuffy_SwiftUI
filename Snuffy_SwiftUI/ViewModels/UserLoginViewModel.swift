//
//  UserLoginViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 13/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class UserLoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var emailErrorMessage: String?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var shouldNavigateToSignUp = false
    @Published var shouldNavigateToHome = false
    @Published var shouldNavigateToCaretakerHome = false
    
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
            emailErrorMessage = "Invalid email format!"
        }
    }
    
    // MARK: - Login Method
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
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
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
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
                    self.alertMessage = "User not found"
                    self.showAlert = true
                }
                return
            }
            
            self.checkUserRoles(userID: user.uid)
        }
    }
    
    // MARK: - Firebase Methods (to be connected to Firebase Manager later)
    private func checkUserRoles(userID: String) {
        let group = DispatchGroup()
        var isCaretaker = false
        var isDogwalker = false
        
        group.enter()
        checkIfUserIsCaretaker(userID: userID) { result in
            isCaretaker = result
            group.leave()
        }
        
        group.enter()
        checkIfUserIsDogWalker(userID: userID) { result in
            isDogwalker = result
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            if isCaretaker || isDogwalker {
                self.shouldNavigateToCaretakerHome = true
            } else {
                self.shouldNavigateToHome = true
            }
        }
    }
    
    private func checkIfUserIsCaretaker(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let caretakersRef = db.collection("caretakers")
        
        caretakersRef.whereField("caretakerId", isEqualTo: userID).getDocuments { snapshot, error in
            if let error = error {
                print("Error verifying caretaker role: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(snapshot?.documents.isEmpty == false)
        }
    }
    
    private func checkIfUserIsDogWalker(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let dogWalkersRef = db.collection("dogwalkers")
        
        dogWalkersRef.whereField("dogWalkerId", isEqualTo: userID).getDocuments { snapshot, error in
            if let error = error {
                print("Error verifying dog walker role: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(snapshot?.documents.isEmpty == false)
        }
    }
}
