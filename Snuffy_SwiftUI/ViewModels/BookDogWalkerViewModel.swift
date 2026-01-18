//
//  BookDogWalkerViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class BookDogWalkerViewModel: ObservableObject {
    @Published var petNames: [String] = []
    @Published var selectedPetName: String = ""
    @Published var selectedDate = Date()
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var walkingInstructions = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showNoPetsAlert = false
    @Published var shouldNavigateToAddress = false
    @Published var currentRequestId: String?
    
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
        
        // Validate times
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        guard let dateOnly = calendar.date(from: dateComponents) else { return }
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var combinedStartComponents = calendar.dateComponents([.year, .month, .day], from: dateOnly)
        combinedStartComponents.hour = startComponents.hour
        combinedStartComponents.minute = startComponents.minute
        
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        var combinedEndComponents = calendar.dateComponents([.year, .month, .day], from: dateOnly)
        combinedEndComponents.hour = endComponents.hour
        combinedEndComponents.minute = endComponents.minute
        
        guard let combinedStart = calendar.date(from: combinedStartComponents),
              let combinedEnd = calendar.date(from: combinedEndComponents) else {
            alertMessage = "Invalid time selection"
            showAlert = true
            return
        }
        
        guard combinedEnd >= combinedStart else {
            alertMessage = "End time must be after start time."
            showAlert = true
            return
        }
        
        // Create request ID and save initial request
        isLoading = true
        saveDogWalkerRequest()
    }
    
    private func saveDogWalkerRequest() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        let requestId = UUID().uuidString
        self.currentRequestId = requestId
        
        fetchUserName(userId: currentUser.uid) { [weak self] userName in
            guard let self = self else { return }
            
            var requestData: [String: Any] = [
                "requestId": requestId,
                "userId": currentUser.uid,
                "userName": userName,
                "petName": self.selectedPetName,
                "date": Timestamp(date: self.selectedDate),
                "startTime": Timestamp(date: self.startTime),
                "endTime": Timestamp(date: self.endTime),
                "instructions": self.walkingInstructions,
                "status": "available",
                "dogWalkerId": "",
                "timestamp": Timestamp(date: Date())
            ]
            
            FirebaseManager.shared.saveDogWalkerRequestData(data: requestData) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.alertMessage = "Failed to save request: \(error.localizedDescription)"
                        self.showAlert = true
                    } else {
                        self.shouldNavigateToAddress = true
                    }
                }
            }
        }
    }
    
    private func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Failed to fetch user name: \(error.localizedDescription)")
                completion("Anonymous User")
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let name = data["name"] as? String, !name.isEmpty {
                completion(name)
            } else {
                completion("Anonymous User")
            }
        }
    }
    
    func navigateToAddPet() {
        // TODO: Implement navigation to add pet
        print("Navigate to add pet screen")
    }
}
