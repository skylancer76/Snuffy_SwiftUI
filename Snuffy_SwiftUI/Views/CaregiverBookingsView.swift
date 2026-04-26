//
//  CaregiverBookingsView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI
import Kingfisher

struct CaregiverBookingsView: View {
    @StateObject private var viewModel = CaregiverBookingsViewModel()
    @State private var selectedTab: Int = 0

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient — same as snuffy-main gradient
                LinearGradient(
                    colors: [snuffyPink.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // Title
                    Text("My Bookings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    // Segmented control — Upcoming / Completed
                    HStack(spacing: 0) {
                        segmentButton("Upcoming", 0)
                        segmentButton("Completed", 1)
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().fill(snuffyPink.opacity(0.08)))
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        let items = selectedTab == 0 ? viewModel.upcomingBookings : viewModel.completedBookings
                        if items.isEmpty {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No \(selectedTab == 0 ? "upcoming" : "completed") bookings")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(items) { booking in
                                        let bookingItem = convertToBookingItem(booking)
                                        NavigationLink(destination: destinationView(for: bookingItem)) {
                                            CaregiverBookingCard(
                                                booking: booking,
                                                onMarkComplete: selectedTab == 0 ? { viewModel.markAsCompleted(booking: booking) } : nil
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
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

    @ViewBuilder
    private func destinationView(for item: BookingItem) -> some View {
        // Caregiver always sees their booking details (caregiver POV: pet parent, pet details, etc.)
        CaregiverBookingDetailsView(booking: item)
    }
}

// MARK: - Booking Card
struct CaregiverBookingCard: View {
    let booking: CaregiverBookingItem
    var onMarkComplete: (() -> Void)?

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Pet image
            petImageView
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.petName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                Text(booking.ownerName)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Text(booking.petBreed)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Text(booking.durationLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)

                HStack {
                    statusBadge

                    Spacer()

                    if let complete = onMarkComplete {
                        Button(action: complete) {
                            Text("Mark Complete")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(snuffyPink)
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var petImageView: some View {
        if let urlStr = booking.petImageUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder {
                    Image("DogPlaceholder")
                        .resizable()
                        .scaledToFill()
                }
                .resizable()
                .scaledToFill()
        } else {
            Image("DogPlaceholder")
                .resizable()
                .scaledToFill()
        }
    }

    private var statusBadge: some View {
        Text(booking.displayStatus)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch booking.status.lowercased() {
        case "accepted":  return .blue
        case "ongoing":   return snuffyPink
        case "completed": return .green
        case "rejected":  return .red
        default:          return .orange
        }
    }
}

#Preview {
    CaregiverBookingsView()
}
