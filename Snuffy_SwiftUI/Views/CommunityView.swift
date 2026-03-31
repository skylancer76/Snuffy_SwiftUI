//
//  CommunityView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var createVM  = CreatePostViewModel()
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    @State private var selectedPostForComments: CommunityPost?
    @State private var searchText = ""
    @State private var selectedTag: String? = nil

    var filteredEvents: [CommunityEvent] {
        guard let tag = selectedTag else { return viewModel.events }
        return viewModel.events.filter { $0.tag == tag }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // MARK: - Background Gradient
            LinearGradient(colors: [snuffyPink.opacity(0.35), Color.white],
                           startPoint: .top, endPoint: .center)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Community")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                            Text("Connect with fellow pet lovers")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // User initials bubble
                        ZStack {
                            Circle().fill(snuffyPink)
                                .frame(width: 42, height: 42)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    // MARK: - Search / Filter Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        TextField("Search events nearby", text: $searchText)
                            .font(.system(size: 14))
                            .onSubmit {
                                selectedTag = searchText.isEmpty ? nil : searchText
                            }
                        if !searchText.isEmpty {
                            Button { searchText = ""; selectedTag = nil } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)

                    // MARK: - Announcements
                    if !viewModel.announcements.isEmpty {
                        sectionHeader("Announcements")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.announcements) { ann in
                                    AnnouncementPillView(announcement: ann, color: snuffyPink)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }

                    // MARK: - Events Nearby
                    if !viewModel.events.isEmpty {
                        HStack {
                            sectionHeader("Events Nearby")
                            Spacer()
                            // Tag filter pills
                            eventTagPills
                        }
                        .padding(.trailing, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(filteredEvents) { event in
                                    EventCard(event: event, snuffyPink: snuffyPink)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 28)
                    }

                    // MARK: - Posts Feed
                    sectionHeader("Feed")

                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        HStack { Spacer(); ProgressView().tint(snuffyPink); Spacer() }
                            .padding(.top, 40)
                    } else if viewModel.posts.isEmpty {
                        emptyFeedPlaceholder
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                CommunityPostCard(post: post) {
                                    viewModel.toggleLike(post: post)
                                } onComment: {
                                    selectedPostForComments = post
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 120) // space for floating tab bar
                    }
                }
            }

            // MARK: - FAB
            Button {
                viewModel.showCreateMenu = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [snuffyPink, snuffyPink.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: snuffyPink.opacity(0.45), radius: 12, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 22)
            .padding(.bottom, 90) // above tab bar
        }
        .navigationBarHidden(true)

        // MARK: - Sheets
        .sheet(isPresented: $viewModel.showCreateMenu) {
            CreatePostMenuSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView(viewModel: createVM)
        }
        .sheet(isPresented: $viewModel.showCreateEvent) {
            CreateEventView(viewModel: createVM)
        }
        .sheet(isPresented: $viewModel.showAddAnnouncement) {
            AddAnnouncementView(viewModel: createVM)
        }
        .sheet(item: $selectedPostForComments) { post in
            CommunityCommentsView(post: post)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
    }

    // MARK: - Tag Filter Pills
    private var eventTagPills: some View {
        let allTags = Array(Set(viewModel.events.map { $0.tag })).sorted()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                tagPill("All", isSelected: selectedTag == nil) { selectedTag = nil }
                ForEach(allTags, id: \.self) { tag in
                    tagPill(tag, isSelected: selectedTag == tag) { selectedTag = tag }
                }
            }
        }
    }

    private func tagPill(_ tag: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? .white : snuffyPink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? snuffyPink : snuffyPink.opacity(0.1))
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty Feed
    private var emptyFeedPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(snuffyPink.opacity(0.35))
            Text("No posts yet!")
                .font(.title3.bold())
                .foregroundColor(.black.opacity(0.7))
            Text("Be the first to share something\nwith the community 🐾")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Announcement Pill
struct AnnouncementPillView: View {
    let announcement: CommunityAnnouncement
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.15))
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 11))
                    .foregroundColor(color)
            }
            .frame(width: 28, height: 28)

            Text(announcement.text)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(2)
                .frame(maxWidth: 220, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: CommunityEvent
    let snuffyPink: Color

    private let cardW: CGFloat = 185

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image / placeholder
            ZStack {
                if let urlStr = event.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            eventPlaceholder
                        }
                    }
                } else {
                    eventPlaceholder
                }
            }
            .frame(width: cardW, height: 110)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                // Tag badge
                Text(event.tag)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(snuffyPink)
                    .cornerRadius(8)

                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)

                if !event.location.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundColor(snuffyPink)
                        Text(event.location)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(snuffyPink)
                    Text(event.eventDate, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .padding(10)
        }
        .frame(width: cardW)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private var eventPlaceholder: some View {
        ZStack {
            Color(red: 1.0, green: 0.9, blue: 0.94)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 32))
                .foregroundColor(snuffyPink.opacity(0.4))
        }
    }
}

#Preview {
    CommunityView()
}
