//
//  CaregiverOnboardingViewModel.swift
//  Snuffy_SwiftUI
//
//  Authored by bhumika sharam
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import CoreLocation

class CaregiverOnboardingViewModel: ObservableObject {

    // MARK: - Form Fields
    @Published var address: String = ""
    @Published var bio: String = ""
    @Published var phoneNumber: String = ""
    @Published var experience: String = ""          // caretaker only
    @Published var petsHandled: String = ""
    @Published var certification: String = ""
    @Published var lor: String = ""

    // MARK: - Images (max 4, first = profile)
    @Published var selectedImages: [UIImage?] = [nil, nil, nil, nil]
    @Published var selectedItems: [PhotosPickerItem?] = [nil, nil, nil, nil]

    // MARK: - State
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var submittedSuccessfully = false

    // MARK: - Location
    @Published var isLocationLoading = false
    @Published var locationStatus: String = ""
    @Published var hasLocationPermission = false
    @Published var detectedLatitude: Double?
    @Published var detectedLongitude: Double?
    private let locationManager = LocationManager.shared

    private let db = Firestore.firestore()

    // MARK: - Request Location Permission on Init
    func requestLocationPermission() {
        locationManager.requestLocationPermission()

        // Observe authorization changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateLocationStatus()
        }
    }

    /// Actively fetch the user's coordinates (GPS or geocoded from address)
    func detectLocation() {
        isLocationLoading = true
        locationStatus = "Detecting your location..."

        locationManager.getLocationForOnboarding(address: address) { [weak self] latitude, longitude in
            DispatchQueue.main.async {
                self?.isLocationLoading = false
                if latitude != 0.0 || longitude != 0.0 {
                    self?.detectedLatitude = latitude
                    self?.detectedLongitude = longitude
                    self?.hasLocationPermission = true
                    self?.locationStatus = String(
                        format: "Location detected: %.4f, %.4f",
                        latitude, longitude
                    )
                } else {
                    self?.locationStatus = "Could not detect location. Enter a detailed address."
                }
            }
        }
    }

    private func updateLocationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
            locationStatus = "Location access granted. Tap detect to fetch coordinates."
        case .denied, .restricted:
            hasLocationPermission = false
            locationStatus = "Location denied — will geocode from your address"
        case .notDetermined:
            hasLocationPermission = false
            locationStatus = "Tap to allow location access"
        @unknown default:
            hasLocationPermission = false
            locationStatus = ""
        }
    }

    // MARK: - Submit
    func submit(role: UserRole, roleVM: UserRoleViewModel) {
        guard validate() else { return }

        isLoading = true
        isLocationLoading = true
        locationStatus = "Getting your location..."

        // Capture all values BEFORE async calls to avoid weak self issues
        let addressValue = self.address
        let bioValue = self.bio
        let phoneNumberValue = self.phoneNumber
        let certificationValue = self.certification
        let lorValue = self.lor
        let experienceValue = self.experience
        let petsHandledValue = self.petsHandled

        // First get location, then upload images and save data
        locationManager.getLocationForOnboarding(address: addressValue) { [weak self] latitude, longitude in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLocationLoading = false
                self.locationStatus = "Location obtained!"
            }

            print("[CaregiverOnboarding] 📍 Got location: \(latitude), \(longitude)")

            self.uploadAllImages { [weak self] urls in
                guard let self = self else {
                    print("[CaregiverOnboarding] ❌ Self is nil after image upload")
                    return
                }

                let profilePic = urls.first ?? ""
                let galleryImages = Array(urls)

                guard let uid = Auth.auth().currentUser?.uid else {
                    self.finish(error: "Not authenticated.")
                    return
                }

                print("[CaregiverOnboarding] 📤 Starting profile update for uid=\(uid)")

                let exp = Int(experienceValue) ?? 0
                let pets = Int(petsHandledValue) ?? 0

                var update: [String: Any] = [
                    "address": addressValue,
                    "bio": bioValue,
                    "phoneNumber": phoneNumberValue,
                    "petsHandled": pets,
                    "certification": certificationValue,
                    "lor": lorValue,
                    "galleryImages": galleryImages,
                    "isProfileComplete": true,
                    // Add location data for caretaker/dogwalker matching
                    "location": [latitude, longitude],
                    "distanceAway": 0.0  // Will be calculated dynamically when matching
                ]

                if !profilePic.isEmpty {
                    update["profilePic"] = profilePic
                }

                let collection: String
                let notifRole: String

                switch role {
                case .caretaker:
                    collection = "caretakers"
                    notifRole = "caretaker"
                    update["experience"] = exp
                case .dogWalker:
                    collection = "dogwalkers"
                    notifRole = "dogwalker"
                default:
                    collection = "caretakers"
                    notifRole = "caretaker"
                }

                // Prepare notification data BEFORE Firestore call
                let notifName = Auth.auth().currentUser?.displayName?.isEmpty == false
                    ? Auth.auth().currentUser!.displayName!
                    : (Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "New Applicant")
                let notifEmail = Auth.auth().currentUser?.email ?? ""

                print("[CaregiverOnboarding] 📝 Updating \(collection) document for uid=\(uid) with location [\(latitude), \(longitude)]")

                // Use setData with merge instead of updateData for more reliability
                self.db.collection(collection).document(uid).setData(update, merge: true) { error in
                    if let error = error {
                        print("[CaregiverOnboarding] ❌ Firestore update FAILED: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.alertMessage = error.localizedDescription
                            self.showAlert = true
                        }
                        return
                    }

                    print("[CaregiverOnboarding] ✅ Firestore update SUCCESS with location data")
                    print("[CaregiverOnboarding] 🔔 Sending admin notification for uid=\(uid) role=\(notifRole)")

                    // Send admin notification
                    if role == .caretaker {
                        AdminNotificationService.shared.sendCaretakerApprovalRequest(
                            uid: uid,
                            name: notifName,
                            email: notifEmail,
                            address: addressValue,
                            bio: bioValue,
                            experience: exp,
                            petsHandled: pets,
                            phoneNumber: phoneNumberValue,
                            certification: certificationValue,
                            lor: lorValue,
                            galleryImages: galleryImages
                        )
                    } else {
                        AdminNotificationService.shared.sendDogWalkerApprovalRequest(
                            uid: uid,
                            name: notifName,
                            email: notifEmail,
                            address: addressValue,
                            bio: bioValue,
                            petsHandled: pets,
                            phoneNumber: phoneNumberValue,
                            certification: certificationValue,
                            lor: lorValue,
                            galleryImages: galleryImages
                        )
                    }

                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.submittedSuccessfully = true
                        roleVM.isProfileComplete = true
                    }
                }
            }
        }
    }

    // MARK: - Validation
    private func validate() -> Bool {
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        if trimmedAddress.isEmpty {
            alertMessage = "Please enter your address."
            showAlert = true
            return false
        }
        // Validate address has enough detail for geocoding (at least area/city)
        if trimmedAddress.count < 15 {
            alertMessage = "Please enter a more detailed address including area, city and pincode for accurate location."
            showAlert = true
            return false
        }
        if bio.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter a short bio about yourself."
            showAlert = true
            return false
        }
        if phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your phone number."
            showAlert = true
            return false
        }
        if selectedImages.compactMap({ $0 }).isEmpty {
            alertMessage = "Please upload at least one photo."
            showAlert = true
            return false
        }
        return true
    }

    // MARK: - Image Upload
    private func uploadAllImages(completion: @escaping ([String]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        let images = selectedImages.compactMap { $0 }
        if images.isEmpty {
            completion([])
            return
        }

        let group = DispatchGroup()
        var urls: [String?] = Array(repeating: nil, count: images.count)

        for (i, image) in images.enumerated() {
            group.enter()
            let path = "caregiver_onboarding/\(uid)/image_\(i).jpg"
            let ref = Storage.storage().reference().child(path)
            guard let data = image.jpegData(compressionQuality: 0.75) else {
                group.leave()
                continue
            }
            ref.putData(data, metadata: nil) { _, error in
                if error != nil { group.leave(); return }
                ref.downloadURL { url, _ in
                    urls[i] = url?.absoluteString
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(urls.compactMap { $0 })
        }
    }

    private func finish(error: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.alertMessage = error
            self.showAlert = true
        }
    }

    // MARK: - Load photo from picker item
    func loadImage(from item: PhotosPickerItem?, into index: Int) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data, let uiImage = UIImage(data: data) {
                        self?.selectedImages[index] = uiImage
                    }
                case .failure:
                    break
                }
            }
        }
    }
    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("[CaregiverOnboarding] ❌ Logout failed: \(error.localizedDescription)")
        }
    }
}
