import SwiftUI
import Kingfisher

struct CaregiverBookingsView: View {
    @StateObject private var viewModel = CaregiverBookingsViewModel()
    @State private var selectedTab: Int = 0

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            // Background gradient — same as MyBookingsView gradient
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

                // Title
                Text("My Bookings")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Segmented control — Upcoming / Completed
                HStack(spacing: 0) {
                    segmentButton("Upcoming", 0)
                    segmentButton("Completed", 1)
                }
                .padding(4)
                .background(
                    ZStack {
                        Capsule()
                            .fill(.ultraThinMaterial)
                        Capsule()
                            .fill(snuffyPink.opacity(0.10))
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 16)

                // List
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        let items = selectedTab == 0 ? viewModel.upcomingBookings : viewModel.completedBookings
                        if items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No \(selectedTab == 0 ? "upcoming" : "completed") bookings")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 24) {
                                ForEach(items) { booking in
                                    let bookingItem = convertToBookingItem(booking)
                                    CaregiverBookingCard(booking: booking, bookingItem: bookingItem)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarTitle("", displayMode: .inline)
    }

    @ViewBuilder
    private func segmentButton(_ title: String, _ index: Int) -> some View {
        let isSelected = selectedTab == index
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
                        }
                    }
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func convertToBookingItem(_ item: CaregiverBookingItem) -> BookingItem {
        return BookingItem(
            id: item.id,
            petId: item.petId,
            petName: item.petName,
            petImageUrl: item.petImageUrl,
            startDate: item.caretakerRequest?.startDate ?? item.dogWalkerRequest?.startTime ?? Date(),
            endDate: item.caretakerRequest?.endDate ?? item.dogWalkerRequest?.endTime ?? Date(),
            status: item.status,
            type: item.type,
            durationString: item.durationLabel,
            caretakerRequest: item.caretakerRequest,
            dogWalkerRequest: item.dogWalkerRequest
        )
    }
}

// MARK: - Booking Card
struct CaregiverBookingCard: View {
    let booking: CaregiverBookingItem
    let bookingItem: BookingItem

    private let snuffyPink    = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let petCircleFill = Color(red: 255/255, green: 214/255, blue: 230/255)
    private let imageSize: CGFloat = 75

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // TOP SECTION
            HStack(alignment: .top, spacing: 16) {
                // Image
                ZStack {
                    Circle()
                        .fill(petCircleFill)
                        .frame(width: imageSize, height: imageSize)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    
                    petImageView
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(booking.petName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        statusBadge
                    }
                    
                    if bookingItem.type == .caretaker {
                        Text("Pet Sitting • \(caretakerDuration(start: bookingItem.startDate, end: bookingItem.endDate))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(caretakerDateLine(start: bookingItem.startDate, end: bookingItem.endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("Dog Walking • \(bookingItem.durationString)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(dogWalkerDateLine(start: bookingItem.startDate, end: bookingItem.endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            // BOTTOM BUTTONS
            HStack(spacing: 12) {
                NavigationLink(destination: CaregiverPetProfileView(petId: booking.petId ?? "")) {
                    Text("Pet Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(snuffyPink)
                        .cornerRadius(25)
                }
                
                NavigationLink(destination: CaregiverBookingDetailsView(booking: bookingItem)) {
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

    @ViewBuilder
    private var petImageView: some View {
        if let urlStr = booking.petImageUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder {
                    ZStack {
                        Circle().fill(petCircleFill)
                        ProgressView().scaleEffect(0.7)
                    }
                }
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "dog.fill")
                .font(.system(size: 24))
                .foregroundColor(snuffyPink)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 3) {
            let s = booking.status.lowercased()
            if s == "completed" || s == "accepted" {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 11, weight: .semibold))
            } else if s == "ongoing" {
                Image(systemName: "record.circle")
                    .font(.system(size: 11, weight: .semibold))
            } else if s == "rejected" {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11, weight: .semibold))
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(booking.displayStatus)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor)
        .cornerRadius(6)
        .fixedSize()
    }

    private var statusColor: Color {
        switch booking.status.lowercased() {
        case "accepted":  return .blue
        case "ongoing":   return .pink
        case "completed": return .green
        case "rejected":  return .red
        default:          return .orange
        }
    }
}

#Preview {
    NavigationStack {
        CaregiverBookingsView()
    }
}
