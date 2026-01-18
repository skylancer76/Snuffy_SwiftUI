//
//  AddAddressViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import Combine
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class AddAddressViewModel: ObservableObject {
    @Published var selectedCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
    @Published var locationSearchText = ""
    @Published var houseNo = ""
    @Published var buildingNo = ""
    @Published var landmark = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var shouldNavigateToSuccess = false
    
    private var searchCompleter = MKLocalSearchCompleter()
    private let requestType: RequestType
    private let petName: String
    private let startDate: Date
    private let endDate: Date
    private let startTime: Date?
    private let endTime: Date?
    private let instructions: String
    private let isPetPickup: Bool
    private let isPetDropoff: Bool
    private let currentRequestId: String?
    
    init(requestType: RequestType,
         petName: String,
         startDate: Date,
         endDate: Date,
         startTime: Date? = nil,
         endTime: Date? = nil,
         instructions: String,
         isPetPickup: Bool = false,
         isPetDropoff: Bool = false,
         currentRequestId: String?) {
        
        self.requestType = requestType
        self.petName = petName
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = startTime
        self.endTime = endTime
        self.instructions = instructions
        self.isPetPickup = isPetPickup
        self.isPetDropoff = isPetDropoff
        self.currentRequestId = currentRequestId
        
        searchCompleter.resultTypes = .address
    }
    
    func setDefaultLocation() {
        let chennaiCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
        selectedCoordinate = chennaiCoordinate
        getAddressFromCoordinates(coordinate: chennaiCoordinate)
    }
    
    func handleMapTap(coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        getAddressFromCoordinates(coordinate: coordinate)
    }
    
    func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self, let response = response else {
                return
            }
            
            let completions = response.mapItems.map { item -> MKLocalSearchCompletion in
                CustomSearchCompletion(
                    title: item.name ?? "",
                    subtitle: item.placemark.title ?? ""
                )
            }
            
            DispatchQueue.main.async {
                self.searchResults = Array(completions.prefix(5))
            }
        }
    }
    
    func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchQuery = result.title + " " + result.subtitle
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let self = self,
                  let coordinate = response?.mapItems.first?.placemark.coordinate else {
                return
            }
            
            DispatchQueue.main.async {
                self.selectedCoordinate = coordinate
                self.locationSearchText = searchQuery
                self.searchResults = []
                self.getAddressFromCoordinates(coordinate: coordinate)
            }
        }
    }
    
    private func getAddressFromCoordinates(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first else {
                return
            }
            
            let addressString = [
                placemark.name,
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")
            
            DispatchQueue.main.async {
                self.locationSearchText = addressString
            }
        }
    }
    
    func scheduleRequest() {
        guard !locationSearchText.isEmpty, !houseNo.isEmpty, !buildingNo.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }
        
        let addressData: [String: Any] = [
            "location": locationSearchText,
            "houseNo": houseNo,
            "buildingNo": buildingNo,
            "landmark": landmark,
            "latitude": selectedCoordinate.latitude,
            "longitude": selectedCoordinate.longitude
        ]
        
        isLoading = true
        
        switch requestType {
        case .caretaker:
            scheduleCaretakerRequest(addressData: addressData)
        case .dogWalker:
            scheduleDogWalkerRequest(addressData: addressData)
        }
    }
    
    private func scheduleCaretakerRequest(addressData: [String: Any]) {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            alertMessage = "You must be logged in."
            showAlert = true
            return
        }
        
        let requestId = UUID().uuidString
        
        fetchUserName(userId: currentUser.uid) { [weak self] userName in
            guard let self = self else { return }
            
            var requestData: [String: Any] = [
                "requestId": requestId,
                "userId": currentUser.uid,
                "userName": userName,
                "petName": self.petName,
                "startDate": Timestamp(date: self.startDate),
                "endDate": Timestamp(date: self.endDate),
                "petPickup": self.isPetPickup,
                "petDropoff": self.isPetDropoff,
                "instructions": self.instructions,
                "status": "available",
                "timestamp": Timestamp(date: Date())
            ]
            
            // Merge address data
            for (key, value) in addressData {
                requestData[key] = value
            }
            
            FirebaseManager.shared.saveScheduleRequestData(data: requestData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Failed to save the schedule request."
                        self.showAlert = true
                    }
                } else {
                    let userLocation = CLLocation(
                        latitude: self.selectedCoordinate.latitude,
                        longitude: self.selectedCoordinate.longitude
                    )
                    
                    FirebaseManager.shared.autoAssignCaretaker(
                        petName: self.petName,
                        requestId: requestId,
                        userLocation: userLocation
                    ) { assignError in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let assignError = assignError {
                                print("Auto-assign error: \(assignError.localizedDescription)")
                            }
                            self.shouldNavigateToSuccess = true
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleDogWalkerRequest(addressData: [String: Any]) {
        guard let requestId = currentRequestId else {
            isLoading = false
            alertMessage = "No request ID found."
            showAlert = true
            return
        }
        
        let requestRef = Firestore.firestore().collection("dogWalkerRequests").document(requestId)
        
        requestRef.updateData(addressData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Could not update the request with address."
                    self.showAlert = true
                }
            } else {
                let userLocation = CLLocation(
                    latitude: self.selectedCoordinate.latitude,
                    longitude: self.selectedCoordinate.longitude
                )
                
                FirebaseManager.shared.autoAssignDogWalker(
                    petName: self.petName,
                    requestId: requestId,
                    userLocation: userLocation
                ) { assignError in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let assignError = assignError {
                            print("Auto-assign dogwalker error: \(assignError.localizedDescription)")
                        }
                        self.shouldNavigateToSuccess = true
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
}

class CustomSearchCompletion: NSObject, MKLocalSearchCompletion {
    var title: String
    var subtitle: String
    
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}
