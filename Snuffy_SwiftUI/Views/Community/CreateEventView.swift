import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor    = Color(red: 242/255, green: 242/255, blue: 247/255)

    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Event Banner
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Banner")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        if let image = viewModel.eventImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipped()
                                .cornerRadius(14)
                                .padding(.horizontal, 20)
                                .overlay(
                                    Button { viewModel.eventImage = nil } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                            .shadow(radius: 4)
                                    }.padding(28), alignment: .topTrailing
                                )
                        } else {
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 22))
                                        .foregroundColor(snuffyPink)
                                    Text("Add Event Banner")
                                        .font(.system(size: 15))
                                        .foregroundColor(snuffyPink)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Color.white)
                                .cornerRadius(14)
                                .padding(.horizontal, 20)
                            }
                            .onChange(of: photoPickerItem) { _, item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        viewModel.eventImage = ui
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Event Details
                    formSection("Event Details") {
                        formRow(label: "Title") {
                            TextField("e.g. Dog Show at Central Park", text: $viewModel.eventTitle)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.primary)
                        }
                        rowDivider
                        formRow(label: "Location") {
                            TextField("Venue or address", text: $viewModel.eventLocation)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.primary)
                        }
                        rowDivider
                        formRow(label: "Contact") {
                            TextField("Phone or email (optional)", text: $viewModel.eventContactInfo)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.primary)
                        }
                    }

                    // MARK: - Category Tag
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.availableEventTags, id: \.self) { tag in
                                    Button { viewModel.eventTag = tag } label: {
                                        Text(tag)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(viewModel.eventTag == tag ? .white : snuffyPink)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(
                                                viewModel.eventTag == tag
                                                ? snuffyPink
                                                : snuffyPink.opacity(0.1)
                                            )
                                            .cornerRadius(22)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // MARK: - Date & Time
                    formSection("Date & Time") {
                        HStack {
                            Text("Event Date")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $viewModel.eventDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(snuffyPink)
                            .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                    }

                    // MARK: - Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }

                    // MARK: - Create Button
                    Button {
                        viewModel.uploadEvent()
                    } label: {
                        Group {
                            if viewModel.isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Create Event", systemImage: "calendar.badge.plus")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(snuffyPink)
                        .cornerRadius(30)
                        .shadow(color: snuffyPink.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .disabled(viewModel.isUploading)
                }
                .padding(.top, 24)
            }
            .background(bgColor.ignoresSafeArea())
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
            .onChange(of: viewModel.didPost) { _, posted in
                if posted { viewModel.reset(); dismiss() }
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Section

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content() }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 20)
        }
    }

    private func formRow<Content: View>(label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 16)
    }
}
