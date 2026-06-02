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
                colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let pet = viewModel.pet {
                VStack(spacing: 0) {
                    
                    // Custom Navigation Bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            
                            // Pet Image Area
                            PetProfileImageView(imageUrl: pet.petImage)
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                            
                            // Bottom White Sheet
                            VStack(spacing: 24) {
                                
                                // Name & Breed
                                VStack(spacing: 4) {
                                    Text(pet.petName ?? "Unknown")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text(pet.petBreed ?? "Unknown")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 32)
                                
                                // Info Box (Three Cards)
                                HStack(spacing: 12) {
                                    AttributeCard(title: "Age", value: pet.petAge ?? "Unknown")
                                    AttributeCard(title: "Weight", value: pet.petWeight ?? "Unknown")
                                    AttributeCard(title: "Sex", value: pet.petGender ?? "Unknown")
                                }
                                .padding(.horizontal, 24)
                                
                                // Records Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Records")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 24)
                                    
                                    VStack(spacing: 16) {
                                        NavigationLink(destination: PetVaccinationListView(petId: petId)) {
                                            RecordRow(
                                                icon: "syringe.fill",
                                                color: Color.orange,
                                                title: "Vaccination",
                                                subtitle: "Vaccination history"
                                            )
                                        }
                                        NavigationLink(destination: PetDietListView(petId: petId)) {
                                            RecordRow(
                                                icon: "fork.knife",
                                                color: Color.purple,
                                                title: "Diet",
                                                subtitle: "Meal plan & schedules"
                                            )
                                        }
                                        NavigationLink(destination: PetMedicationListView(petId: petId)) {
                                            RecordRow(
                                                icon: "pills.fill",
                                                color: Color.blue,
                                                title: "Medication",
                                                subtitle: "Current medications"
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding(.top, 16)
                                
                                Spacer().frame(height: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
                        }
                    }
                }
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

struct AttributeCard: View {
    let title: String
    let value: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(snuffyPink.opacity(0.1))
        .cornerRadius(16)
    }
}

struct RecordRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        PetProfileView(petId: "sample")
    }
}
