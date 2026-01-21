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
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [snuffyPink.opacity(0.4), Color.white, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Custom Header
                        HStack {
                            Text("Explore")
                                .font(.system(size: 42, weight: .bold))
                            Spacer()
                            Button(action: {
                                viewModel.shouldNavigateToProfile = true
                            }) {
                                ProfileIconView(initials: viewModel.userInitials)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        
                        // Our Services Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Our Services")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                            
                            // Pet Sitting Card
                            ServiceCardView(
                                title: "Pet Sitting",
                                description: "Reliable caretaker to keep your pet happy and safe while you are away.",
                                imageName: "Home1-2",
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
                                description: "Experienced walkers to keep your pup active, healthy and happy!",
                                imageName: "Home2-2",
                                backgroundColor: Color.yellow,
                                iconName: "pawprint.fill",
                                action: {
                                    viewModel.navigateToPetWalking()
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // My Pets Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Pets")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.homePets) { pet in
                                        PetCardView(pet: pet)
                                            .onTapGesture {
                                                viewModel.selectedPet = pet
                                                viewModel.shouldNavigateToPetProfile = true
                                            }
                                    }
                                    
                                    AddPetCardView()
                                        .onTapGesture {
                                            viewModel.moveToMyPets()
                                        }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Space for floating tab bar
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.checkUserAuthentication()
                viewModel.fetchUserNameAndSetupProfile()
                viewModel.fetchPetsForHomeScreen()
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToProfile) {
                UserProfileView(viewModel: viewModel)
            }
            .onChange(of: viewModel.shouldNavigateToLogin) { newValue in
                if newValue {
                    dismiss()
                }
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPetProfile) {
                if let pet = viewModel.selectedPet {
                    PetProfileView(petId: pet.petId)
                }
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToCaretakerBooking) {
                BookCaretakerView()
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToDogWalkerBooking) {
                BookDogWalkerView()
            }
            .fullScreenCover(isPresented: $viewModel.shouldNavigateToLogin) {
                UserLoginView()
            }
            .onChange(of: viewModel.shouldNavigateToMyPets) { navigate in
                if navigate {
                    selectedTab = 2 // My Pets is now tab 2
                    viewModel.shouldNavigateToMyPets = false
                }
            }
        }
    }
}

// MARK: - Service Card View
struct ServiceCardView: View {
    let title: String
    let description: String
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
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // Bottom Section with Title and Button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(snuffyPink)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(snuffyPink)
                }
                
                Spacer()
                
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Book Now")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(snuffyPink)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

// PetCardView moved to its own file

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
    HomeView(selectedTab: .constant(0))
}
