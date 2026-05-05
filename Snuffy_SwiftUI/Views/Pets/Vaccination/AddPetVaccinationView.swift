//
//  AddPetVaccinationView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
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
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Vaccination Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vaccination Details")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
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
                            .background(Color.white)
                        }
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Expiry Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expiry Details")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Expires")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                Toggle("", isOn: $viewModel.expires)
                                    .labelsHidden()
                                    .tint(snuffyPink)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.white)
                            
                            if viewModel.expires {
                                Divider().padding(.leading, 16)
                                
                                HStack {
                                    Text("Expiry Date")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    DatePicker("", selection: $viewModel.expiryDate, in: Date()..., displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(snuffyPink)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                                .background(Color.white)
                                
                                Divider().padding(.leading, 16)
                                
                                HStack {
                                    Text("Notify upon expiry")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Toggle("", isOn: $viewModel.notifyUponExpiry)
                                        .labelsHidden()
                                        .tint(snuffyPink)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                                .background(Color.white)
                            }
                        }
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        TextEditor(text: $viewModel.notes)
                            .padding(8)
                            .frame(height: 120)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    // Add Vaccine Button
                    Button(action: {
                        viewModel.saveVaccination()
                    }) {
                        Text("Add Vaccine")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
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
        .navigationTitle("Add Vaccine")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
