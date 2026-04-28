//
//  CreatePostView.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma 

import SwiftUI
import PhotosUI
import AVKit

struct CreatePostView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor    = Color(red: 242/255, green: 242/255, blue: 247/255)

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var videoPickerItem: PhotosPickerItem?
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Post Type
                    formSection("Post Type") {
                        Picker("", selection: $viewModel.selectedMediaType) {
                            Text("Text").tag(CommunityMediaType.text)
                            Text("Image").tag(CommunityMediaType.image)
                            Text("Video").tag(CommunityMediaType.video)
                        }
                        .pickerStyle(.segmented)
                        .tint(snuffyPink)
                        .padding(16)
                    }

                    // MARK: - Caption
                    formSection("Caption") {
                        ZStack(alignment: .topLeading) {
                            if viewModel.caption.isEmpty {
                                Text("What's on your mind?")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 14)
                            }
                            TextEditor(text: $viewModel.caption)
                                .font(.system(size: 15))
                                .frame(minHeight: 120)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                                .focused($captionFocused)
                        }
                    }

                    // MARK: - Media
                    if viewModel.selectedMediaType == .image {
                        formSection("Photo") {
                            if let image = viewModel.selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .padding(12)
                                    .overlay(
                                        Button { viewModel.selectedImage = nil } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                                .shadow(radius: 4)
                                        }.padding(20), alignment: .topTrailing
                                    )
                            } else {
                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                    mediaPlaceholder(icon: "photo", label: "Tap to add photo")
                                }
                                .onChange(of: photoPickerItem) { _, item in
                                    Task {
                                        if let data = try? await item?.loadTransferable(type: Data.self),
                                           let ui = UIImage(data: data) {
                                            viewModel.selectedImage = ui
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if viewModel.selectedMediaType == .video {
                        formSection("Video") {
                            if let videoURL = viewModel.selectedVideoURL {
                                VideoPlayer(player: AVPlayer(url: videoURL))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .padding(12)
                            } else {
                                PhotosPicker(selection: $videoPickerItem, matching: .videos) {
                                    mediaPlaceholder(icon: "video", label: "Tap to add video")
                                }
                                .onChange(of: videoPickerItem) { _, item in
                                    Task {
                                        if let url = try? await item?.loadTransferable(type: URL.self) {
                                            viewModel.selectedVideoURL = url
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Upload Progress
                    if viewModel.isUploading && viewModel.uploadProgress > 0 {
                        VStack(spacing: 6) {
                            ProgressView(value: viewModel.uploadProgress)
                                .tint(snuffyPink)
                            Text("Uploading \(Int(viewModel.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: - Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }

                    // MARK: - Share Button
                    Button {
                        captionFocused = false
                        viewModel.uploadPost()
                    } label: {
                        Group {
                            if viewModel.isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Share Post", systemImage: "paperplane.fill")
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
            .navigationTitle("Create Post")
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

    // MARK: - Media Placeholder

    private func mediaPlaceholder(icon: String, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(snuffyPink)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(snuffyPink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(snuffyPink.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .padding(12)
        )
    }
}
