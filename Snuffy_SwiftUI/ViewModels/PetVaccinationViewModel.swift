//
//  PetVaccinationViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class PetVaccinationViewModel: ObservableObject {
    @Published var vaccinations: [VaccinationDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowAddVaccine = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    init(petId: String) {
        self.petId = petId
        fetchVaccinations()
    }
    
    func fetchVaccinations() {
        isLoading = true
        db.collection("Pets")
            .document(petId)
            .collection("Vaccinations")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.vaccinations = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return VaccinationDetails(
                        vaccineId: document.documentID,
                        vaccineName: data["vaccineName"] as? String ?? "",
                        dateOfVaccination: data["dateOfVaccination"] as? String ?? "",
                        expires: data["expires"] as? Bool ?? false,
                        expiryDate: data["expiryDate"] as? String,
                        notifyUponExpiry: data["notifyUponExpiry"] as? Bool ?? false,
                        notes: data["notes"] as? String
                    )
                } ?? []
            }
    }
}
