//
//  AddPetMedicationViewModel.swift
//  Snuffy_SwiftUI
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class AddPetMedicationViewModel: ObservableObject {
    @Published var medicineName = ""
    @Published var medicineType = "Tablet"
    @Published var purpose = ""
    @Published var frequency = ""
    @Published var dosage = ""
    @Published var startDate = Date()
    @Published var endDate = Date()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    let medicineTypes = ["Tablet", "Syrup", "Ointment", "Injection"]
    
    init(petId: String) {
        self.petId = petId
    }
    
    func saveMedication() {
        guard !medicineName.isEmpty, !purpose.isEmpty, !frequency.isEmpty, !dosage.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let medicationData: [String: Any] = [
            "medicineName": medicineName,
            "medicineType": medicineType,
            "purpose": purpose,
            "frequency": frequency,
            "dosage": dosage,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate)
        ]
        
        db.collection("Pets")
            .document(petId)
            .collection("PetMedication")
            .addDocument(data: medicationData) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isSuccess = true
                }
            }
    }
}
