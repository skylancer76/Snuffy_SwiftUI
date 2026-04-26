//
//  PetProfileView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
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
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let pet = viewModel.pet {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Spacer for custom nav bar
                        Spacer().frame(height: 60)
                        
                        // Pet Image
                        PetProfileImageView(imageUrl: pet.petImage)
                            .frame(width: 280, height: 280)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.35), radius: 25, x: 0, y: 15)
                        
                        // Name & Breed
                        VStack(spacing: 8) {
                            Text(pet.petName ?? "Unknown")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(pet.petBreed ?? "Unknown")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        
                        // Info Box (Glassmorphic)
                        HStack(spacing: 0) {
                            InfoItem(title: "Weight", value: pet.petWeight ?? "Unknown")
                            InfoItem(title: "Gender", value: pet.petGender ?? "Unknown")
                            InfoItem(title: "Age", value: pet.petAge ?? "Unknown")
                        }
                        .padding(.vertical, 24)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(snuffyPink.opacity(0.25))
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                            }
                            .shadow(color: snuffyPink.opacity(0.3), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal, 24)
                        
                        // Three Action Circles
                        HStack {
                            NavigationLink(destination: PetVaccinationListView(petId: petId)) {
                                CircleActionItem(title: "Vaccination", icon: "syringe.fill")
                            }
                            Spacer()
                            NavigationLink(destination: PetDietListView(petId: petId)) {
                                CircleActionItem(title: "Diet", icon: "fork.knife")
                            }
                            Spacer()
                            NavigationLink(destination: PetMedicationListView(petId: petId)) {
                                CircleActionItem(title: "Medication", icon: "pills.fill")
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                        
                        Spacer().frame(height: 40)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Custom Navigation Bar Overlay
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive) {
                            viewModel.shouldShowDeleteAlert = true
                        } label: {
                            Label("Delete Pet", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(snuffyPink)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
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
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
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

struct CircleActionItem: View {
    let title: String
    let icon: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.25))
                    .clipShape(Circle())
                    .frame(width: 80, height: 80)
                    .shadow(color: snuffyPink.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(snuffyPink)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
        }
    }
}

#Preview {
    NavigationStack {
        PetProfileView(petId: "sample")
    }
}
