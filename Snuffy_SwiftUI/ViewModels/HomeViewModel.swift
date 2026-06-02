import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class HomeViewModel: ObservableObject {
    @Published var homePets: [PetData] = []
    @Published var userInitials: String = "U"
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profilePicURL: String? = nil
    @Published var memberSince: String = ""
    @Published var isUploadingProfilePic: Bool = false
    @Published var shouldNavigateToProfile = false
    @Published var shouldNavigateToPetProfile = false
    @Published var shouldNavigateToLogin = false
    @Published var shouldNavigateToCaretakerBooking = false
    @Published var shouldNavigateToDogWalkerBooking = false
    @Published var shouldNavigateToMyPets = false
    @Published var selectedPet: PetData?
    @Published var searchText: String = ""

    // MARK: - Delete account state
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String? = nil

    // MARK: - Search state
    @Published var shouldScrollToMyPets: Bool = false
    @Published var isSearchingPet: Bool = false
    @Published var petSearchError: String? = nil

    private var homePetsListener: ListenerRegistration?

    // MARK: - Search Logic

    func searchPetByName(_ name: String) {
        let lower = name.lowercased()
        if let foundPet = homePets.first(where: { ($0.petName ?? "").lowercased() == lower }) {
            selectedPet = foundPet
            shouldNavigateToPetProfile = true
            return
        }

        isSearchingPet = true
        petSearchError = nil
        searchPetInDB(name: name)
    }

    private func searchPetInDB(name: String) {
        let db = Firestore.firestore()
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
                    self.profilePicURL = data["profilePicURL"] as? String
                    // Parse createdAt
                    if let timestamp = data["createdAt"] as? Timestamp {
                        let date = timestamp.dateValue()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMMM yyyy"
                        self.memberSince = formatter.string(from: date)
                    }
                }
            } else {
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
        }
    }

    @MainActor
    func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        deleteAccountError = nil
        do {
            try await DeleteAccountService.shared.deleteCurrentUser()
            shouldNavigateToLogin = true
        } catch let err as DeleteAccountError {
            deleteAccountError = err.errorDescription
        } catch {
            deleteAccountError = error.localizedDescription
        }
        isDeletingAccount = false
    }

    // MARK: - Profile Picture Upload
    func uploadProfilePicture(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.6) else { return }

        isUploadingProfilePic = true
        let storageRef = Storage.storage().reference().child("user_profile_pictures/\(userId).jpg")

        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async { self?.isUploadingProfilePic = false }
                return
            }

            storageRef.downloadURL { [weak self] url, error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async { self.isUploadingProfilePic = false }
                    return
                }

                if let url = url {
                    let urlString = url.absoluteString
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).updateData(["profilePicURL": urlString]) { error in
                        DispatchQueue.main.async {
                            self.isUploadingProfilePic = false
                            if error == nil {
                                self.profilePicURL = urlString
                            } else {
                            }
                        }
                    }
                }
            }
        }
    }

    deinit {
        homePetsListener?.remove()
    }
}
