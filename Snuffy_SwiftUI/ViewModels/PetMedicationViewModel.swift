//
//  PetMedicationViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class PetMedicationViewModel: ObservableObject {
    @Published var medications: [PetMedicationDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowAddMedication = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    init(petId: String) {
        self.petId = petId
        fetchMedications()
    }
    
    func fetchMedications() {
        isLoading = true
        db.collection("Pets")
            .document(petId)
            .collection("PetMedication")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.medications = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return PetMedicationDetails(
                        medicationId: document.documentID,
                        medicineName: data["medicineName"] as? String ?? "",
                        medicineType: data["medicineType"] as? String ?? "",
                        purpose: data["purpose"] as? String ?? "",
                        frequency: data["frequency"] as? String ?? "",
                        dosage: data["dosage"] as? String ?? "",
                        startDate: data["startDate"] as? String ?? "",
                        endDate: data["endDate"] as? String ?? ""
                    )
                } ?? []
            }
    }
}
