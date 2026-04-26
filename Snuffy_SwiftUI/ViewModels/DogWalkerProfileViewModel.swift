//
//  DogWalkerProfileViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI
import Combine
import CoreLocation
import FirebaseFirestore

class DogWalkerProfileViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published
    @Published var dogWalker: DogWalker?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var distanceText: String = "Distance unavailable"
    @Published var resolvedProfilePicURL: URL? = nil
    @Published var resolvedGalleryURLs: [URL] = []

    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var currentUserLocation: CLLocation?
    private var pendingWalkerId: String?

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Entry Point
    func load(dogWalkerId: String) {
        isLoading = true
        pendingWalkerId = dogWalkerId

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        if let loc = locationManager.location {
            currentUserLocation = loc
        }
        fetchDogWalkerData(dogWalkerId: dogWalkerId)
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentUserLocation = loc

        if let id = pendingWalkerId, dogWalker == nil {
            fetchDogWalkerData(dogWalkerId: id)
        } else if let walker = dogWalker {
            updateDistance(for: walker)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let id = pendingWalkerId, dogWalker == nil {
            fetchDogWalkerData(dogWalkerId: id)
        }
    }

    // MARK: - Firestore Fetch
    private func fetchDogWalkerData(dogWalkerId: String) {
        let db = Firestore.firestore()
        db.collection("dogwalkers")
            .whereField("dogWalkerId", isEqualTo: dogWalkerId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }

                    guard let doc = snapshot?.documents.first else {
                        self.errorMessage = "Dogwalker not found."
                        self.isLoading = false
                        return
                    }

                    if let walker = DogWalker(dictionary: doc.data()) {
                        self.dogWalker = walker
                        self.updateDistance(for: walker)
                        self.resolveURLs(for: walker)
                    } else {
                        self.errorMessage = "Could not read dogwalker data."
                        self.isLoading = false
                    }
                }
            }
    }

    // MARK: - URL Resolution
    private func resolveURLs(for walker: DogWalker) {
        let group = DispatchGroup()
        
        // Resolve profile pic
        if let pic = walker.profilePic, !pic.isEmpty {
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
        let baseNameFallback = walker.name.replacingOccurrences(of: " ", with: "")
        let galleryImages = walker.galleryImages ?? []
        
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
    private func updateDistance(for walker: DogWalker) {
        guard let lat = walker.latitude,
              let lon = walker.longitude,
              let userLoc = currentUserLocation else {
            distanceText = "Distance unavailable"
            return
        }
        let walkerLoc = CLLocation(latitude: lat, longitude: lon)
        let distKm = userLoc.distance(from: walkerLoc) / 1000.0
        distanceText = String(format: "%.1f km away", distKm)
        
        // Sync to Firestore (snuffy-main logic)
        FirebaseManager.shared.updateDistanceInFirestore(
            collection: "dogwalkers",
            id: walker.dogWalkerId,
            distance: distKm
        )
    }
}

// MARK: - DogWalker dictionary init
extension DogWalker {
    convenience init?(dictionary: [String: Any]) {
        guard
            let dogWalkerId      = dictionary["dogWalkerId"]       as? String,
            let name             = dictionary["name"]              as? String,
            let email            = dictionary["email"]             as? String,
            let password         = dictionary["password"]          as? String,
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

        let profilePic = dictionary["profilePic"] as? String
        let bio = dictionary["bio"] as? String
        let galleryImages = dictionary["galleryImages"] as? [String]

        self.init(
            dogWalkerId: dogWalkerId,
            name: name,
            email: email,
            password: password,
            profilePic: profilePic ?? "",
            rating: ratingString ?? "0.0",
            bio: bio,
            galleryImages: galleryImages,
            address: address,
            location: location,
            distanceAway: distanceAway,
            status: status,
            pendingRequests: pendingRequests,
            completedRequests: completedRequests,
            phoneNumber: phoneString
        )
    }
}
