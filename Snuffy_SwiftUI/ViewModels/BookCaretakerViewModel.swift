//
//  BookCaretakerViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class BookCaretakerViewModel: ObservableObject {
    @Published var petNames: [String] = []
    @Published var selectedPetName: String = ""
    @Published var startDate = Date()
    @Published var endDate = Date()
    @Published var isPetPickup = false
    @Published var isPetDropoff = false
    @Published var caretakingInstructions = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showNoPetsAlert = false
    @Published var shouldNavigateToAddress = false
    
    func fetchPetNames() {
        guard let currentUser = Auth.auth().currentUser else {
            showAlert = true
            alertMessage = "No logged in user found."
            return
        }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(currentUser.uid)
        
        userDocRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let petIds = data["petIds"] as? [String], !petIds.isEmpty else {
                DispatchQueue.main.async {
                    self.showNoPetsAlert = true
                }
                return
            }
            
            db.collection("Pets")
                .whereField(FieldPath.documentID(), in: petIds)
                .getDocuments { snapshot, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error fetching pets: \(error.localizedDescription)")
                            self.petNames = []
                        } else if let snapshot = snapshot {
                            self.petNames = snapshot.documents.compactMap { doc in
                                doc.data()["petName"] as? String
                            }
                            
                            // Auto-select first pet
                            if let firstPet = self.petNames.first {
                                self.selectedPetName = firstPet
                            }
                        }
                        
                        if self.petNames.isEmpty {
                            self.showNoPetsAlert = true
                        }
                    }
                }
        }
    }
    
    func proceedToAddress() {
        guard !selectedPetName.isEmpty else {
            alertMessage = "Please select a pet"
            showAlert = true
            return
        }
        
        guard endDate >= startDate else {
            alertMessage = "End date must be after start date."
            showAlert = true
            return
        }
        
        shouldNavigateToAddress = true
    }
    
    func navigateToAddPet() {
        // TODO: Implement navigation to add pet
        print("Navigate to add pet screen")
    }
}
