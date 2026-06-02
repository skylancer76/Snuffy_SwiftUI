import SwiftUI
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    // MARK: - Published State

    @Published var authorizationStatus: CLAuthorizationStatus

    // MARK: - Private

    private let clManager = CLLocationManager()
    private var locationCompletion: ((Double, Double) -> Void)?

    private override init() {
        authorizationStatus = clManager.authorizationStatus
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Permission

    func requestLocationPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    // MARK: - Location for Onboarding

    func getLocationForOnboarding(address: String, completion: @escaping (Double, Double) -> Void) {
        let status = clManager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationCompletion = { [weak self] lat, lng in
                self?.locationCompletion = nil
                self?.clManager.stopUpdatingLocation()
                completion(lat, lng)
            }
            clManager.startUpdatingLocation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                guard let self = self, self.locationCompletion != nil else { return }
                self.locationCompletion = nil
                self.clManager.stopUpdatingLocation()
                self.geocodeAddress(address, completion: completion)
            }
        } else {
            geocodeAddress(address, completion: completion)
        }
    }

    // MARK: - Geocoding

    private func geocodeAddress(_ address: String, completion: @escaping (Double, Double) -> Void) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(0.0, 0.0)
            return
        }

        CLGeocoder().geocodeAddressString(trimmed) { placemarks, error in
            if let location = placemarks?.first?.location {
                completion(location.coordinate.latitude, location.coordinate.longitude)
            } else {
                completion(0.0, 0.0)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationCompletion?(location.coordinate.latitude, location.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
        }
    }
}
