//
//  PetProfileViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PetProfileViewModel: ObservableObject {
    @Published var pet: PetData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowDeleteAlert = false
    @Published var isDeleted = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    init(petId: String) {
        self.petId = petId
        fetchPetData()
    }
    
    func fetchPetData() {
        isLoading = true
        db.collection("Pets").document(petId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                self.pet = PetData(
                    petId: self.petId,
                    petImage: data["petImage"] as? String,
                    petName: data["petName"] as? String,
                    petBreed: data["petBreed"] as? String,
                    petGender: data["petGender"] as? String,
                    petAge: data["petAge"] as? String,
                    petWeight: data["petWeight"] as? String
                )
            } else {
                self.errorMessage = "Pet not found."
            }
        }
    }
    
    func deletePet() {
        db.collection("Pets").document(petId).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.isDeleted = true
            }
        }
    }
}
