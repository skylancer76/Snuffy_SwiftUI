//
//  HomeViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var homePets: [PetData] = []
    @Published var userInitials: String = "U"
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var shouldNavigateToProfile = false
    @Published var shouldNavigateToPetProfile = false
    @Published var shouldNavigateToLogin = false
    @Published var shouldNavigateToCaretakerBooking = false
    @Published var shouldNavigateToDogWalkerBooking = false
    @Published var shouldNavigateToMyPets = false
    @Published var selectedPet: PetData?
    @Published var searchText: String = ""

    // MARK: - Search state
    @Published var shouldScrollToMyPets: Bool = false
    @Published var isSearchingPet: Bool = false
    @Published var petSearchError: String? = nil

    private var homePetsListener: ListenerRegistration?

    // MARK: - Search Logic

    /// Called from HomeView's `handleSearch` for Firestore pet-name lookup
    func searchPetByName(_ name: String) {
        // 1. Quick local check first
        let lower = name.lowercased()
        if let foundPet = homePets.first(where: { ($0.petName ?? "").lowercased() == lower }) {
            selectedPet = foundPet
            shouldNavigateToPetProfile = true
            return
        }

        // 2. Fallback to Firestore
        isSearchingPet = true
        petSearchError = nil
        searchPetInDB(name: name)
    }

    private func searchPetInDB(name: String) {
        let db = Firestore.firestore()
        // Try exact capitalised form; also try trimmed lowercased
        db.collection("Pets")
            .whereField("petName", isEqualTo: name.capitalized)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.isSearchingPet = false

                    if let error = error {
                        self.petSearchError = "Error searching pet: \(error.localizedDescription)"
                        return
                    }

                    if let document = snapshot?.documents.first {
                        let data = document.data()
                        self.selectedPet = PetData(
                            petId: data["petId"] as? String ?? document.documentID,
                            petImage: data["petImage"] as? String,
                            petName: data["petName"] as? String,
                            petBreed: data["petBreed"] as? String,
                            petGender: data["petGender"] as? String,
                            petAge: data["petAge"] as? String,
                            petWeight: data["petWeight"] as? String
                        )
                        self.shouldNavigateToPetProfile = true
                    } else {
                        self.petSearchError = "No pet found with the name \"\(name.capitalized)\""
                    }
                }
            }
    }

    // MARK: - Authentication
    func checkUserAuthentication() {
        if Auth.auth().currentUser == nil {
            shouldNavigateToLogin = true
        }
    }

    // MARK: - Fetch User Profile
    func fetchUserNameAndSetupProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let document = document,
               document.exists,
               let data = document.data(),
               let name = data["name"] as? String,
               let email = data["email"] as? String {
                DispatchQueue.main.async {
                    self.userName = name
                    self.userEmail = email
                    self.userInitials = self.getInitials(from: name)
                }
            } else {
                print("User document not found or missing fields: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.userInitials = "U"
                    self.userName = "Unknown User"
                    self.userEmail = Auth.auth().currentUser?.email ?? ""
                }
            }
        }
    }

    private func getInitials(from name: String) -> String {
        let nameParts = name.split(separator: " ")
        let initials = nameParts.compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }

    // MARK: - Fetch Pets (Firebase)
    func fetchPetsForHomeScreen() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        homePetsListener = db.collection("Pets")
            .whereField("ownerID", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching pet data for Home: \(error.localizedDescription)")
                    return
                }

                DispatchQueue.main.async {
                    self.homePets = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        return PetData(
                            petId: data["petId"] as? String ?? document.documentID,
                            petImage: data["petImage"] as? String,
                            petName: data["petName"] as? String,
                            petBreed: data["petBreed"] as? String,
                            petGender: data["petGender"] as? String,
                            petAge: data["petAge"] as? String,
                            petWeight: data["petWeight"] as? String
                        )
                    } ?? []
                }
            }
    }

    // MARK: - Navigation Actions
    func navigateToPetSitting() {
        shouldNavigateToCaretakerBooking = true
    }

    func navigateToPetWalking() {
        shouldNavigateToDogWalkerBooking = true
    }

    func moveToMyPets() {
        shouldNavigateToMyPets = true
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            shouldNavigateToLogin = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    deinit {
        homePetsListener?.remove()
    }
}
