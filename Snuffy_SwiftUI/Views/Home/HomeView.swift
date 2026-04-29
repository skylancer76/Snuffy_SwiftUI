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

    private let myPetsSectionID = "MY_PETS_SECTION"

    // MARK: - Pet Bot state
    @State private var showPetBot      = false
    @State private var botDragOffset   = CGSize.zero
    @State private var botLastOffset   = CGSize.zero

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [snuffyPink.opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {

                                // MARK: - Title + Profile Icon
                                HStack(alignment: .center) {
                                    Text("Explore")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)

                                    Spacer()

                                    // Profile initials circle
                                    Button {
                                        viewModel.shouldNavigateToProfile = true
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(snuffyPink)
                                                .frame(width: 42, height: 42)
                                            Text(viewModel.userInitials)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 30)

                                // MARK: - Search Bar
                                SearchBarView(
                                    placeholder: "Which service are you looking for ?",
                                    onSearch: { query in
                                        handleSearch(query: query, proxy: proxy)
                                    }
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)

                                // MARK: - Pet search loading indicator
                                if viewModel.isSearchingPet {
                                    HStack {
                                        ProgressView()
                                            .padding(.leading, 20)
                                        Text("Searching for pet…")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    .padding(.bottom, 12)
                                }

                                if let searchError = viewModel.petSearchError {
                                    Text(searchError)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 12)
                                }

                                // MARK: - Banner
                                Image("Home Screen Banner")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(25)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 25)

                                // MARK: - Our Services Section
                                Text("Our Services")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 25)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        Button(action: { viewModel.navigateToPetSitting() }) {
                                            Image("Caretaker Banner")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 175, height: 185)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: { viewModel.navigateToPetWalking() }) {
                                            Image("Dog Walker Banner")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 175, height: 185)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.leading, 20)
                                    .padding(.trailing, 20)
                                    .padding(.bottom, 25)
                                }

                                // MARK: - My Pets Section
                                Text("My Pets")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                    .id(myPetsSectionID)

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
                                    .padding(.bottom, 40)
                                }
                            }
                            .frame(width: geo.size.width)
                        }
                        .onChange(of: viewModel.shouldScrollToMyPets) { _, newValue in
                            if newValue {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(myPetsSectionID, anchor: .top)
                                }
                                viewModel.shouldScrollToMyPets = false
                            }
                        }
                    }
                }
                // MARK: - Floating Pet Bot Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        petBotButton
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100)
                .allowsHitTesting(true)
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
            .sheet(isPresented: $showPetBot) {
                PetBotView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .fullScreenCover(isPresented: $viewModel.shouldNavigateToLogin) {
                UserLoginView()
            }
            .onChange(of: viewModel.shouldNavigateToLogin) { _, newValue in
                if newValue { dismiss() }
            }
            .onChange(of: viewModel.shouldNavigateToMyPets) { _, navigate in
                if navigate {
                    selectedTab = 2
                    viewModel.shouldNavigateToMyPets = false
                }
            }

        }
    }

    // MARK: - Floating Pet Bot Button

    private var petBotButton: some View {
        Button { showPetBot = true } label: {
            ZStack {
                Circle()
                    .fill(snuffyPink)
                    .frame(width: 56, height: 56)
                    .shadow(color: snuffyPink.opacity(0.45), radius: 10, x: 0, y: 5)

                HStack(spacing: -4) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(-20))
                        .offset(y: 3)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(10))
                }
            }
        }
        .buttonStyle(.plain)
        .offset(botDragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    botDragOffset = CGSize(
                        width:  botLastOffset.width  + value.translation.width,
                        height: botLastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    botLastOffset = botDragOffset
                }
        )
    }

    // MARK: - Search Handler
    private func handleSearch(query: String, proxy: ScrollViewProxy) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let lower = trimmed.lowercased()

        // 1. Dog walking
        let walkingKeywords = ["dog walking", "dog walker", "walking", "walker", "walk"]
        if walkingKeywords.contains(where: { lower.contains($0) }) {
            viewModel.navigateToPetWalking()
            return
        }

        // 2. Caretaker / pet sitting
        let caretakerKeywords = ["caretaker", "caretake", "pet sitting", "sitting", "pet sit", "sitter"]
        if caretakerKeywords.contains(where: { lower.contains($0) }) {
            viewModel.navigateToPetSitting()
            return
        }

        // 3. "pets" / "my pets" → scroll to section
        let petsKeywords = ["my pets", "pets", "pet"]
        if petsKeywords.contains(where: { lower == $0 }) {
            viewModel.shouldScrollToMyPets = true
            return
        }

        // 4. Specific pet name → search Firestore
        viewModel.searchPetByName(trimmed)
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    let placeholder: String
    var onSearch: ((String) -> Void)? = nil

    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    
    private let iconColor = Color.black.opacity(0.5)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)

            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(iconColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                TextField("", text: $searchText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSearch?(searchText)
                        isFocused = false
                    }
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    onSearch?("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(Color.black.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Pet Circle Card View
struct PetCircleCardView: View {
    let pet: PetData
    let borderColor: Color
    let fillColor: Color

    private let imageSize: CGFloat = 110

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: imageSize, height: imageSize)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)

                Group {
                    if let imageName = pet.petImage, !imageName.isEmpty {
                        if let url = URL(string: imageName), imageName.hasPrefix("http") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:      ProgressView()
                                case .success(let image): image.resizable().scaledToFill()
                                case .failure:
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(borderColor)
                                @unknown default: EmptyView()
                                }
                            }
                        } else {
                            Image(imageName).resizable().scaledToFill()
                        }
                    } else {
                        Image(systemName: "dog.fill")
                            .font(.system(size: 32))
                            .foregroundColor(borderColor)
                    }
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
            }

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

    private let imageSize: CGFloat = 110

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: imageSize, height: imageSize)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(borderColor)
            }

            Text("Add Pet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
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
