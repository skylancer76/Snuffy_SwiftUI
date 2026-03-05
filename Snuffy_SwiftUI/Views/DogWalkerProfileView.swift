//
//  DogWalkerProfileView.swift
//  Snuffy_SwiftUI
//
//  Matches the same design as CaretakerProfileView:
//  circular image → bold name → gray address →
//  horizontal stat card (Rating | Distance | Walks Completed) →
//  About the DogWalker section → Gallery grid
//

import SwiftUI
import Kingfisher

struct DogWalkerProfileView: View {

    let dogWalkerId: String

    @StateObject private var viewModel = DogWalkerProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let columns = [GridItem(.flexible(), spacing: 8),
                           GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Standardized gradient (matches HomeView)
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Color.white
                .padding(.top, 400)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 50)

                    if viewModel.isLoading {
                        loadingView
                    } else if let walker = viewModel.dogWalker {
                        profileContent(walker)
                    } else if let err = viewModel.errorMessage {
                        errorView(err)
                    }
                }
            }

            // Back + share button row
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(snuffyPink)
                    Text("Booking Info")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(snuffyPink)
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(snuffyPink)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.load(dogWalkerId: dogWalkerId) }
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

    // MARK: - Profile Content
    @ViewBuilder
    private func profileContent(_ walker: DogWalker) -> some View {
        VStack(spacing: 0) {

            // 1. Circular profile image
            profileImageView()
                .padding(.top, 10)
                .padding(.bottom, 14)

            // 2. Name
            Text(walker.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

            // 3. Address
            Text(walker.address)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

            // 4. Horizontal stat card
            statCard(walker)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            // 5. About the DogWalker
            if let bio = walker.bio, !bio.isEmpty {
                aboutSection(title: "About the DogWalker", bio: bio)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }

            // 6. Gallery
            if !viewModel.resolvedGalleryURLs.isEmpty {
                gallerySection(viewModel.resolvedGalleryURLs)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
            }

            Spacer(minLength: 50)
        }
    }

    // MARK: - Profile Image
    private func profileImageView() -> some View {
        Group {
            if let url = viewModel.resolvedProfilePicURL {
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 130, height: 130)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    // MARK: - Horizontal Stat Card
    private func statCard(_ walker: DogWalker) -> some View {
        HStack(spacing: 0) {
            // Rating
            statItem(
                value: "\(walker.rating ?? "N/A") ★",
                label: "Rating"
            )

            statDivider

            // Distance
            statItem(
                value: viewModel.distanceText
                    .replacingOccurrences(of: " away", with: ""),
                label: "Distance"
            )

            statDivider

            // Walks Completed
            statItem(
                value: "\(walker.completedRequests)",
                label: "Walks Done"
            )
        }
        .padding(.vertical, 16)
        .background(Color(UIColor.systemPink).opacity(0.1))
        .cornerRadius(12)
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

    private var statDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    // MARK: - About Section (for when DogWalker bio is added)
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

    // MARK: - Gallery Section (for when DogWalker galleryImages is added)
    private func gallerySection(_ urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(urls, id: \.self) { url in
                        ProfileGalleryCell(url: url)
                            .frame(width: 280)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        DogWalkerProfileView(dogWalkerId: "SAMPLE_ID")
    }
}
