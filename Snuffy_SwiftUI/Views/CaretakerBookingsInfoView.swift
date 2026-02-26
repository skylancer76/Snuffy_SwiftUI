//
//  CaretakerBookingsInfoView.swift
//  Snuffy_SwiftUI
//
//  Created by Agent.
//

import SwiftUI
import Kingfisher
import MessageUI

struct CaretakerBookingsInfoView: View {
    let booking: BookingItem
    @StateObject private var viewModel = CaretakerBookingsInfoViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showingMessageComposer = false
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor = Color(red: 242/255, green: 242/255, blue: 247/255)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Header
                    headerView
                        .padding(.top, 10)
                    
                    if viewModel.isLoading {
                        CenterProgressView()
                    } else {
                        // MARK: - Caretaker Information
                        if let caretaker = viewModel.caretaker {
                            sectionTitle("Caretaker Information")
                            caretakerCard(caretaker)
                        }
                        
                        // MARK: - Booking Details
                        sectionTitle("Booking Details")
                        bookingDetailsCard
                        
                        // MARK: - Track Your Pet
                        sectionTitle("Track Your Pet")
                        trackPetCard
                        
                        // MARK: - Payment Details
                        sectionTitle("Caretaking fees")
                        paymentDetailsCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let caretakerId = booking.caretakerRequest?.caretakerId, !caretakerId.isEmpty {
                viewModel.fetchCaretakerDetails(caretakerId: caretakerId)
            } else {
                viewModel.isLoading = false
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let phone = viewModel.caretaker?.phoneNumber, !phone.isEmpty, MFMessageComposeViewController.canSendText() {
                MessageComposeView(recipients: [phone], body: "Hi, I would like to chat about my booking.")
                    .ignoresSafeArea()
            } else {
                Text("Messaging not supported on this device.")
            }
        }
    }
    
    private func CenterProgressView() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.top, 50)
            Spacer()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
    
    // MARK: - Caretaker Card
    private func caretakerCard(_ caretaker: Caretakers) -> some View {
        HStack(spacing: 16) {
            // Profile Pic
            if let urlStr = caretaker.profilePic, let url = URL(string: urlStr) {
                KFImage(url)
                    .placeholder {
                        Color.gray.opacity(0.3)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
            } else {
                Image("CaretakerPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
            }
            
            // Name & Address
            VStack(alignment: .leading, spacing: 4) {
                Text(caretaker.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text(caretaker.address)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                if let phone = caretaker.phoneNumber, !phone.isEmpty {
                    actionCircleButton(icon: "phone.fill") {
                        let formattedPhone = phone.replacingOccurrences(of: " ", with: "")
                        if let url = URL(string: "tel://\(formattedPhone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    actionCircleButton(icon: "message.fill") {
                        showingMessageComposer = true
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
    }
    
    private func actionCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(snuffyPink)
                .clipShape(Circle())
                .shadow(color: snuffyPink.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Booking Details
    private var bookingDetailsCard: some View {
        VStack(spacing: 0) {
            let request = booking.caretakerRequest
            
            detailRow(icon: "pawprint.fill", iconColor: snuffyPink, label: "Pet Name", value: booking.petName)
            Divider().padding(.leading, 44)
            detailRow(icon: "calendar", iconColor: snuffyPink, label: "Start Date", value: formatDate(booking.startDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill", iconColor: snuffyPink, label: "Start Time", value: formatTime(booking.startDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "calendar", iconColor: snuffyPink, label: "End Date", value: formatDate(booking.endDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill", iconColor: snuffyPink, label: "End Time", value: formatTime(booking.endDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "info.circle.fill", iconColor: snuffyPink, label: "Status", value: booking.status.capitalized)
            Divider().padding(.leading, 44)
            
            // Address row
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "map.fill")
                    .foregroundColor(snuffyPink)
                    .font(.system(size: 18))
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pickup Location")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    
                    if let req = request {
                        let addressStr = shortPickupAddress(for: req)
                        if !addressStr.isEmpty {
                            Text(addressStr)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
    
    private func detailRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)
            
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Track Pet Card
    private var trackPetCard: some View {
        Button(action: {
            print("Track Pet tapped")
        }) {
            HStack(spacing: 16) {
                Image(systemName: "location.north.circle.fill")
                    .foregroundColor(snuffyPink)
                    .font(.system(size: 20))
                    .frame(width: 24, alignment: .center)
                
                Text("Track Pet")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Payment Details Card
    private var paymentDetailsCard: some View {
        Button(action: {
            print("Payment Details tapped")
        }) {
            HStack(spacing: 16) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(snuffyPink)
                    .font(.system(size: 20))
                    .frame(width: 24, alignment: .center)
                
                Text("Payment Details")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
    
    private func shortPickupAddress(for request: ScheduleCaretakerRequest) -> String {
        var components: [String] = []
        if let bNo = request.buildingNo, !bNo.isEmpty {
            components.append(bNo.trimmingCharacters(in: .whitespaces))
        }
        if let hNo = request.houseNo, !hNo.isEmpty {
            components.append(hNo.trimmingCharacters(in: .whitespaces))
        }
        if let mark = request.landmark, !mark.isEmpty {
            components.append(mark.trimmingCharacters(in: .whitespaces))
        }
        return components.joined(separator: ", ")
    }
}
