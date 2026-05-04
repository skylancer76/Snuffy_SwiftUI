//
//  DogWalkerBookingsInfoView.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma 

import SwiftUI
import Kingfisher
import MessageUI

struct DogWalkerBookingsInfoView: View {
    let booking: BookingItem
    @StateObject private var viewModel:  DogWalkerBookingsInfoViewModel
    @StateObject private var ratingVM:   RatingViewModel
    @StateObject private var serviceVM:  ServiceFlowViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showingMessageComposer = false
    @State private var showRatingSheet        = false

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor    = Color(red: 242/255, green: 242/255, blue: 247/255)

    private var req: ScheduleDogWalkerRequest? { booking.dogWalkerRequest }
    private var isCompleted: Bool { booking.dynamicStatus == .completed }

    init(booking: BookingItem) {
        self.booking = booking
        _viewModel  = StateObject(wrappedValue: DogWalkerBookingsInfoViewModel())
        _ratingVM   = StateObject(wrappedValue: RatingViewModel(
            targetId:       booking.dogWalkerRequest?.dogWalkerId ?? "",
            collectionName: "dogwalkers",
            bookingId:      booking.id
        ))
        _serviceVM  = StateObject(wrappedValue: ServiceFlowViewModel(booking: booking))
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    headerView.padding(.top, 10)

                    // MARK: Service Flow (Start / PIN)
                    serviceFlowSection

                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView().padding(.top, 50); Spacer() }
                    } else {

                        // MARK: Dog Walker Info
                        if let walker = viewModel.dogWalker {
                            sectionTitle("Dog Walker")
                            dogWalkerCard(walker)
                        }

                        // MARK: Booking Details
                        sectionTitle("Booking Details")
                        bookingDetailsCard

                        // MARK: Track Your Pet
                        if let walker = viewModel.dogWalker,
                           let lat = walker.latitude, let lon = walker.longitude,
                           (lat != 0 || lon != 0) {
                            sectionTitle("Track Your Pet")
                            NavigationLink(destination: TrackPetMapView(
                                walkerLatitude: lat,
                                walkerLongitude: lon,
                                walkerName: walker.name
                            )) {
                                trackPetRow
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // MARK: Rating (completed bookings only)
                        if isCompleted, let walker = viewModel.dogWalker {
                            sectionTitle("Your Rating")
                            if ratingVM.isChecking {
                                HStack { Spacer(); ProgressView().tint(snuffyPink); Spacer() }
                                    .padding(.vertical, 8)
                            } else if ratingVM.hasRated {
                                ratedCard
                            } else {
                                rateRow(name: walker.name)
                            }
                        }

                        // MARK: Instructions
                        if let instructions = req?.instructions, !instructions.isEmpty {
                            sectionTitle("Special Instructions")
                            instructionsCard(instructions)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let walkerId = req?.dogWalkerId, !walkerId.isEmpty {
                viewModel.fetchDogWalkerDetails(dogWalkerId: walkerId)
            } else {
                viewModel.isLoading = false
            }
            if isCompleted {
                Task { await ratingVM.checkExistingRating() }
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let phone = viewModel.dogWalker?.phoneNumber, !phone.isEmpty,
               MFMessageComposeViewController.canSendText() {
                MessageComposeView(recipients: [phone], body: "Hi, I wanted to check on my pet's walk.")
                    .ignoresSafeArea()
            } else {
                Text("Messaging is not supported on this device.").padding()
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            if let walker = viewModel.dogWalker {
                RatingSheetView(targetName: walker.name, vm: ratingVM)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: – Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            Text("Booking Info")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.gray)
            .padding(.top, 8)
            .padding(.bottom, -4)
    }

    // MARK: – Dog Walker Card

    private func dogWalkerCard(_ walker: DogWalker) -> some View {
        HStack(spacing: 16) {
            if let urlStr = walker.profilePic, let url = URL(string: urlStr) {
                KFImage(url)
                    .placeholder { Color.gray.opacity(0.3) }
                    .resizable().scaledToFill()
                    .frame(width: 64, height: 64).clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(snuffyPink.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "figure.walk")
                        .font(.system(size: 26))
                        .foregroundColor(snuffyPink)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(walker.name)
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                Text(walker.address)
                    .font(.system(size: 13)).foregroundColor(.gray).lineLimit(1)
            }

            Spacer()

            if let phone = walker.phoneNumber, !phone.isEmpty {
                HStack(spacing: 10) {
                    actionCircleButton(icon: "phone.fill") {
                        let clean = phone.replacingOccurrences(of: " ", with: "")
                        if let url = URL(string: "tel://\(clean)") { UIApplication.shared.open(url) }
                    }
                    actionCircleButton(icon: "message.fill") { showingMessageComposer = true }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func actionCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(width: 38, height: 38).background(snuffyPink).clipShape(Circle())
                .shadow(color: snuffyPink.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: – Booking Details Card

    private var bookingDetailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "pawprint.fill",    label: "Pet Name",   value: booking.petName)
            Divider().padding(.leading, 56)
            detailRow(icon: "calendar",         label: "Date",       value: formatDate(booking.startDate))
            Divider().padding(.leading, 56)
            detailRow(icon: "clock.fill",       label: "Start Time", value: formatTime(booking.startDate))
            Divider().padding(.leading, 56)
            detailRow(icon: "clock.fill",       label: "End Time",   value: formatTime(booking.endDate))
            Divider().padding(.leading, 56)
            detailRow(icon: "info.circle.fill", label: "Status",     value: booking.status.capitalized)

            if let address = pickupAddress, !address.isEmpty {
                Divider().padding(.leading, 56)
                addressRow(address)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Track Pet Row

    private var trackPetRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "location.north.circle.fill")
                .foregroundColor(snuffyPink).font(.system(size: 20)).frame(width: 24)
            Text("Track Your Pet").font(.system(size: 16)).foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Rating Rows

    private func rateRow(name: String) -> some View {
        Button { showRatingSheet = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .foregroundColor(snuffyPink).font(.system(size: 20)).frame(width: 24)
                Text("Rate your dog walker")
                    .font(.system(size: 16)).foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
            }
            .padding(.vertical, 16).padding(.horizontal, 16)
            .background(Color.white).cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var ratedCard: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= ratingVM.existingStars ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(star <= ratingVM.existingStars ? .yellow : .gray.opacity(0.3))
                }
            }
            Spacer()
            Text("Rating submitted")
                .font(.system(size: 13)).foregroundColor(.gray)
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Instructions

    private func instructionsCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "note.text")
                .foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            Text(text).font(.system(size: 15)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Service Flow (Pet Owner Side)

    @ViewBuilder
    private var serviceFlowSection: some View {
        if !isCompleted {
            if serviceVM.canStartService {
                sectionTitle("Service")
                startServiceCard
            } else if serviceVM.hasPinPending {
                sectionTitle("Service")
                pinDisplayCard
            } else if serviceVM.firestoreStatus == "ongoing" {
                sectionTitle("Service")
                serviceOngoingCard
            }
        }
    }

    private var startServiceCard: some View {
        Button {
            Task { await serviceVM.generatePin() }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(snuffyPink.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(snuffyPink).font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Service")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                    Text("Tap to generate a PIN for your dog walker")
                        .font(.system(size: 12)).foregroundColor(.gray)
                }
                Spacer()
                if serviceVM.isGeneratingPin {
                    ProgressView().tint(snuffyPink)
                } else {
                    Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
                }
            }
            .padding(16)
            .background(Color.white).cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(serviceVM.isGeneratingPin)
    }

    private var pinDisplayCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill").foregroundColor(snuffyPink).font(.system(size: 14))
                Text("Share this PIN with your dog walker")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                ForEach(Array((serviceVM.servicePin ?? "----").enumerated()), id: \.offset) { _, ch in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(snuffyPink.opacity(0.1))
                            .frame(width: 56, height: 64)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(snuffyPink.opacity(0.4), lineWidth: 1.5)
                            )
                        Text(String(ch))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(snuffyPink)
                    }
                }
            }
            Text("Waiting for dog walker to enter PIN…")
                .font(.system(size: 12)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20).padding(.horizontal, 16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var serviceOngoingCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(snuffyPink.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: "figure.walk")
                    .foregroundColor(snuffyPink).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Walk in Progress")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                Text("Your pet is out on a walk")
                    .font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Helpers

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            Text(label).font(.system(size: 16)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
    }

    private func addressRow(_ address: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "map.fill")
                .foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pickup Location").font(.system(size: 16)).foregroundColor(.black)
                Text(address).font(.system(size: 14)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
    }

    private var pickupAddress: String? {
        guard let r = req else { return nil }
        var parts: [String] = []
        if let v = r.buildingNo, !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = r.houseNo,    !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = r.landmark,   !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
