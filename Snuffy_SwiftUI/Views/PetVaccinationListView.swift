//
//  PetVaccinationListView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct PetVaccinationListView: View {
    let petId: String
    @StateObject private var viewModel: PetVaccinationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetVaccinationViewModel(petId: petId))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.1), Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.vaccinations.isEmpty {
                ProgressView()
                    .tint(snuffyPink)
            } else if viewModel.vaccinations.isEmpty {
                VStack {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(snuffyPink)
                                .frame(width: 44, height: 44)
                            Image(systemName: "syringe.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text("No vaccination found")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.vaccinations, id: \.vaccineId) { vaccination in
                            VaccinationRow(vaccination: vaccination)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Vaccination Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shouldShowAddVaccine = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(snuffyPink)
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowAddVaccine) {
            AddPetVaccinationView(petId: petId)
        }
    }
}

struct VaccinationRow: View {
    let vaccination: VaccinationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "syringe.fill")
                    .foregroundColor(snuffyPink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vaccination.vaccineName)
                    .font(.headline)
                Text("Given on \(vaccination.dateOfVaccination)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if vaccination.expires, let expiry = vaccination.expiryDate {
                    Text("Expires on \(expiry)")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        PetVaccinationListView(petId: "sample")
    }
}
