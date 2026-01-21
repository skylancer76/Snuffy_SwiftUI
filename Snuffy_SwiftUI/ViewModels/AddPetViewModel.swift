//
//  AddPetViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class AddPetViewModel: ObservableObject {
    
    @Published var petName = ""
    @Published var petBreed = ""
    @Published var petAge = "1 Year"
    @Published var petGender = "Male"
    @Published var petWeight = ""
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    let genders = ["Male", "Female"]
    let breeds = ["Labrador", "German Shepherd", "Golden Retriever", "Poodle", "Bulldog", "Rottweiler", "Other"]
    let ages = (1...20).map { "\($0) \($0 == 1 ? "Year" : "Years")" }
    
    init() {}
    
    func savePet() {
        guard !petName.isEmpty, !petBreed.isEmpty else {
            errorMessage = "Please fill in all mandatory fields."
            return
        }
        
        isLoading = true
        let petId = UUID().uuidString
        
        if let image = selectedImage {
            uploadImage(image, petId: petId) { [weak self] result in
                switch result {
                case .success(let url):
                    self?.savePetData(petId: petId, imageUrl: url)
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        } else {
            savePetData(petId: petId, imageUrl: nil)
        }
    }
    
    private func uploadImage(_ image: UIImage, petId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child("pet_images/\(petId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image."])))
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    private func savePetData(petId: String, imageUrl: String?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let petData: [String: Any] = [
            "petId": petId,
            "petName": petName,
            "petBreed": petBreed,
            "petAge": petAge,
            "petGender": petGender,
            "petWeight": petWeight,
            "petImage": imageUrl ?? "",
            "ownerID": userId
        ]
        
        db.collection("Pets").document(petId).setData(petData) { [weak self] error in
            self?.isLoading = false
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.isSuccess = true
            }
        }
    }
}
