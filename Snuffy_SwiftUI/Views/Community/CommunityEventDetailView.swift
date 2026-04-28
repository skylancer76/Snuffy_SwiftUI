//
//  CommunityEventDetailView.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma 

import SwiftUI

struct CommunityEventDetailView: View {
    let event: CommunityEvent
    @StateObject private var vm: EventDetailViewModel
    @Environment(\.dismiss) var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor    = Color(red: 242/255, green: 242/255, blue: 247/255)

    init(event: CommunityEvent) {
        self.event = event
        _vm = StateObject(wrappedValue: EventDetailViewModel(event: event))
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: - Header Title & Hero Image
                    VStack(spacing: 16) {
                        Text(event.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        ZStack {
                            if let urlStr = event.imageURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        Color.clear
                                            .overlay(img.resizable().scaledToFill())
                                            .clipped()
                                    } else {
                                        eventPlaceholder
                                    }
                                }
                            } else {
                                eventPlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .clipped()
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: - Event Details Block
                        sectionTitle("Event Details")
                        eventDetailsCard

                        // MARK: - Event Overview Block
                        sectionTitle("Event Overview")
                        Text(event.location.isEmpty
                             ? "Join us for this exciting pet community event. Details will be shared by the organizer."
                             : "Join us at \(event.location) for this community event. Contact the organizer for more details.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineSpacing(4)

                        // MARK: - Action Button
                        actionButton
                            .padding(.top, 16)
                            .padding(.bottom, 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }

            // MARK: - Floating Back Button
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task { await vm.loadDetail() }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if vm.isOrganizer {
            NavigationLink {
                EventParticipantsView(event: event, vm: vm)
            } label: {
                Label("View Participants", systemImage: "person.2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(snuffyPink)
                    .cornerRadius(30)
                    .shadow(color: snuffyPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        } else if vm.isRegistered {
            Label("Registered", systemImage: "checkmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(uiColor: .systemGray3))
                .cornerRadius(30)
        } else {
            Button {
                Task { await vm.register() }
            } label: {
                Group {
                    if vm.isRegistering {
                        ProgressView().tint(.white)
                    } else {
                        Text("Register")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(snuffyPink)
                .cornerRadius(30)
                .shadow(color: snuffyPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(vm.isRegistering)
        }
    }

    // MARK: - Section Title

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .padding(.bottom, -4)
    }

    // MARK: - Event Details Card

    private var eventDetailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "calendar",
                      label: "Date",
                      value: formatDate(event.eventDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "mappin.and.ellipse",
                      label: "Location",
                      value: event.location.isEmpty ? "TBD" : event.location)
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill",
                      label: "Time",
                      value: formatTime(event.eventDate))
            if let contact = event.contactInfo, !contact.isEmpty {
                Divider().padding(.leading, 44)
                detailRow(icon: "phone.fill", label: "Contact", value: contact)
            }
            Divider().padding(.leading, 44)
            organizerRow
        }
        .background(Color.white)
        .cornerRadius(20)
    }

    private var organizerRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(snuffyPink)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)

            Text("Organizer")
                .font(.system(size: 16))
                .foregroundColor(.black)

            Spacer()

            if vm.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(vm.organizerName.isEmpty ? "—" : vm.organizerName)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(snuffyPink)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)

            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.black)

            Spacer()

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private var eventPlaceholder: some View {
        ZStack {
            Color(red: 1.0, green: 0.9, blue: 0.94)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(snuffyPink.opacity(0.4))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
