import SwiftUI
import MapKit
import CoreLocation

struct TrackPetMapView: View {
    let walkerLatitude: Double
    let walkerLongitude: Double
    let walkerName: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            TrackMapRepresentable(
                walkerLatitude: walkerLatitude,
                walkerLongitude: walkerLongitude,
                walkerName: walkerName
            )
            .ignoresSafeArea()

            // Floating nav bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                }
                Spacer()
                Text("Track Your Pet")
                    .font(.system(size: 17, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - UIViewRepresentable

struct TrackMapRepresentable: UIViewRepresentable {
    let walkerLatitude: Double
    let walkerLongitude: Double
    let walkerName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(walkerLatitude: walkerLatitude, walkerLongitude: walkerLongitude)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        context.coordinator.mapView = mapView

        let coord = CLLocationCoordinate2D(latitude: walkerLatitude, longitude: walkerLongitude)

        let pin = MKPointAnnotation()
        pin.coordinate = coord
        pin.title = walkerName
        pin.subtitle = "Current Location"
        mapView.addAnnotation(pin)

        mapView.setRegion(
            MKCoordinateRegion(center: coord, latitudinalMeters: 1000, longitudinalMeters: 1000),
            animated: false
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            mapView.setRegion(
                MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500),
                animated: true
            )
        }

        context.coordinator.startLocating()
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        let locationManager = CLLocationManager()
        let walkerLatitude: Double
        let walkerLongitude: Double
        var routeDrawn = false
        weak var mapView: MKMapView?

        init(walkerLatitude: Double, walkerLongitude: Double) {
            self.walkerLatitude = walkerLatitude
            self.walkerLongitude = walkerLongitude
            super.init()
            locationManager.delegate = self
        }

        func startLocating() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard !routeDrawn, let userLoc = locations.last else { return }
            routeDrawn = true
            locationManager.stopUpdatingLocation()
            let dest = CLLocationCoordinate2D(latitude: walkerLatitude, longitude: walkerLongitude)
            drawRoute(from: userLoc.coordinate, to: dest)
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        }

        private func drawRoute(from source: CLLocationCoordinate2D, to dest: CLLocationCoordinate2D) {
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
            req.transportType = .walking

            MKDirections(request: req).calculate { [weak self] response, _ in
                guard let self, let route = response?.routes.first else { return }
                DispatchQueue.main.async {
                    self.mapView?.addOverlay(route.polyline)
                    self.mapView?.setVisibleMapRect(
                        route.polyline.boundingMapRect,
                        edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 60, right: 40),
                        animated: true
                    )
                }
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 0.85)
            r.lineWidth = 4
            return r
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let pin = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "walkerPin")
            pin.markerTintColor = UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1)
            pin.glyphImage = UIImage(systemName: "figure.walk")
            pin.canShowCallout = true
            return pin
        }
    }
}
