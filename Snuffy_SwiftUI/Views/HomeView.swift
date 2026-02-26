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
    private let petCircleFill = Color(hex: "#FFD6E6")

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        snuffyPink.opacity(0.4),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                            // MARK: - Title "Explore"
                            Text("Explore")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 20)

                            // MARK: - Search Bar (native iOS style)
                            SearchBarView(placeholder: "Which service are you looking for ?")
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)

                            // MARK: - Banner Image
                            Image("Home Screen Banner")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(25)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 25)

                            // MARK: - My Pets Section
                            Text("My Pets")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(viewModel.homePets) { pet in
                                        PetCircleCardView(
                                            pet: pet,
                                            borderColor: snuffyPink,
                                            fillColor: petCircleFill
                                        )
                                        .onTapGesture {
                                            viewModel.selectedPet = pet
                                            viewModel.shouldNavigateToPetProfile = true
                                        }
                                    }

                                    // Add Pet Button
                                    AddPetCircleView(
                                        borderColor: snuffyPink,
                                        fillColor: petCircleFill
                                    )
                                    .onTapGesture {
                                        viewModel.moveToMyPets()
                                    }
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .padding(.bottom, 25)
                            }

                            // MARK: - Our Services Section
                            Text("Our Services")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 25)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    // Pet Sitting Card
                                    HomeServiceCard(
                                        imageName: "Home1-2",
                                        buttonTitle: "Book Caretake",
                                        buttonColor: snuffyPink,
                                        action: {
                                            viewModel.navigateToPetSitting()
                                        }
                                    )

                                    // Pet Walking Card
                                    HomeServiceCard(
                                        imageName: "Home2-2",
                                        buttonTitle: "Book Caretake",
                                        buttonColor: snuffyPink,
                                        action: {
                                            viewModel.navigateToPetWalking()
                                        }
                                    )
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .padding(.bottom, 40)
                            }
                        }
                        .frame(width: geo.size.width)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.checkUserAuthentication()
                viewModel.fetchUserNameAndSetupProfile()
                viewModel.fetchPetsForHomeScreen()
            }
            // MARK: - Navigation Destinations
            .navigationDestination(isPresented: $viewModel.shouldNavigateToProfile) {
                UserProfileView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPetProfile) {
                if let pet = viewModel.selectedPet {
                    PetProfileView(petId: pet.petId)
                }
            }
            .sheet(isPresented: $viewModel.shouldNavigateToCaretakerBooking) {
                BookCaretakerView()
            }
            .sheet(isPresented: $viewModel.shouldNavigateToDogWalkerBooking) {
                BookDogWalkerView()
            }
            .fullScreenCover(isPresented: $viewModel.shouldNavigateToLogin) {
                UserLoginView()
            }
            .onChange(of: viewModel.shouldNavigateToLogin) { newValue in
                if newValue { dismiss() }
            }
            .onChange(of: viewModel.shouldNavigateToMyPets) { navigate in
                if navigate {
                    selectedTab = 2
                    viewModel.shouldNavigateToMyPets = false
                }
            }
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    let placeholder: String
    @State private var searchText: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(.gray)

            TextField(placeholder, text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .autocorrectionDisabled()

            Spacer()

            Image(systemName: "mic")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.gray.opacity(1), lineWidth: 1)
        )
    }
}

// MARK: - Pet Circle Card View
struct PetCircleCardView: View {
    let pet: PetData
    let borderColor: Color
    let fillColor: Color

    private let outerSize: CGFloat = 100
    private let innerSize: CGFloat = 88
    private let borderWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer circle – pink border
                Circle()
                    .strokeBorder(borderColor, lineWidth: borderWidth)
                    .frame(width: outerSize, height: outerSize)

                // Fill behind the image
                Circle()
                    .fill(fillColor)
                    .frame(width: outerSize - borderWidth * 2, height: outerSize - borderWidth * 2)

                // Pet image (clipped to inner circle)
                Group {
                    if let imageName = pet.petImage, !imageName.isEmpty {
                        if let url = URL(string: imageName), imageName.hasPrefix("http") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(borderColor)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    } else {
                        Image(systemName: "dog.fill")
                            .font(.system(size: 32))
                            .foregroundColor(borderColor)
                    }
                }
                .frame(width: innerSize, height: innerSize)
                .clipShape(Circle())
            }

            // Pet name label
            Text(pet.petName ?? "Pet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(1)
        }
    }
}

// MARK: - Add Pet Circle View
struct AddPetCircleView: View {
    let borderColor: Color
    let fillColor: Color

    private let outerSize: CGFloat = 100
    private let borderWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer circle – pink border
                Circle()
                    .strokeBorder(borderColor, lineWidth: borderWidth)
                    .frame(width: outerSize, height: outerSize)

                // Inner fill
                Circle()
                    .fill(fillColor)
                    .frame(width: outerSize - borderWidth * 2, height: outerSize - borderWidth * 2)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(borderColor)
            }

            Text("Add Pet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Home Service Card View
struct HomeServiceCard: View {
    let imageName: String
    let buttonTitle: String
    let buttonColor: Color
    let action: () -> Void

    private let cardWidth: CGFloat = 175
    private let cardHeight: CGFloat = 220
    private let buttonHeight: CGFloat = 42

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Service image – fills the card above the button
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight - buttonHeight)
                    .clipped()

                // Bottom button strip
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(buttonColor)
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)   // removes default press opacity on the whole card
    }
}

// MARK: - Color Hex Initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:  a = 255; r = int >> 16; g = int >> 8 & 0xFF; b = int & 0xFF
        case 8:  a = int >> 24; r = int >> 16 & 0xFF; g = int >> 8 & 0xFF; b = int & 0xFF
        default: a = 255; r = 0; g = 0; b = 0
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    HomeView(selectedTab: .constant(0))
}
