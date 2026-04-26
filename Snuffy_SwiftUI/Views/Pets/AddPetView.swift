//
//  AddPetView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI

struct AddPetView: View {
    @StateObject private var viewModel = AddPetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Upload Section
                        VStack(spacing: 12) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                if let image = viewModel.selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                } else {
                                    Image(systemName: "camera.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4))
                                }
                            }
                        }
                        .padding(.top, 24)
                        
                        // Pet Details Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pet Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                FormRow(label: "Name", value: $viewModel.petName, placeholder: "Value")
                                Divider().padding(.leading, 16)
                                
                                Menu {
                                    ForEach(viewModel.breeds, id: \.self) { breed in
                                        Button(breed) {
                                            viewModel.petBreed = breed
                                        }
                                    }
                                } label: {
                                    SelectionRow(label: "Breed", value: viewModel.petBreed.isEmpty ? "Select" : viewModel.petBreed)
                                }
                                Divider().padding(.leading, 16)
                                
                                Menu {
                                    ForEach(viewModel.ages, id: \.self) { age in
                                        Button(age) {
                                            viewModel.petAge = age
                                        }
                                    }
                                } label: {
                                    SelectionRow(label: "Age", value: viewModel.petAge.isEmpty ? "Select" : viewModel.petAge)
                                }
                                
                                Divider().padding(.leading, 16)
                                
                                Menu {
                                    ForEach(viewModel.genders, id: \.self) { gender in
                                        Button(gender) {
                                            viewModel.petGender = gender
                                        }
                                    }
                                } label: {
                                    SelectionRow(label: "Gender", value: viewModel.petGender)
                                }
                                Divider().padding(.leading, 16)
                                
                                FormRow(label: "Weight", value: $viewModel.petWeight, placeholder: "Value")
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Add Pet Button
                        Button(action: {
                            viewModel.savePet()
                        }) {
                            Text("Add Pet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(snuffyPink)
                                .cornerRadius(30)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .disabled(viewModel.isLoading)
                    }
                }
                
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
                }
            }
            .navigationTitle("Add New Pet")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage)
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
}

struct FormRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $value)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16))
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
    }
}

struct SelectionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    AddPetView()
}
