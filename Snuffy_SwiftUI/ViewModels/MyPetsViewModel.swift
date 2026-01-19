//
//  MyPetsViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class MyPetsViewModel: ObservableObject {
    @Published var pets: [PetData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowAddPet = false
    @Published var selectedPet: PetData?
    @Published var shouldNavigateToPetProfile = false
    
    private var petsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        fetchPets()
    }
    
    func fetchPets() {
        guard let currentUser = Auth.auth().currentUser else {
            self.errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        
        // Remove existing listener if any
        petsListener?.remove()
        
        petsListener = db.collection("Pets")
            .whereField("ownerID", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.pets = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return PetData(
                        petId: data["petId"] as? String ?? document.documentID,
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
    
    func deletePet(at offsets: IndexSet) {
        let petsToDelete = offsets.map { pets[$0] }
        for pet in petsToDelete {
            db.collection("Pets").document(pet.petId).delete { error in
                if let error = error {
                    print("Error deleting pet: \(error.localizedDescription)")
                }
            }
        }
    }
    
    deinit {
        petsListener?.remove()
    }
}
