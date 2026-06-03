import SwiftUI
import Kingfisher

struct CaretakerHomeView: View {
    @StateObject private var viewModel = CaretakerHomeViewModel()

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    // Reject confirmation alert state
    @State private var pendingRejectCaretaker: ScheduleCaretakerRequest? = nil
    @State private var pendingRejectDogWalker: ScheduleDogWalkerRequest? = nil

    // State for popup
    @State private var showNewRequestPopup = false
    @State private var shownRequestIds = Set<String>()
    @State private var selectedBookingForDetails: BookingItem? = nil
    @State private var shouldNavigateToDetails = false

    private var isDogWalker: Bool { viewModel.dogWalkerId != nil }

    private var articlesForRole: [CaregiverArticle] {
        isDogWalker
            ? CaregiverArticleLibrary.dogWalkerArticles
            : CaregiverArticleLibrary.caretakerArticles
    }

    private var sectionTitleForRole: String {
        isDogWalker ? "For Dog Walkers" : "For Caretakers"
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Home")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.shouldNavigateToProfile = true
                    }) {
                        Circle()
                            .fill(snuffyPink)
                            .frame(width: 40, height: 40)
                            .shadow(color: snuffyPink.opacity(0.3), radius: 5, x: 0, y: 3)
                            .overlay(
                                Text(viewModel.userInitials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // 1. Banner Section
                        Image("Caretaker Home Screen Banner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 25)
                        
                        // 2. Upcoming Bookings Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Upcoming Bookings")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            
                            if viewModel.isLoading && viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                                ProgressView()
                                    .padding(.vertical, 30)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 25)
                            } else if viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("No Upcoming Bookings")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .background(Color.white)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 25)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.scheduleRequests, id: \.requestId) { request in
                                            RequestCard(
                                                petName: request.petName,
                                                serviceType: "Pet Sitting",
                                                duration: caretakerDuration(for: request),
                                                dateLine: caretakerDateLine(for: request),
                                                imageUrl: request.petImageUrl,
                                                onAccept: { viewModel.acceptCaretakerRequest(request: request) },
                                                onReject: { pendingRejectCaretaker = request }
                                            )
                                            .frame(width: UIScreen.main.bounds.width - 40)
                                        }

                                        ForEach(viewModel.dogWalkerRequests, id: \.requestId) { request in
                                            RequestCard(
                                                petName: request.petName,
                                                serviceType: "Dog Walking",
                                                duration: request.duration,
                                                dateLine: dogWalkerDateLine(for: request),
                                                imageUrl: request.petImageUrl,
                                                onAccept: { viewModel.acceptDogWalkerRequest(request: request) },
                                                onReject: { pendingRejectDogWalker = request }
                                            )
                                            .frame(width: UIScreen.main.bounds.width - 40)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12) // padded to prevent shadow clipping
                                }
                                .padding(.bottom, 25)
                            }
                        }

                        // 3. Calendar Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Booking Calendar")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                            MonthCalendarView(bookingsByDate: viewModel.bookingsByDate)
                                .padding(.bottom, 25)
                        }

                        // 4. Articles Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text(sectionTitleForRole)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                            VStack(spacing: 16) {
                                ForEach(articlesForRole) { article in
                                    NavigationLink(destination: ArticleReaderView(article: article)) {
                                        ArticleCard(
                                            category: article.category,
                                            title: article.title,
                                            readTime: article.readTime,
                                            iconName: article.iconName,
                                            iconColor: article.iconColor
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            
            // Pop-up Notification
            if showNewRequestPopup, let requestItem = pendingRequest {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .font(.system(size: 56))
                            .foregroundColor(snuffyPink)
                            .padding(.top, 16)
                        
                        Text("You've received a new booking request!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                shownRequestIds.insert(requestItem.id)
                                withAnimation {
                                    showNewRequestPopup = false
                                }
                            }) {
                                Text("Okay")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(snuffyPink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 26)
                                            .stroke(snuffyPink, lineWidth: 2)
                                    )
                                    .cornerRadius(26)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                shownRequestIds.insert(requestItem.id)
                                withAnimation {
                                    showNewRequestPopup = false
                                }
                                selectedBookingForDetails = requestItem
                                shouldNavigateToDetails = true
                            }) {
                                Text("View")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(snuffyPink)
                                    .cornerRadius(26)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .alert("Reject this booking?",
               isPresented: Binding(
                get: { pendingRejectCaretaker != nil },
                set: { if !$0 { pendingRejectCaretaker = nil } }
               )) {
            Button("Reject", role: .destructive) {
                if let r = pendingRejectCaretaker { viewModel.rejectCaretakerRequest(request: r) }
                pendingRejectCaretaker = nil
            }
            Button("Cancel", role: .cancel) { pendingRejectCaretaker = nil }
        } message: {
            Text("This booking will be reassigned to the next available caretaker.")
        }
        .alert("Reject this booking?",
               isPresented: Binding(
                get: { pendingRejectDogWalker != nil },
                set: { if !$0 { pendingRejectDogWalker = nil } }
               )) {
            Button("Reject", role: .destructive) {
                if let r = pendingRejectDogWalker { viewModel.rejectDogWalkerRequest(request: r) }
                pendingRejectDogWalker = nil
            }
            Button("Cancel", role: .cancel) { pendingRejectDogWalker = nil }
        } message: {
            Text("This booking will be reassigned to the next available dog walker.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .onAppear {
            viewModel.checkUserRoleAndFetchRequests()
            viewModel.fetchUserProfile()
            checkForNewRequests()
        }
        .onChange(of: viewModel.scheduleRequests) { _, _ in
            checkForNewRequests()
        }
        .onChange(of: viewModel.dogWalkerRequests) { _, _ in
            checkForNewRequests()
        }
        .navigationDestination(isPresented: $shouldNavigateToDetails) {
            if let booking = selectedBookingForDetails {
                CaregiverBookingDetailsView(booking: booking)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitle("", displayMode: .inline)
        .fullScreenCover(isPresented: $viewModel.shouldNavigateToProfile) {
            ProfileCompatibilityView(caretakerVM: viewModel)
        }
        .alert(item: Binding<AlertError?>(
            get: { viewModel.errorMessage.map { AlertError(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Booking date-line formatters

extension CaretakerHomeView {
    fileprivate func caretakerDateLine(for request: ScheduleCaretakerRequest) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        guard let start = request.startDate, let end = request.endDate else { return request.duration }
        return "\(f.string(from: start)) • \(f.string(from: end))"
    }

    fileprivate func caretakerDuration(for request: ScheduleCaretakerRequest) -> String {
        guard let start = request.startDate, let end = request.endDate else { return request.duration }
        let calendar = Calendar.current
        let startOfDay1 = calendar.startOfDay(for: start)
        let startOfDay2 = calendar.startOfDay(for: end)
        let components = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2)
        let days = max(1, abs(components.day ?? 0))
        return "\(days) Day\(days == 1 ? "" : "s")"
    }

    fileprivate func dogWalkerDateLine(for request: ScheduleDogWalkerRequest) -> String {
        let dateFmt = DateFormatter(); dateFmt.dateFormat = "d MMM yyyy"
        let timeFmt = DateFormatter(); timeFmt.dateFormat = "h:mm a"
        return "\(dateFmt.string(from: request.date)) • \(timeFmt.string(from: request.startTime)) – \(timeFmt.string(from: request.endTime))"
    }
}

// MARK: - New Request Notification Helper
extension CaretakerHomeView {
    private var pendingRequest: BookingItem? {
        if let request = viewModel.scheduleRequests.first(where: { !shownRequestIds.contains($0.requestId) }) {
            return BookingItem(
                id: request.requestId,
                petId: request.petId,
                petName: request.petName,
                petImageUrl: request.petImageUrl,
                startDate: request.startDate ?? Date(),
                endDate: request.endDate ?? Date(),
                status: request.status,
                type: .caretaker,
                durationString: request.duration,
                caretakerRequest: request,
                dogWalkerRequest: nil
            )
        }
        if let request = viewModel.dogWalkerRequests.first(where: { !shownRequestIds.contains($0.requestId) }) {
            return BookingItem(
                id: request.requestId,
                petId: request.petId,
                petName: request.petName,
                petImageUrl: request.petImageUrl,
                startDate: request.startTime,
                endDate: request.endTime,
                status: request.status,
                type: .dogWalker,
                durationString: request.duration,
                caretakerRequest: nil,
                dogWalkerRequest: request
            )
        }
        return nil
    }

    private func checkForNewRequests() {
        if pendingRequest != nil {
            withAnimation {
                showNewRequestPopup = true
            }
        }
    }
}

struct ArticleCard: View {
    let category: String
    let title: String
    let readTime: String
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(iconColor)
                    .tracking(1)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(readTime)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct RequestCard: View {
    let petName: String
    let serviceType: String
    let duration: String
    let dateLine: String
    let imageUrl: String?
    let onAccept: () -> Void
    let onReject: () -> Void

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let imageSize: CGFloat = 75

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                // Pet Image (Circle)
                if let urlStr = imageUrl, let url = URL(string: urlStr) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Image("DogPlaceholder")
                                .resizable()
                                .scaledToFill()
                        }
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                } else {
                    Image("DogPlaceholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(petName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // New badge
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 8))
                            Text("New")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 138/255, green: 100/255, blue: 250/255))
                        .clipShape(Capsule())
                    }

                    Text("\(serviceType) • \(duration)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Text(dateLine)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // Action Buttons (Accept Green, Reject Red)
            HStack(spacing: 16) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 46/255, green: 204/255, blue: 113/255))
                        .clipShape(Capsule())
                }

                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 255/255, green: 71/255, blue: 87/255))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        CaretakerHomeView()
    }
}

// MARK: - Bridge to UserProfileView
struct ProfileCompatibilityView: View {
    @ObservedObject var caretakerVM: CaretakerHomeViewModel
    @StateObject private var homeVM = HomeViewModel()
    
    var body: some View {
        UserProfileView(viewModel: homeVM)
            .onAppear {
                homeVM.userName = caretakerVM.userName
                homeVM.userEmail = caretakerVM.userEmail
                homeVM.userInitials = caretakerVM.userInitials
            }
            .onChange(of: homeVM.shouldNavigateToLogin) { newValue in
                if newValue {
                    caretakerVM.logout()
                }
            }
    }
}
