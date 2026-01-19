//
//  AddAddressView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct AddAddressView: View {
    @StateObject private var viewModel: AddAddressViewModel
    @Environment(\.dismiss) var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(requestType: RequestType,
         petName: String,
         startDate: Date,
         endDate: Date,
         startTime: Date? = nil,
         endTime: Date? = nil,
         instructions: String,
         isPetPickup: Bool = false,
         isPetDropoff: Bool = false,
         currentRequestId: String? = nil) {
        
        _viewModel = StateObject(wrappedValue: AddAddressViewModel(
            requestType: requestType,
            petName: petName,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            instructions: instructions,
            isPetPickup: isPetPickup,
            isPetDropoff: isPetDropoff,
            currentRequestId: currentRequestId
        ))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Map Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select your location")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        MapView(
                            coordinate: $viewModel.selectedCoordinate,
                            onTap: { coordinate in
                                viewModel.handleMapTap(coordinate: coordinate)
                            }
                        )
                        .frame(height: 250)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        
                        // Location TextField (read-only, shows reverse geocoded address)
                        TextField("", text: $viewModel.locationSearchText)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .disabled(true)
                    }
                    
                    // Address Details Section
                    VStack(spacing: 16) {
                        TextField("House No.& Floor *", text: $viewModel.houseNo)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        
                        TextField("Building and Block No.*", text: $viewModel.buildingNo)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        
                        TextField("Landmark and Area (Optional)", text: $viewModel.landmark)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                    }
                    
                    // Schedule Request Button
                    Button(action: {
                        viewModel.scheduleRequest()
                    }) {
                        Text("Schedule Request")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(snuffyPink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical, 24)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
            }
        }
        .navigationTitle("Add Address")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setDefaultLocation()
        }
        .navigationDestination(isPresented: $viewModel.shouldNavigateToSuccess) {
            RequestScheduledView()
                .navigationBarBackButtonHidden(true)
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// MARK: - MapView UIViewRepresentable
struct MapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    var onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.mapTapped(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove all existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add new annotation at selected coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Center map on coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.onTap(coordinate)
        }
    }
}

#Preview {
    NavigationStack {
        AddAddressView(
            requestType: .caretaker,
            petName: "Buddy",
            startDate: Date(),
            endDate: Date(),
            instructions: "Take good care",
            isPetPickup: true,
            isPetDropoff: true
        )
    }
}
