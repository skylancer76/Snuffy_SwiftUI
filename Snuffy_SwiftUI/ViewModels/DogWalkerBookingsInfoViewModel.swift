//
//  DogWalkerBookingsInfoViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import Foundation
import FirebaseFirestore
import Combine

class DogWalkerBookingsInfoViewModel: ObservableObject {
    @Published var dogWalker: DogWalker?
    @Published var isLoading = true
    
    private let db = Firestore.firestore()
    
    func fetchDogWalkerDetails(dogWalkerId: String) {
        guard !dogWalkerId.isEmpty else {
            print("Dog walker ID is empty. Skipping fetch.")
            isLoading = false
            return
        }
        isLoading = true
        db.collection("dogwalkers")
            .document(dogWalkerId)
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("Error fetching dogwalker details: \(error.localizedDescription)")
                        return
                    }
                    if let data = document?.data() {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                            let decoded = try JSONDecoder().decode(DogWalker.self, from: jsonData)
                            self?.dogWalker = decoded
                        } catch {
                            print("Error decoding dogwalker: \(error.localizedDescription)")
                        }
                    } else {
                        print("No dogwalker found for ID: \(dogWalkerId)")
                    }
                }
            }
    }
}
