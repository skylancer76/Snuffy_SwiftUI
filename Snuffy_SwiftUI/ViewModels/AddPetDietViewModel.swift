//
//  AddPetDietViewModel.swift
//  Snuffy_SwiftUI
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class AddPetDietViewModel: ObservableObject {
    @Published var mealType = "Breakfast"
    @Published var foodName = ""
    @Published var foodCategory = "Dry Food"
    @Published var portionSize = ""
    @Published var feedingFrequency = ""
    @Published var servingTime = Date()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let db = Firestore.firestore()
    private let petId: String
    
    let foodCategories = ["Dry Food", "Wet Food", "Raw Food"]
    let mealTypes = ["Breakfast", "Lunch", "Dinner"]
    
    init(petId: String) {
        self.petId = petId
    }
    
    func saveDiet() {
        guard !foodName.isEmpty, !portionSize.isEmpty, !feedingFrequency.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        
        let dietData: [String: Any] = [
            "mealType": mealType,
            "foodName": foodName,
            "foodCategory": foodCategory,
            "portionSize": portionSize,
            "feedingFrequency": feedingFrequency,
            "servingTime": timeFormatter.string(from: servingTime)
        ]
        
        db.collection("Pets")
            .document(petId)
            .collection("PetDiet")
            .addDocument(data: dietData) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isSuccess = true
                }
            }
    }
}
