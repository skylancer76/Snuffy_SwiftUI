//
//  AddPetVaccinationView.swift
//  Snuffy_SwiftUI
//

import SwiftUI

struct AddPetVaccinationView: View {
    let petId: String
    @StateObject private var viewModel: AddPetVaccinationViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: AddPetVaccinationViewModel(petId: petId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(snuffyPink)
                
                Spacer()
                
                Text("Add Vaccine")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveVaccination()
                }
                .foregroundColor(snuffyPink)
                .bold()
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Vaccination Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VACCINATION DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
                        VStack(spacing: 0) {
                            Menu {
                                ForEach(viewModel.vaccineOptions, id: \.self) { type in
                                    Button(type) {
                                        viewModel.vaccineName = type
                                    }
                                }
                            } label: {
                                SelectionRow(label: "Vaccine Name", value: viewModel.vaccineName.isEmpty ? "Select" : viewModel.vaccineName)
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            HStack {
                                Text("Date of Vaccination")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $viewModel.dateOfVaccination, displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(snuffyPink)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 20)
                    
                    // Expiry Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXPIRY DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Expires")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                Toggle("", isOn: $viewModel.expires)
                                    .labelsHidden()
                                    .tint(.green)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            
                            if viewModel.expires {
                                Divider().padding(.leading, 16)
                                
                                HStack {
                                    Text("Expiry Date")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    DatePicker("", selection: $viewModel.expiryDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(snuffyPink)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                                
                                Divider().padding(.leading, 16)
                                
                                HStack {
                                    Text("Notify upon expiry")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Toggle("", isOn: $viewModel.notifyUponExpiry)
                                        .labelsHidden()
                                        .tint(.green)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTES (OPTIONAL)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
                        TextEditor(text: $viewModel.notes)
                            .padding(12)
                            .frame(height: 120)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                dismiss()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
