//
//  HomeViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var homePets: [PetData] = []
    @Published var userInitials: String = "U"
    @Published var shouldNavigateToProfile = false
    @Published var shouldNavigateToPetProfile = false
    @Published var shouldNavigateToLogin = false
    @Published var shouldNavigateToCaretakerBooking = false
    @Published var shouldNavigateToDogWalkerBooking = false
    @Published var shouldNavigateToMyPets = false
    @Published var selectedPet: PetData?
    
    private var homePetsListener: ListenerRegistration?
    
    // MARK: - Authentication
    func checkUserAuthentication() {
        if Auth.auth().currentUser == nil {
            shouldNavigateToLogin = true
        }
    }
    
    // MARK: - Fetch User Profile
    func fetchUserNameAndSetupProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document,
               document.exists,
               let data = document.data(),
               let name = data["name"] as? String {
                DispatchQueue.main.async {
                    self.userInitials = self.getInitials(from: name)
                }
            } else {
                print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.userInitials = "U"
                }
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        let nameParts = name.split(separator: " ")
        let initials = nameParts.compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }
    
    // MARK: - Fetch Pets (Firebase)
    func fetchPetsForHomeScreen() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        homePetsListener = db.collection("Pets")
            .whereField("ownerID", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching pet data for Home: \(error.localizedDescription)")
                    return
                }
                
                self.homePets = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return PetData(
                        petId: data["petId"] as? String ?? "",
                        petImage: data["petImage"] as? String,
                        petName: data["petName"] as? String,
                        petBreed: data["petBreed"] as? String,
                        petGender: data["petGender"] as? String,
                        petAge: data["petAge"] as? String,
                        petWeight: data["petWeight"] as? String
                    )
                } ?? []
            }
    }
    
    // MARK: - Navigation Actions
    func navigateToPetSitting() {
        shouldNavigateToCaretakerBooking = true
    }
    
    func navigateToPetWalking() {
        shouldNavigateToDogWalkerBooking = true
    }
    
    func moveToMyPets() {
        shouldNavigateToMyPets = true
    }
    
    deinit {
        homePetsListener?.remove()
    }
}
