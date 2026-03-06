//
//  CaretakerProfileView.swift
//  Snuffy_SwiftUI
//
//  Matches the design from snuffy-main's Caretaker Profile.swift
//  Screenshot: circular image → bold name → gray address →
//              horizontal stat card (Rating | Distance | Pets Sitted) →
//              About the Caretaker section → Gallery grid
//

import SwiftUI
import Kingfisher

struct CaretakerProfileView: View {

    let caretakerId: String

    @StateObject private var viewModel = CaretakerProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var isShareSheetPresented = false
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let columns = [GridItem(.flexible(), spacing: 8),
                           GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
                    .frame(maxHeight: .infinity)
            } else if let ct = viewModel.caretaker {
                // Fixed Image Background
                GeometryReader { geo in
                    profileImageView()
                        .frame(width: geo.size.width, height: 400 + geo.safeAreaInsets.top)
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                }
                
                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 340)
                        
                        // Bottom Sheet
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Name & Breed/Location
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(ct.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    // small rating badge inline with name
                                    if let rating = ct.rating {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12, weight: .medium))
                                            Text(String(rating))
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow)
                                        .cornerRadius(7)
                                    }
                                }
                                
                                Text(ct.address.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 32)
                            .padding(.horizontal, 20)
                            
                            // Horizontal stat card
                            statCard(ct)
                                .padding(.horizontal, 20)
                            
                            // About Caretaker
                            if !ct.bio.isEmpty {
                                aboutSection(title: "About Caretaker", bio: ct.bio)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Gallery
                            if !viewModel.resolvedGalleryURLs.isEmpty {
                                gallerySection(viewModel.resolvedGalleryURLs)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 50)
                            }
                            
                            Spacer()
                                .frame(height: 60)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            ZStack {
                                Color.white
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
                    
                    Button(action: {
                        isShareSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
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
                
            } else if let err = viewModel.errorMessage {
                errorView(err)
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.load(caretakerId: caretakerId) }
        .sheet(isPresented: $isShareSheetPresented) {
            if let ct = viewModel.caretaker {
                ShareSheet(items: ["Check out \(ct.name)'s profile for pet sitting on Snuffy!"])
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
            .scaleEffect(1.4)
            .frame(maxWidth: .infinity)
            .padding(.top, 120)
    }

    // MARK: - Error
    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 15))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 120)
    }

    // (Old profile content functions removed manually, logic is directly in the body ViewBuilder now)

    // MARK: - Profile Image
    private func profileImageView() -> some View {
        Group {
            if let url = viewModel.resolvedProfilePicURL {
                KFImage(url)
                    .placeholder {
                        Color(UIColor.systemGray5)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                Color(UIColor.systemGray5)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    // MARK: - Horizontal Stat Card
    private func statCard(_ ct: Caretakers) -> some View {
        HStack(spacing: 0) {
            // Distance
            let rawDistance = viewModel.distanceText.replacingOccurrences(of: " away", with: "")
            statItem(
                value: rawDistance == "Distance unavailable" ? "N/A" : rawDistance,
                label: "Distance"
            )

            // Experience (Mocked for now as we don't have this field yet)
            statItem(
                value: "4+",
                label: "Years of Experience"
            )

            // Pets Sitted
            statItem(
                value: "\(ct.completedRequests)+",
                label: "Pets Sitted"
            )
        }
        .padding(.vertical, 20)
        .background(snuffyPink.opacity(0.15))
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // Removed divider line

    // MARK: - About Section
    private func aboutSection(title: String, bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(bio)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Gallery Section
    private func gallerySection(_ urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(urls, id: \.self) { url in
                        ProfileGalleryCell(url: url)
                            .frame(width: 280) // Increased width for horizontal scrolling
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Custom Views

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        CaretakerProfileView(caretakerId: "SAMPLE_ID")
    }
}
