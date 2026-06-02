import SwiftUI
import Kingfisher

struct MyBookingsView: View {
    @StateObject private var viewModel = MyBookingsViewModel()
    @State private var selectedTab: Int = 0
    
    @State private var showingCaretakerBooking = false
    @State private var showingDogWalkerBooking = false
    
    @State private var selectedCaretakerBooking: BookingItem?
    @State private var selectedDogWalkerBooking: BookingItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.4),
                        Color(UIColor.systemGray6)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Title
                    Text("My Bookings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // MARK: - Segmented Control — full width, 16pt side padding
                    LiquidGlassSegmentedControl(selectedTab: $selectedTab)
                        .padding(.horizontal, 16)
                    
                    // MARK: - Bookings List
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            let currentBookings = selectedTab == 0
                                ? viewModel.caretakerBookings
                                : viewModel.dogWalkerBookings
                            
                            if currentBookings.isEmpty {
                                Text("No bookings found.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(currentBookings) { booking in
                                    BookingCard(
                                        booking: booking,
                                        onBookAgain: {
                                            if booking.type == .caretaker {
                                                showingCaretakerBooking = true
                                            } else {
                                                showingDogWalkerBooking = true
                                            }
                                        },
                                        onViewDetails: {
                                            if booking.type == .caretaker {
                                                selectedCaretakerBooking = booking
                                            } else {
                                                selectedDogWalkerBooking = booking
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: Group {
                        if let booking = selectedCaretakerBooking {
                            CaretakerBookingsInfoView(booking: booking)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedCaretakerBooking != nil },
                        set: { if !$0 { selectedCaretakerBooking = nil } }
                    )
                ) { EmptyView() }
            )
            .background(
                NavigationLink(
                    destination: Group {
                        if let booking = selectedDogWalkerBooking {
                            DogWalkerBookingsInfoView(booking: booking)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedDogWalkerBooking != nil },
                        set: { if !$0 { selectedDogWalkerBooking = nil } }
                    )
                ) { EmptyView() }
            )
            .sheet(isPresented: $showingCaretakerBooking) {
                BookCaretakerView()
            }
            .sheet(isPresented: $showingDogWalkerBooking) {
                BookDogWalkerView()
            }
        }
    }
}

// MARK: - Liquid Glass Segmented Control
struct LiquidGlassSegmentedControl: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Caretaker", index: 0)
            segmentButton(title: "Dogwalker", index: 1)
        }
        .padding(4)
        .frame(maxWidth: .infinity) // full width — parent controls side padding
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.10))
                Capsule()
                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
    
    @ViewBuilder
    private func segmentButton(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .black : Color.gray.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                        }
                    }
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let booking: BookingItem
    var onBookAgain: () -> Void
    var onViewDetails: () -> Void
    
    private let snuffyPink    = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let petCircleFill = Color(red: 255/255, green: 214/255, blue: 230/255)
    
    private let imageSize: CGFloat = 75
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                
                // MARK: - Pet Image
                ZStack {
                    Circle()
                        .fill(petCircleFill)
                        .frame(width: imageSize, height: imageSize)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    
                    petImageView
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                }
                
                // MARK: - Pet Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(booking.petName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        StatusBadge(status: booking.dynamicStatus)
                    }
                    
                    if booking.type == .caretaker {
                        Text("Pet Sitting • \(caretakerDuration(start: booking.startDate, end: booking.endDate))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(caretakerDateLine(start: booking.startDate, end: booking.endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("Dog Walking • \(booking.durationString)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(dogWalkerDateLine(start: booking.startDate, end: booking.endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            // MARK: - Action Buttons
            HStack(spacing: 12) {
                Button(action: onBookAgain) {
                    Text("Book Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(snuffyPink)
                        .cornerRadius(25)
                }
                
                Button(action: onViewDetails) {
                    Text("View Details")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.2))
                        .cornerRadius(25)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Pet Image View

    @ViewBuilder
    private var petImageView: some View {
        if let urlStr = booking.petImageUrl,
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder {
                    ZStack {
                        Circle().fill(petCircleFill)
                        ProgressView().scaleEffect(0.7)
                    }
                }
                .onFailure { err in
                }
                .resizable()
                .scaledToFill()
        } else {
            // petImageUrl is nil or empty — show icon on fill background
            Image(systemName: "dog.fill")
                .font(.system(size: 24))
                .foregroundColor(snuffyPink)
        }
    }
    
    // MARK: - Helpers
    private func caretakerDuration(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let startOfDay1 = calendar.startOfDay(for: start)
        let startOfDay2 = calendar.startOfDay(for: end)
        let components = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2)
        let days = max(1, abs(components.day ?? 0))
        return "\(days) Day\(days == 1 ? "" : "s")"
    }

    private func caretakerDateLine(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return "\(f.string(from: start)) • \(f.string(from: end))"
    }

    private func dogWalkerDateLine(start: Date, end: Date) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "d MMM yyyy"
        
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        
        return "\(dateFmt.string(from: start)) • \(timeFmt.string(from: start)) – \(timeFmt.string(from: end))"
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: DynamicBookingStatus
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: iconName(for: status))
                .font(.system(size: 11, weight: .semibold))
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(backgroundColor(for: status))
        .cornerRadius(6)
        .fixedSize()
    }
    
    private func iconName(for status: DynamicBookingStatus) -> String {
        switch status {
        case .requested:   return "clock"
        case .accepted:  return "checkmark.circle"
        case .ongoing:   return "record.circle"
        case .completed: return "checkmark.circle"
        case .rejected:  return "xmark.circle"
        }
    }
    
    private func backgroundColor(for status: DynamicBookingStatus) -> Color {
        switch status {
        case .requested:   return .orange
        case .accepted:  return .blue
        case .ongoing:   return .pink
        case .completed: return .green
        case .rejected:  return .red
        }
    }
}

struct MyBookingsView_Previews: PreviewProvider {
    static var previews: some View {
        MyBookingsView()
    }
}
