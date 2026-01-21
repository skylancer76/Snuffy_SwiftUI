//
//  PetDietViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class PetDietViewModel: ObservableObject {
    @Published var diets: [PetDietDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowAddDiet = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    init(petId: String) {
        self.petId = petId
        fetchDiets()
    }
    
    func fetchDiets() {
        isLoading = true
        db.collection("Pets")
            .document(petId)
            .collection("PetDiet")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.diets = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return PetDietDetails(
                        dietId: document.documentID,
                        mealType: data["mealType"] as? String ?? "",
                        foodName: data["foodName"] as? String ?? "",
                        foodCategory: data["foodCategory"] as? String ?? "",
                        portionSize: data["portionSize"] as? String ?? "",
                        feedingFrequency: data["feedingFrequency"] as? String ?? "",
                        servingTime: data["servingTime"] as? String ?? ""
                    )
                } ?? []
            }
    }
}
