import SwiftUI
import Kingfisher
import MessageUI

struct CaretakerBookingsInfoView: View {
    let booking: BookingItem
    @StateObject private var viewModel:   CaretakerBookingsInfoViewModel
    @StateObject private var ratingVM:    RatingViewModel
    @StateObject private var serviceVM:   ServiceFlowViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showingMessageComposer = false
    @State private var showRatingSheet        = false

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor    = Color(red: 242/255, green: 242/255, blue: 247/255)

    private var isCompleted: Bool { booking.dynamicStatus == .completed }
    private var isWaitingForAcceptance: Bool { booking.dynamicStatus == .requested }

    init(booking: BookingItem) {
        self.booking = booking
        _viewModel  = StateObject(wrappedValue: CaretakerBookingsInfoViewModel())
        _ratingVM   = StateObject(wrappedValue: RatingViewModel(
            targetId:       booking.caretakerRequest?.caretakerId ?? "",
            collectionName: "caretakers",
            bookingId:      booking.id
        ))
        _serviceVM  = StateObject(wrappedValue: ServiceFlowViewModel(booking: booking))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    headerView.padding(.top, 10)

                    // MARK: Service Flow (Start / PIN)
                    serviceFlowSection

                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView().padding(.top, 50); Spacer() }
                    } else {

                        // MARK: Caretaker Information
                        if let caretaker = viewModel.caretaker {
                            sectionTitle("Caretaker Information")
                            caretakerCard(caretaker)
                        }

                        // MARK: Booking Details
                        sectionTitle("Booking Details")
                        bookingDetailsCard

                        // MARK: Track Your Pet
                        if let caretaker = viewModel.caretaker,
                           let lat = caretaker.latitude, let lon = caretaker.longitude,
                           (lat != 0 || lon != 0) {
                            sectionTitle("Track Your Pet")
                            NavigationLink(destination: TrackPetMapView(
                                walkerLatitude: lat,
                                walkerLongitude: lon,
                                walkerName: caretaker.name
                            )) {
                                trackPetRow
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // MARK: Payment Details
                        sectionTitle("Caretaking Fees")
                        paymentDetailsCard

                        // MARK: Rating (completed bookings only)
                        if isCompleted, let caretaker = viewModel.caretaker {
                            sectionTitle("Your Rating")
                            if ratingVM.isChecking {
                                HStack { Spacer(); ProgressView().tint(snuffyPink); Spacer() }
                                    .padding(.vertical, 8)
                            } else if ratingVM.hasRated {
                                ratedCard
                            } else {
                                rateRow(name: caretaker.name)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .blur(radius: isWaitingForAcceptance ? 18 : 0)
            .disabled(isWaitingForAcceptance)
            .allowsHitTesting(!isWaitingForAcceptance)

            if isWaitingForAcceptance {
                FindingProviderOverlay(provider: .caretaker)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)

                floatingBackButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isWaitingForAcceptance)
        .navigationBarHidden(true)
        .onAppear {
            if let caretakerId = booking.caretakerRequest?.caretakerId, !caretakerId.isEmpty {
                viewModel.fetchCaretakerDetails(caretakerId: caretakerId)
            } else {
                viewModel.isLoading = false
            }
        }
        // Once the real document ID is resolved, update ratingVM and check existing rating
        .onChange(of: viewModel.caretakerDocumentId) { _, docId in
            guard let docId else { return }
            ratingVM.setTargetDocumentId(docId)
            if isCompleted {
                Task { await ratingVM.checkExistingRating() }
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let phone = viewModel.caretaker?.phoneNumber, !phone.isEmpty,
               MFMessageComposeViewController.canSendText() {
                MessageComposeView(recipients: [phone], body: "Hi, I would like to chat about my booking.")
                    .ignoresSafeArea()
            } else {
                Text("Messaging not supported on this device.")
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            if let caretaker = viewModel.caretaker {
                RatingSheetView(targetName: caretaker.name, vm: ratingVM)
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

    /// Back button rendered above the blurred content while waiting for acceptance,
    /// so the pet owner can still leave the screen.
    private var floatingBackButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.gray)
            .padding(.top, 8)
            .padding(.bottom, -4)
    }

    // MARK: – Caretaker Card

    private func caretakerCard(_ caretaker: Caretakers) -> some View {
        NavigationLink(destination: CaretakerProfileView(caretakerId: caretaker.caretakerId)) {
            HStack(spacing: 16) {
                if let urlStr = caretaker.profilePic, let url = URL(string: urlStr) {
                    KFImage(url)
                        .placeholder { Color.gray.opacity(0.3) }
                        .resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(Circle())
                } else {
                    Image("CaretakerPlaceholder")
                        .resizable().scaledToFill()
                        .frame(width: 64, height: 64)
                        .background(Color.gray.opacity(0.3)).clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(caretaker.name)
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                    Text(caretaker.address)
                        .font(.system(size: 14)).foregroundColor(.gray).lineLimit(1)
                }
                Spacer()

                HStack(spacing: 12) {
                    if let phone = caretaker.phoneNumber, !phone.isEmpty {
                        actionCircleButton(icon: "phone.fill") {
                            let clean = phone.replacingOccurrences(of: " ", with: "")
                            if let url = URL(string: "tel://\(clean)") { UIApplication.shared.open(url) }
                        }
                        actionCircleButton(icon: "message.fill") { showingMessageComposer = true }
                    }
                }
            }
            .padding(16)
            .background(Color.white).cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func actionCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                .frame(width: 40, height: 40).background(snuffyPink).clipShape(Circle())
                .shadow(color: snuffyPink.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: – Booking Details Card

    private var bookingDetailsCard: some View {
        VStack(spacing: 0) {
            let request = booking.caretakerRequest
            detailRow(icon: "pawprint.fill",    label: "Pet Name",   value: booking.petName)
            Divider().padding(.leading, 44)
            detailRow(icon: "calendar",         label: "Start Date", value: formatDate(booking.startDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill",       label: "Start Time", value: formatTime(booking.startDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "calendar",         label: "End Date",   value: formatDate(booking.endDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill",       label: "End Time",   value: formatTime(booking.endDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "info.circle.fill", label: "Status",     value: booking.status.capitalized)
            Divider().padding(.leading, 44)
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "map.fill")
                    .foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pickup Location").font(.system(size: 16)).foregroundColor(.black)
                    if let req = request {
                        let addr = shortPickupAddress(for: req)
                        if !addr.isEmpty {
                            Text(addr).font(.system(size: 14)).foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16).padding(.horizontal, 16)
        }
        .background(Color.white).cornerRadius(20)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            Text(label).font(.system(size: 16)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 16)).foregroundColor(.gray)
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
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

    // MARK: – Payment Details

    private var paymentDetailsCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "indianrupeesign.circle.fill")
                .foregroundColor(snuffyPink).font(.system(size: 20)).frame(width: 24)
            Text("Payment Details").font(.system(size: 16)).foregroundColor(.black)
            Spacer()
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(Color.white).cornerRadius(20)
    }

    // MARK: – Rating Rows

    private func rateRow(name: String) -> some View {
        Button { showRatingSheet = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .foregroundColor(snuffyPink).font(.system(size: 20)).frame(width: 24)
                Text("Rate your caretaker")
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
                    Text("Tap to generate a PIN for your caretaker")
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
                Text("Share this PIN with your caretaker")
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
            Text("Waiting for caretaker to enter PIN…")
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
                Image(systemName: "pawprint.fill")
                    .foregroundColor(snuffyPink).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Service in Progress")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                Text("Your pet is with the caretaker")
                    .font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Helpers

    private func shortPickupAddress(for request: ScheduleCaretakerRequest) -> String {
        var parts: [String] = []
        if let v = request.buildingNo, !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = request.houseNo,    !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = request.landmark,   !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        return parts.joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
