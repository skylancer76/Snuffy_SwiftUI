//
//  CaregiverBookingDetailsView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI

struct CaregiverBookingDetailsView: View {
    let booking: BookingItem
    @Environment(\.dismiss) var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor = Color(red: 242/255, green: 242/255, blue: 247/255)

    private var caretakerReq: ScheduleCaretakerRequest? { booking.caretakerRequest }
    private var dogWalkerReq: ScheduleDogWalkerRequest? { booking.dogWalkerRequest }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Header
                    headerView.padding(.top, 10)

                    // MARK: Booking Details (caregiver POV)
                    sectionTitle("Booking Details")
                    bookingDetailsCard

                    // MARK: Pet Details → CaregiverPetProfileView (read-only)
                    sectionTitle("Pet Details")
                    petDetailsRow

                    // MARK: Instructions
                    if let instructions = caretakerReq?.instructions ?? dogWalkerReq?.instructions,
                       !instructions.isEmpty {
                        sectionTitle("Special Instructions")
                        instructionsCard(instructions)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
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

    // MARK: – Booking Details Card (mirrors snuffy-main caretaker booking info cells)
    private var bookingDetailsCard: some View {
        VStack(spacing: 0) {
            // Pet Parent (owner's name)
            let ownerName = caretakerReq?.userName ?? dogWalkerReq?.userName ?? "–"
            detailRow(icon: "person.fill",       label: "Pet Parent",   value: ownerName)
            Divider().padding(.leading, 56)
            detailRow(icon: "pawprint.fill",     label: "Pet Name",     value: booking.petName)
            Divider().padding(.leading, 56)

            if booking.type == .caretaker {
                // Caretaker: start date + time, end date + time
                detailRow(icon: "calendar",      label: "Start Date",   value: formatDate(booking.startDate))
                Divider().padding(.leading, 56)
                detailRow(icon: "clock.fill",    label: "Start Time",   value: formatTime(booking.startDate))
                Divider().padding(.leading, 56)
                detailRow(icon: "calendar",      label: "End Date",     value: formatDate(booking.endDate))
                Divider().padding(.leading, 56)
                detailRow(icon: "clock.fill",    label: "End Time",     value: formatTime(booking.endDate))
            } else {
                // Dog Walker: date + start/end time
                detailRow(icon: "calendar",      label: "Date",         value: formatDate(booking.startDate))
                Divider().padding(.leading, 56)
                detailRow(icon: "clock.fill",    label: "Start Time",   value: formatTime(booking.startDate))
                Divider().padding(.leading, 56)
                detailRow(icon: "clock.fill",    label: "End Time",     value: formatTime(booking.endDate))
            }

            Divider().padding(.leading, 56)
            detailRow(icon: "info.circle.fill",  label: "Status",       value: booking.status.capitalized)

            if let address = pickupAddress, !address.isEmpty {
                Divider().padding(.leading, 56)
                addressRow(address)
            }
        }
        .background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Pet Details row → read-only CaregiverPetProfileView
    @ViewBuilder
    private var petDetailsRow: some View {
        if let petId = booking.petId {
            NavigationLink(destination: CaregiverPetProfileView(petId: petId)) {
                petDetailCell
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            petDetailCell
        }
    }

    private var petDetailCell: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(snuffyPink).frame(width: 40, height: 40)
                Image(systemName: "pawprint.fill").foregroundColor(.white).font(.system(size: 18))
            }
            Text("Pet Details").font(.system(size: 16)).foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
        }
        .padding(16).background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func instructionsCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "note.text").foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24)
            Text(text).font(.system(size: 15)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16).background(Color.white).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: – Row builders
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            Text(label).font(.system(size: 16)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
    }

    private func addressRow(_ address: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "map.fill").foregroundColor(snuffyPink).font(.system(size: 18)).frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pickup Location").font(.system(size: 16)).foregroundColor(.black)
                Text(address).font(.system(size: 14)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
    }

    // MARK: – Helpers
    private var pickupAddress: String? {
        var parts: [String] = []
        let building = caretakerReq?.buildingNo ?? dogWalkerReq?.buildingNo
        let house    = caretakerReq?.houseNo    ?? dogWalkerReq?.houseNo
        let landmark = caretakerReq?.landmark   ?? dogWalkerReq?.landmark
        if let v = building, !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = house,    !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        if let v = landmark, !v.isEmpty { parts.append(v.trimmingCharacters(in: .whitespaces)) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
