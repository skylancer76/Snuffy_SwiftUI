//
//  CreatePostView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import PhotosUI
import AVKit

struct CreatePostView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var videoPickerItem: PhotosPickerItem?
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [snuffyPink.opacity(0.18), Color.white],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Media Type Picker
                        Picker("", selection: $viewModel.selectedMediaType) {
                            Text("📝 Text").tag(CommunityMediaType.text)
                            Text("🖼 Image").tag(CommunityMediaType.image)
                            Text("🎬 Video").tag(CommunityMediaType.video)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // MARK: - Caption
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Caption")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)

                            TextEditor(text: $viewModel.caption)
                                .font(.system(size: 15))
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .focused($captionFocused)
                                .padding(.horizontal, 20)
                        }

                        // MARK: - Image Picker
                        if viewModel.selectedMediaType == .image {
                            if let image = viewModel.selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                    .onTapGesture { viewModel.selectedImage = nil }
                            } else {
                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                    mediaPickerPlaceholder(icon: "photo", label: "Tap to select photo")
                                }
                                .padding(.horizontal, 20)
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

                        // MARK: - Video Picker
                        if viewModel.selectedMediaType == .video {
                            if let videoURL = viewModel.selectedVideoURL {
                                VideoPlayer(player: AVPlayer(url: videoURL))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                            } else {
                                PhotosPicker(selection: $videoPickerItem, matching: .videos) {
                                    mediaPickerPlaceholder(icon: "video", label: "Tap to select video")
                                }
                                .padding(.horizontal, 20)
                                .onChange(of: videoPickerItem) { _, item in
                                    Task {
                                        if let url = try? await item?.loadTransferable(type: URL.self) {
                                            viewModel.selectedVideoURL = url
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
                                    .padding(.horizontal, 20)
                                Text("Uploading… \(Int(viewModel.uploadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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
                            HStack {
                                if viewModel.isUploading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Share")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(16)
                            .shadow(color: snuffyPink.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .disabled(viewModel.isUploading)
                    }
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(snuffyPink)
                }
            }
            .onChange(of: viewModel.didPost) { _, posted in
                if posted { viewModel.reset(); dismiss() }
            }
        }
    }

    private func mediaPickerPlaceholder(icon: String, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(snuffyPink)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(snuffyPink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(snuffyPink.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(snuffyPink.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
    }
}
