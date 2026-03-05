//
//  CaretakerProfileViewModel.swift
//  Snuffy_SwiftUI
//

import SwiftUI
import Combine
import CoreLocation
import FirebaseFirestore

class CaretakerProfileViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published
    @Published var caretaker: Caretakers?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var distanceText: String = "Distance unavailable"
    @Published var resolvedProfilePicURL: URL? = nil
    @Published var resolvedGalleryURLs: [URL] = []

    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var currentUserLocation: CLLocation?
    private var pendingCaretakerId: String?

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Entry Point
    func load(caretakerId: String) {
        isLoading = true
        pendingCaretakerId = caretakerId

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Fetch immediately (don't wait for location)
        if let loc = locationManager.location {
            currentUserLocation = loc
        }
        fetchCaretakerData(caretakerId: caretakerId)
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentUserLocation = loc
        
        // Don't stop updating immediately if we want to reactive distance, 
        // but for profile view, one stable location is usually enough.
        // locationManager.stopUpdatingLocation() 

        if let id = pendingCaretakerId, caretaker == nil {
            fetchCaretakerData(caretakerId: id)
        } else if let ct = caretaker {
            updateDistance(for: ct)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let id = pendingCaretakerId, caretaker == nil {
            fetchCaretakerData(caretakerId: id)
        }
    }

    // MARK: - Firestore Fetch
    private func fetchCaretakerData(caretakerId: String) {
        let db = Firestore.firestore()
        db.collection("caretakers")
            .whereField("caretakerId", isEqualTo: caretakerId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }

                    guard let doc = snapshot?.documents.first else {
                        self.errorMessage = "Caretaker not found."
                        self.isLoading = false
                        return
                    }

                    if let ct = Caretakers(dictionary: doc.data()) {
                        self.caretaker = ct
                        self.updateDistance(for: ct)
                        self.resolveURLs(for: ct)
                    } else {
                        self.errorMessage = "Could not read caretaker data."
                        self.isLoading = false
                    }
                }
            }
    }

    // MARK: - URL Resolution
    private func resolveURLs(for ct: Caretakers) {
        let group = DispatchGroup()
        
        // Resolve profile pic (assuming it might still be remote/resolvable)
        if let pic = ct.profilePic, !pic.isEmpty {
            group.enter()
            FirebaseManager.shared.getDownloadURL(from: pic) { [weak self] url, _ in
                DispatchQueue.main.async {
                    self?.resolvedProfilePicURL = url
                }
                group.leave()
            }
        }
        
        // Gallery Priority: Item in galleryImages -> local pattern fallback
        var galleryURLs: [URL] = []
        let baseNameFallback = ct.name.replacingOccurrences(of: " ", with: "")
        let galleryImages = ct.galleryImages ?? []
        
        if !galleryImages.isEmpty {
            for imageName in galleryImages {
                if let url = URL(string: "local://\(imageName)") {
                    galleryURLs.append(url)
                }
            }
        } else {
            // Fallback to Name1, Name2, etc.
            for i in 1...4 {
                if let url = URL(string: "local://\(baseNameFallback)\(i)") {
                    galleryURLs.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.resolvedGalleryURLs = galleryURLs
            self.isLoading = false
        }
    }

    // MARK: - Distance Calculation
    private func updateDistance(for ct: Caretakers) {
        guard let lat = ct.latitude,
              let lon = ct.longitude,
              let userLoc = currentUserLocation else {
            distanceText = "Distance unavailable"
            return
        }
        let caretakerLoc = CLLocation(latitude: lat, longitude: lon)
        let distKm = userLoc.distance(from: caretakerLoc) / 1000.0
        distanceText = String(format: "%.1f km away", distKm)
        
        // Sync to Firestore (from snuffy-main logic)
        FirebaseManager.shared.updateDistanceInFirestore(
            collection: "caretakers",
            id: ct.caretakerId,
            distance: distKm
        )
    }
}

// MARK: - Caretakers dictionary init (mirrors snuffy-main convenience init)
extension Caretakers {
    convenience init?(dictionary: [String: Any]) {
        guard
            let caretakerId      = dictionary["caretakerId"]       as? String,
            let name             = dictionary["name"]              as? String,
            let email            = dictionary["email"]             as? String,
            let password         = dictionary["password"]          as? String,
            let bio              = dictionary["bio"]               as? String,
            let experience       = dictionary["experience"]        as? Int,
            let address          = dictionary["address"]           as? String,
            let location         = dictionary["location"]          as? [Double],
            let distanceAway     = dictionary["distanceAway"]      as? Double,
            let status           = dictionary["status"]            as? String,
            let pendingRequests  = dictionary["pendingRequests"]   as? [String],
            let completedRequests = dictionary["completedRequests"] as? Int
        else { return nil }

        var ratingString: String? = nil
        if let v = dictionary["rating"] {
            if let s = v as? String { ratingString = s }
            else if let n = v as? NSNumber { ratingString = n.stringValue }
        }

        var phoneString: String? = nil
        if let v = dictionary["phoneNumber"] {
            if let s = v as? String { phoneString = s }
            else if let n = v as? NSNumber { phoneString = n.stringValue }
        }

        let profilePic    = dictionary["profilePic"]    as? String
        let petSitted     = dictionary["petSitted"]     as? String
        let galleryImages = dictionary["galleryImages"] as? [String]

        self.init(
            caretakerId: caretakerId,
            name: name,
            email: email,
            password: password,
            profilePic: profilePic,
            petSitted: petSitted,
            galleryImages: galleryImages,
            bio: bio,
            experience: experience,
            address: address,
            location: location,
            rating: ratingString,
            distanceAway: distanceAway,
            status: status,
            pendingRequests: pendingRequests,
            completedRequests: completedRequests,
            phoneNumber: phoneString
        )
    }
}
