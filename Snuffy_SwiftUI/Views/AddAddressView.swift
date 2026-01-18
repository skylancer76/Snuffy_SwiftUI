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
                        
                        ZStack {
                            MapView(
                                coordinate: $viewModel.selectedCoordinate,
                                onTap: { coordinate in
                                    viewModel.handleMapTap(coordinate: coordinate)
                                }
                            )
                            .frame(height: 250)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // Location TextField with Autocomplete
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Search location", text: $viewModel.locationSearchText)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                                .onChange(of: viewModel.locationSearchText) { newValue in
                                    viewModel.searchLocation(query: newValue)
                                }
                            
                            // Autocomplete Results
                            if !viewModel.searchResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.searchResults, id: \.self) { result in
                                        Button(action: {
                                            viewModel.selectSearchResult(result)
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(snuffyPink)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.black)
                                                    
                                                    Text(result.subtitle)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                        }
                                        
                                        if result != viewModel.searchResults.last {
                                            Divider()
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }
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
        .navigationBarBackButtonHidden(false)
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
