//
//  HomeView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        snuffyPink.opacity(0.3),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Our Services Section (only visible when at top)
                        if !viewModel.homePets.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Our Services")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                
                                // Pet Sitting Card
                                ServiceCardView(
                                    title: "Pet Sitting",
                                    imageName: "Frame 1",
                                    backgroundColor: snuffyPink,
                                    iconName: "house.fill",
                                    action: {
                                        viewModel.navigateToPetSitting()
                                    }
                                )
                                .padding(.horizontal, 16)
                                
                                // Pet Walking Card
                                ServiceCardView(
                                    title: "Pet Walking",
                                    imageName: "Frame 2",
                                    backgroundColor: Color.yellow,
                                    iconName: "pawprint.fill",
                                    action: {
                                        viewModel.navigateToPetWalking()
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        } else {
                            // Show only collapsed service cards when scrolled or no pets
                            VStack(spacing: 16) {
                                // Pet Sitting Card (Collapsed)
                                ServiceCardCollapsedView(
                                    title: "Pet Sitting",
                                    iconName: "house.fill",
                                    action: {
                                        viewModel.navigateToPetSitting()
                                    }
                                )
                                .padding(.horizontal, 16)
                                
                                // Pet Walking Card (Collapsed)
                                ServiceCardCollapsedView(
                                    title: "Pet Walking",
                                    iconName: "pawprint.fill",
                                    action: {
                                        viewModel.navigateToPetWalking()
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                        }
                        
                        // My Pets Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Pets")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    // Display pets
                                    ForEach(viewModel.homePets) { pet in
                                        PetCardView(pet: pet)
                                            .onTapGesture {
                                                viewModel.selectedPet = pet
                                                viewModel.shouldNavigateToPetProfile = true
                                            }
                                    }
                                    
                                    // Add Pet Card
                                    AddPetCardView()
                                        .onTapGesture {
                                            viewModel.moveToMyPets()
                                        }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.shouldNavigateToProfile = true
                    }) {
                        ProfileIconView(initials: viewModel.userInitials)
                    }
                }
            }
            .onAppear {
                viewModel.checkUserAuthentication()
                viewModel.fetchUserNameAndSetupProfile()
                viewModel.fetchPetsForHomeScreen()
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToProfile) {
                // Replace with your Profile View
                Text("User Profile Screen")
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPetProfile) {
                // Replace with your Pet Profile View
                if let pet = viewModel.selectedPet {
                    Text("Pet Profile: \(pet.petName ?? "Unknown")")
                }
            }
            .fullScreenCover(isPresented: $viewModel.shouldNavigateToLogin) {
                UserLoginView()
            }
        }
    }
}

// MARK: - Service Card View (Full)
struct ServiceCardView: View {
    let title: String
    let imageName: String
    let backgroundColor: Color
    let iconName: String
    let action: () -> Void
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section with Description
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // Bottom Section with Title and Button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(snuffyPink)
                    
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(snuffyPink)
                }
                
                Spacer()
                
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text("Book Now")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(snuffyPink)
                    .cornerRadius(20)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Service Card View (Collapsed - when scrolled)
struct ServiceCardCollapsedView: View {
    let title: String
    let iconName: String
    let action: () -> Void
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(snuffyPink)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(snuffyPink)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("Book Now")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(snuffyPink)
                .cornerRadius(20)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Pet Card View
struct PetCardView: View {
    let pet: PetData
    @State private var petImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pet Image
            if let image = petImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 160)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Image("DogPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 160)
                    .clipped()
                    .cornerRadius(12)
                    .onAppear {
                        loadPetImage()
                    }
            }
            
            // Pet Name
            Text(pet.petName ?? "Unknown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
        }
        .frame(width: 150, height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
    }
    
    private func loadPetImage() {
        guard let imageUrlString = pet.petImage,
              let url = URL(string: imageUrlString) else {
            petImage = UIImage(named: "DogPlaceholder")
            return
        }
        
        let fileName = url.lastPathComponent
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localURL = cachesDirectory.appendingPathComponent(fileName)
        
        // Check if the file exists locally
        if FileManager.default.fileExists(atPath: localURL.path),
           let image = UIImage(contentsOfFile: localURL.path) {
            petImage = image
        } else {
            // Download the image using your existing ImageDownloader
            ImageDownloader.shared.downloadImage(from: url) { downloadedLocalURL in
                if let downloadedLocalURL = downloadedLocalURL,
                   let image = UIImage(contentsOfFile: downloadedLocalURL.path) {
                    DispatchQueue.main.async {
                        petImage = image
                    }
                } else {
                    DispatchQueue.main.async {
                        petImage = UIImage(named: "DogPlaceholder")
                    }
                }
            }
        }
    }
}

// MARK: - Add Pet Card View
struct AddPetCardView: View {
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 50, weight: .thin))
                .foregroundColor(snuffyPink)
        }
        .frame(width: 150, height: 200)
        .background(snuffyPink.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Profile Icon View
struct ProfileIconView: View {
    let initials: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray)
                .frame(width: 40, height: 40)
            
            Text(initials)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HomeView()
}
