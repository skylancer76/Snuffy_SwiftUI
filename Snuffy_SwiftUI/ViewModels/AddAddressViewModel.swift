import SwiftUI
import Combine
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class AddAddressViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var selectedCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
    @Published var locationSearchText = ""
    @Published var houseNo = ""
    @Published var buildingNo = ""
    @Published var landmark = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var shouldNavigateToSuccess = false
    
    // MARK: - Private Properties (Data passed from previous screen)
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
    
    // MARK: - Initialization
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
    }
    
    // MARK: - Autocomplete Properties
    private var searchCompleter = MKLocalSearchCompleter()
    @Published var searchResults: [MKLocalSearchCompletion] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Set Default Location (Chennai)
    func setDefaultLocation() {
        // Default to Chennai coordinates (matches UIKit)
        let chennaiCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
        selectedCoordinate = chennaiCoordinate
        getAddressFromCoordinates(coordinate: chennaiCoordinate)
        
        setupSearchCompleter()
    }
    
    // MARK: - Search Completer Setup
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        
        // Listen to text changes for autocomplete
        $locationSearchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.searchResults = []
                } else if query != self.lastGeocodedAddress {
                    self.searchCompleter.queryFragment = query
                }
            }
            .store(in: &cancellables)
    }
    
    private var lastGeocodedAddress: String = ""
    
    // MARK: - Handle Autocomplete Selection
    func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchQuery = result.title + " " + result.subtitle
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let self = self,
                  let coordinate = response?.mapItems.first?.placemark.coordinate,
                  error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self.selectedCoordinate = coordinate
                self.lastGeocodedAddress = searchQuery
                self.locationSearchText = searchQuery
                self.searchResults = []
            }
        }
    }
    
    // MARK: - Handle Map Tap
    func handleMapTap(coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        getAddressFromCoordinates(coordinate: coordinate)
    }
    
    // MARK: - Reverse Geocoding (Convert coordinates to address)
    private func getAddressFromCoordinates(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first else {
                if let error = error {
                }
                return
            }
            
            // Build address string from placemark components
            let addressString = [
                placemark.name,
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")
            
            DispatchQueue.main.async {
                self.lastGeocodedAddress = addressString
                self.locationSearchText = addressString
                self.searchResults = []
            }
        }
    }
    
    // MARK: - Schedule Request (Main action)
    func scheduleRequest() {
        // Validate required fields
        guard !locationSearchText.isEmpty, !houseNo.isEmpty, !buildingNo.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }
        
        // Prepare address data
        let addressData: [String: Any] = [
            "location": locationSearchText,
            "houseNo": houseNo,
            "buildingNo": buildingNo,
            "landmark": landmark,
            "latitude": selectedCoordinate.latitude,
            "longitude": selectedCoordinate.longitude
        ]
        
        isLoading = true
        
        // Route to appropriate save method based on request type
        switch requestType {
        case .caretaker:
            saveScheduleRequest(addressData: addressData)
        case .dogWalker:
            updateDogWalkerRequest(addressData: addressData)
        }
    }
    
    // MARK: - Save Caretaker Request
    // Matches UIKit: Schedule_Request -> saveScheduleRequest
    private func saveScheduleRequest(addressData: [String: Any]) {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            alertMessage = "You must be logged in."
            showAlert = true
            return
        }
        
        let userId = currentUser.uid
        
        // Fetch user name first
        fetchUserName(userId: userId) { [weak self] userName in
            guard let self = self else { return }
            
            
            let requestId = UUID().uuidString
            
            // Prepare schedule request data (matches UIKit structure exactly)
            var requestData: [String: Any] = [
                "requestId": requestId,
                "userId": userId,
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
            
            // Merge address data into request data
            for (key, value) in addressData {
                requestData[key] = value
            }
            
            // Save to Firestore using FirebaseManager
            FirebaseManager.shared.saveScheduleRequestData(data: requestData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Failed to save the schedule request."
                        self.showAlert = true
                    }
                } else {
                    
                    // Create CLLocation from selected coordinates
                    let userLocation = CLLocation(
                        latitude: self.selectedCoordinate.latitude,
                        longitude: self.selectedCoordinate.longitude
                    )
                    
                    // Auto-assign caretaker
                    FirebaseManager.shared.autoAssignCaretaker(
                        petName: self.petName,
                        requestId: requestId,
                        userLocation: userLocation
                    ) { assignError in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            if let assignError = assignError {
                            } else {
                            }
                            
                            // Navigate to success screen
                            self.shouldNavigateToSuccess = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Update Dog Walker Request
    // Matches UIKit: Add_Address -> scheduleRequestTapped (for dogwalker)
    private func updateDogWalkerRequest(addressData: [String: Any]) {
        guard let requestId = currentRequestId else {
            isLoading = false
            alertMessage = "No request ID found for updating the dogwalker request."
            showAlert = true
            return
        }
        
        let requestRef = Firestore.firestore().collection("dogWalkerRequests").document(requestId)
        
        // Check if document exists first (matches UIKit logic)
        requestRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Could not retrieve the request."
                    self.showAlert = true
                }
                return
            }
            
            if let document = document, document.exists {
                // Document exists, update it
                self.performDogWalkerUpdate(requestRef: requestRef, addressData: addressData, requestId: requestId)
            } else {
                // Document doesn't exist, create it with address data
                requestRef.setData(addressData, merge: true) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.alertMessage = "Could not create the request with address."
                            self.showAlert = true
                        }
                    } else {
                        self.afterDogwalkerUpdate(addressData: addressData, requestId: requestId)
                    }
                }
            }
        }
    }
    
    // MARK: - Perform Dog Walker Update
    private func performDogWalkerUpdate(requestRef: DocumentReference, addressData: [String: Any], requestId: String) {
        requestRef.updateData(addressData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Could not update the request with address."
                    self.showAlert = true
                }
            } else {
                self.afterDogwalkerUpdate(addressData: addressData, requestId: requestId)
            }
        }
    }
    
    // MARK: - After Dog Walker Update (Auto-assign)
    private func afterDogwalkerUpdate(addressData: [String: Any], requestId: String) {
        // Create CLLocation from address data
        let userLocation: CLLocation? = {
            if let lat = addressData["latitude"] as? Double,
               let lon = addressData["longitude"] as? Double {
                return CLLocation(latitude: lat, longitude: lon)
            }
            return nil
        }()
        
        // Auto-assign dog walker
        FirebaseManager.shared.autoAssignDogWalker(
            petName: self.petName,
            requestId: requestId,
            userLocation: userLocation
        ) { assignError in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let assignError = assignError {
                } else {
                }
                
                // Navigate to success screen
                self.shouldNavigateToSuccess = true
            }
        }
    }
    
    // MARK: - Fetch User Name
    // Matches UIKit: fetchUserName function
    private func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        let usersCollection = db.collection("users")
        
        
        usersCollection.document(userId).getDocument { document, error in
            if let error = error {
                completion("Anonymous User")
            } else if let document = document, document.exists {
                if let data = document.data(), let name = data["name"] as? String, !name.isEmpty {
                    completion(name)
                } else {
                    completion("Anonymous User")
                }
            } else {
                completion("Anonymous User")
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddAddressViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    }
}
