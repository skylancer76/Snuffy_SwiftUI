//
//  AddAnnouncementView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI

struct AddAnnouncementView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [snuffyPink.opacity(0.18), Color.white],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    // Icon + description
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(snuffyPink.opacity(0.12))
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 22))
                                .foregroundColor(snuffyPink)
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Community Announcement")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Visible to all community members")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if viewModel.announcementText.isEmpty {
                            Text("Write your announcement here…")
                                .font(.system(size: 15))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                        }
                        TextEditor(text: $viewModel.announcementText)
                            .font(.system(size: 15))
                            .frame(minHeight: 150)
                            .padding(10)
                            .focused($isFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .onAppear { isFocused = true }

                    // Character count
                    HStack {
                        Spacer()
                        Text("\(viewModel.announcementText.count) characters")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.trailing, 22)
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error).font(.system(size: 13)).foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Post button
                    Button {
                        isFocused = false
                        viewModel.addAnnouncement()
                    } label: {
                        HStack {
                            if viewModel.isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "megaphone.fill")
                                Text("Post Announcement")
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
                    .disabled(viewModel.isUploading
                              || viewModel.announcementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Announcement")
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
}
