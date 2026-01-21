//
//  PetProfileView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct PetProfileView: View {
    let petId: String
    @StateObject private var viewModel: PetProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetProfileViewModel(petId: petId))
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [snuffyPink.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let pet = viewModel.pet {
                ScrollView {
                    VStack(spacing: 32) {
                        // Pet Image Section
                        VStack(spacing: 20) {
                            PetProfileImageView(imageUrl: pet.petImage)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 8) {
                            Text(pet.petName ?? "Unknown")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(pet.petBreed ?? "Unknown")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        
                        // Pet Info Container
                        HStack(spacing: 0) {
                            InfoItem(title: "Weight", value: pet.petWeight ?? "Unknown")
                            InfoItem(title: "Age", value: pet.petAge ?? "Unknown")
                            InfoItem(title: "Gender", value: pet.petGender ?? "Unknown")
                        }
                        .padding(.vertical, 16)
                        .background(snuffyPink.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        
                        VStack(alignment: .leading) {
                            Text("Pet Details")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Options List
                        VStack(spacing: 0) {
                            NavigationLink(destination: PetVaccinationListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Vaccinations", icon: "syringe.fill")
                            }
                            Divider().padding(.leading, 72)
                            
                            NavigationLink(destination: PetDietListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Diet", icon: "fork.knife")
                            }
                            Divider().padding(.leading, 72)
                            
                            NavigationLink(destination: PetMedicationListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Medications", icon: "pills.fill")
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Pet Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.shouldShowDeleteAlert = true
                    } label: {
                        Label("Delete Pet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(snuffyPink)
                        .font(.system(size: 20))
                }
            }
        }
        .alert("Delete Pet", isPresented: $viewModel.shouldShowDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deletePet()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this pet? This action cannot be undone.")
        }
        .onChange(of: viewModel.isDeleted) { deleted in
            if deleted {
                dismiss()
            }
        }
    }
}

struct PetProfileImageView: View {
    let imageUrl: String?
    @State private var uiImage: UIImage?
    private let snuffyPink = Color(uiColor: .systemPink)
    
    var body: some View {
        ZStack {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("DogPlaceholder")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(Circle())
        .onAppear {
            loadPetImage()
        }
    }
    
    private func loadPetImage() {
        guard let imageUrlString = imageUrl, let url = URL(string: imageUrlString) else { return }
        
        let fileName = url.lastPathComponent
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localURL = cachesDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path),
           let image = UIImage(contentsOfFile: localURL.path) {
            uiImage = image
        } else {
            ImageDownloader.shared.downloadImage(from: url) { localURL in
                if let localURL = localURL, let image = UIImage(contentsOfFile: localURL.path) {
                    DispatchQueue.main.async {
                        self.uiImage = image
                    }
                }
            }
        }
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileOptionRow: View {
    let title: String
    let icon: String
    private let snuffyPink = Color(uiColor: .systemPink)
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        PetProfileView(petId: "sample")
    }
}
