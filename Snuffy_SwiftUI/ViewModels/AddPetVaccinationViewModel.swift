//
//  AddPetVaccinationViewModel.swift
//  Snuffy_SwiftUI
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class AddPetVaccinationViewModel: ObservableObject {
    @Published var vaccineName = ""
    @Published var dateOfVaccination = Date()
    @Published var expires = true
    @Published var expiryDate = Date()
    @Published var notifyUponExpiry = true
    @Published var notes = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    let vaccineOptions = ["Rabies", "Distemper", "Parvovirus", "Adenovirus", "Leptospirosis", "Bordetella", "Lyme Disease", "Other"]
    
    init(petId: String) {
        self.petId = petId
    }
    
    func saveVaccination() {
        guard !vaccineName.isEmpty else {
            errorMessage = "Please select or enter a vaccine name."
            return
        }
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        
        let vaccinationData: [String: Any] = [
            "vaccineName": vaccineName,
            "dateOfVaccination": dateFormatter.string(from: dateOfVaccination),
            "expires": expires,
            "expiryDate": expires ? dateFormatter.string(from: expiryDate) : "",
            "notifyUponExpiry": notifyUponExpiry,
            "notes": notes
        ]
        
        db.collection("Pets")
            .document(petId)
            .collection("Vaccinations")
            .addDocument(data: vaccinationData) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isSuccess = true
                }
            }
    }
}
