//
//  CreateEventView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [snuffyPink.opacity(0.18), Color.white],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Banner Image
                        if let image = viewModel.eventImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                                .overlay(
                                    Button {
                                        viewModel.eventImage = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                            .shadow(radius: 4)
                                    }
                                    .padding(24), alignment: .topTrailing
                                )
                        } else {
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                VStack(spacing: 10) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 36))
                                        .foregroundColor(snuffyPink)
                                    Text("Add Event Banner")
                                        .font(.system(size: 14))
                                        .foregroundColor(snuffyPink)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(snuffyPink.opacity(0.08))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(snuffyPink.opacity(0.3),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                            }
                            .padding(.horizontal, 20)
                            .onChange(of: photoPickerItem) { _, item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        viewModel.eventImage = ui
                                    }
                                }
                            }
                        }

                        // MARK: - Form Fields
                        formSection {
                            inputField(title: "Event Title", placeholder: "e.g. Dog Show at Central Park",
                                       text: $viewModel.eventTitle)
                            Divider().padding(.leading, 16)
                            inputField(title: "Location", placeholder: "Venue or address",
                                       text: $viewModel.eventLocation)
                            Divider().padding(.leading, 16)
                            inputField(title: "Contact Info", placeholder: "Phone or email (optional)",
                                       text: $viewModel.eventContactInfo)
                        }

                        // MARK: - Tag Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Tag")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.availableEventTags, id: \.self) { tag in
                                        Button {
                                            viewModel.eventTag = tag
                                        } label: {
                                            Text(tag)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(viewModel.eventTag == tag ? .white : snuffyPink)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.eventTag == tag
                                                    ? snuffyPink
                                                    : snuffyPink.opacity(0.1)
                                                )
                                                .cornerRadius(20)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // MARK: - Date Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Event Date")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)

                            DatePicker("", selection: $viewModel.eventDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 20)
                                .tint(snuffyPink)
                        }

                        // MARK: - Error
                        if let error = viewModel.errorMessage {
                            Text(error).font(.system(size: 13)).foregroundColor(.red)
                                .padding(.horizontal, 20)
                        }

                        // MARK: - Share Button
                        Button {
                            viewModel.uploadEvent()
                        } label: {
                            HStack {
                                if viewModel.isUploading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Create Event")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(16)
                            .shadow(color: snuffyPink.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .disabled(viewModel.isUploading)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(snuffyPink)
                }
            }
            .onChange(of: viewModel.didPost) { _, posted in
                if posted { viewModel.reset(); dismiss() }
            }
        }
    }

    // MARK: - Helpers
    private func formSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 20)
    }

    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
}
