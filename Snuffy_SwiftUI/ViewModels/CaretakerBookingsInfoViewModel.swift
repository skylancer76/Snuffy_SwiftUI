//
//  CaretakerBookingsInfoViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import Foundation
import FirebaseFirestore
import Combine

class CaretakerBookingsInfoViewModel: ObservableObject {
    @Published var caretaker: Caretakers?
    @Published var caretakerDocumentId: String?   // actual Firestore document ID
    @Published var isLoading = true

    private let db = Firestore.firestore()

    func fetchCaretakerDetails(caretakerId: String) {
        guard !caretakerId.isEmpty else {
            isLoading = false
            return
        }
        isLoading = true
        db.collection("caretakers")
            .whereField("caretakerId", isEqualTo: caretakerId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("Error fetching caretaker details: \(error.localizedDescription)")
                        return
                    }
                    guard let doc = snapshot?.documents.first else {
                        print("No caretaker found for ID: \(caretakerId)")
                        return
                    }
                    // Store the real document ID so ratings land on the correct document
                    self?.caretakerDocumentId = doc.documentID
                    let data = doc.data()
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                        let decoded = try JSONDecoder().decode(Caretakers.self, from: jsonData)
                        self?.caretaker = decoded
                    } catch {
                        print("Error decoding caretaker: \(error.localizedDescription)")
                    }
                }
            }
    }
}
