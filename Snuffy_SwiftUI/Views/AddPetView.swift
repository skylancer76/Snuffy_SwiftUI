//
//  AddPetView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct AddPetView: View {
    @StateObject private var viewModel = AddPetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(snuffyPink)
                
                Spacer()
                
                Text("Add New Pet")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button("Add") {
                    viewModel.savePet()
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
                    // Image Upload Section
                    VStack(spacing: 12) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let image = viewModel.selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(snuffyPink.opacity(0.2), lineWidth: 4))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(snuffyPink)
                                    
                                    Text("Upload your pet's pic")
                                        .font(.system(size: 16))
                                        .foregroundColor(snuffyPink)
                                }
                                .frame(width: 120, height: 120)
                                .background(snuffyPink.opacity(0.05))
                                .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top, 40)
                    
                    // Pet Details Form
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ENTER PET DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
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
                            
                            HStack {
                                Text("Age")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                Picker("Age", selection: $viewModel.petAge) {
                                    ForEach(viewModel.ages, id: \.self) { age in
                                        Text(age).tag(age)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            
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
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 16)
                }
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
        .padding(.horizontal, 16)
        .frame(height: 54)
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
                .foregroundColor(.gray.opacity(0.7))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
    }
}

#Preview {
    AddPetView()
}
