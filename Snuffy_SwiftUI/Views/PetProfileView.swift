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
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let pet = viewModel.pet {
                // Fixed Image Background
                GeometryReader { geo in
                    PetProfileImageView(imageUrl: pet.petImage)
                        .frame(width: geo.size.width, height: 400 + geo.safeAreaInsets.top)
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                }
                
                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Spacer to push the white sheet down
                        Spacer()
                            .frame(height: 340)
                        
                        // Bottom Sheet
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Name & Breed
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pet.petName ?? "Unknown")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(pet.petBreed ?? "Unknown")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 32)
                            .padding(.horizontal, 24)
                            
                            // Info Box
                            HStack(spacing: 0) {
                                InfoItem(title: "Weight", value: pet.petWeight ?? "Unknown")
                                InfoItem(title: "Gender", value: pet.petGender ?? "Unknown")
                                InfoItem(title: "Age", value: pet.petAge ?? "Unknown")
                            }
                            .padding(.vertical, 20)
                            .background(snuffyPink.opacity(0.15))
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            
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
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 24)
                            
                            Spacer()
                                .frame(height: 60)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            ZStack {
                                Color.white // To block the image showing underneath
                                LinearGradient(
                                    colors: [Color.white.opacity(0), snuffyPink.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        )
                        .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
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

struct ProfileOptionRow: View {
    let title: String
    let icon: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
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

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        PetProfileView(petId: "sample")
    }
}
