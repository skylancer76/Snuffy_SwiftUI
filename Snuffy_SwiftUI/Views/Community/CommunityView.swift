import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var createVM  = CreatePostViewModel()
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    @State private var selectedPostForComments: CommunityPost?
    @State private var searchText = ""
    @State private var selectedTag: String? = nil

    var filteredEvents: [CommunityEvent] {
        if let tag = selectedTag {
            return viewModel.events.filter { $0.tag == tag }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            return viewModel.events.filter {
                $0.tag.lowercased().contains(q) || $0.title.lowercased().contains(q)
            }
        }
        return viewModel.events
    }

    var availableTags: [String] {
        Array(Set(viewModel.events.map { $0.tag })).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {

                // MARK: - Background Gradient
                LinearGradient(colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                               startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: - Header
                        HStack(alignment: .center, spacing: 12) {
                            Text("Community")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                                
                            Spacer()
                            
                            // Add button
                            Button {
                                viewModel.showCreateMenu = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(snuffyPink)
                                    .clipShape(Circle())
                                    .shadow(color: snuffyPink.opacity(0.4), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)

                        // MARK: - Search / Filter Bar
                        SearchBarView(
                            placeholder: "Search events by name or label...",
                            onSearch: { query in
                                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    searchText = ""
                                    selectedTag = nil
                                } else {
                                    searchText = trimmed
                                    selectedTag = nil
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)

                        // MARK: - Events
                        if !viewModel.events.isEmpty {
                            HStack {
                                Text("Events")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                Menu {
                                    Button("All") {
                                        selectedTag = nil
                                        searchText = ""
                                    }
                                    ForEach(availableTags, id: \.self) { tag in
                                        Button(tag) {
                                            selectedTag = tag
                                            searchText = ""
                                        }
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(snuffyPink)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                            if filteredEvents.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.system(size: 36))
                                            .foregroundColor(snuffyPink.opacity(0.5))
                                        Text("No events for this filter")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 30)
                                    Spacer()
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(filteredEvents) { event in
                                            NavigationLink(destination: CommunityEventDetailView(event: event)) {
                                                EventCard(event: event, snuffyPink: snuffyPink)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                                }
                            }

                            Spacer().frame(height: 8)
                        }

                        // MARK: - Posts Feed (Trending)
                        sectionHeader("Trending")

                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            HStack { Spacer(); ProgressView().tint(snuffyPink); Spacer() }
                                .padding(.top, 40)
                        } else if viewModel.posts.isEmpty {
                            emptyFeedPlaceholder
                        } else {
                            LazyVStack(spacing: 20) {
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
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }

    // MARK: - Tag Pill

    private func tagPill(_ tag: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : snuffyPink)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? snuffyPink : snuffyPink.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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

// MARK: - Event Card
//
// Mirrors `PetCardView`: a flush image at the top with a white text panel
// directly underneath — no inner padding around the image, single rounded
// container, soft drop shadow.
struct EventCard: View {
    let event: CommunityEvent
    let snuffyPink: Color

    private let cardWidth: CGFloat = 240
    private let imageHeight: CGFloat = 190

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pet-card style: image fills the top of the card edge-to-edge
            ZStack {
                if let urlStr = event.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            eventPlaceholder
                        }
                    }
                } else {
                    eventPlaceholder
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: imageHeight, maxHeight: imageHeight)
            .clipped()

            // Text panel below, same shape as PetCardView
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(formattedDateDay(event.eventDate))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .frame(width: cardWidth)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var eventPlaceholder: some View {
        ZStack {
            Color(red: 1.0, green: 0.9, blue: 0.94)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 32))
                .foregroundColor(snuffyPink.opacity(0.4))
        }
    }

    /// "Date • Day • Time" matches the user's reference image for large cards.
    private func formattedDateDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM, yyyy • EEEE • hh:mma"
        return formatter.string(from: date)
    }
}

#Preview {
    CommunityView()
}
