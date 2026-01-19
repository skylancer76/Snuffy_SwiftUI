//
//  PetMedicationListView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct PetMedicationListView: View {
    let petId: String
    @StateObject private var viewModel: PetMedicationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetMedicationViewModel(petId: petId))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.1), Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.medications.isEmpty {
                ProgressView()
                    .tint(snuffyPink)
            } else if viewModel.medications.isEmpty {
                VStack {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(snuffyPink)
                                .frame(width: 44, height: 44)
                            Image(systemName: "pills.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text("No medication found")
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
                        ForEach(viewModel.medications, id: \.medicationId) { medication in
                            MedicationRow(medication: medication)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Medication Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shouldShowAddMedication = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(snuffyPink)
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowAddMedication) {
            AddPetMedicationView(petId: petId)
        }
    }
}

struct MedicationRow: View {
    let medication: PetMedicationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "pills.fill")
                    .foregroundColor(snuffyPink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicineName)
                    .font(.headline)
                
                Text(medication.purpose)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("\(medication.dosage) (\(medication.frequency))")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(snuffyPink.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(snuffyPink)
                    
                    Spacer()
                    
                    Text("\(medication.startDate) - \(medication.endDate)")
                        .font(.caption)
                        .foregroundColor(.gray)
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
        PetMedicationListView(petId: "sample")
    }
}
