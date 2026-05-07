//
//  UserProfileView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 13/01/26.
//


import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let helpURL = URL(string: "https://snuffy-website.vercel.app/")!
    private let dataPolicyURL = URL(string: "https://snuffy-website.vercel.app/security")!
    
    var body: some View {
        ZStack {
            // Background gradient matching HomeView
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Back button)
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // MARK: - Profile Picture + Name
                        VStack(spacing: 14) {
                            // Profile picture with upload
                            ZStack(alignment: .bottomTrailing) {
                                if viewModel.isUploadingProfilePic {
                                    Circle()
                                        .fill(snuffyPink.opacity(0.15))
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            ProgressView()
                                                .tint(snuffyPink)
                                        )
                                } else if let urlString = viewModel.profilePicURL,
                                          !urlString.isEmpty,
                                          let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                        case .failure:
                                            initialsAvatar
                                        case .empty:
                                            Circle()
                                                .fill(snuffyPink.opacity(0.15))
                                                .frame(width: 110, height: 110)
                                                .overlay(ProgressView().tint(snuffyPink))
                                        @unknown default:
                                            initialsAvatar
                                        }
                                    }
                                } else {
                                    initialsAvatar
                                }
                                
                                // Camera overlay button
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(snuffyPink)
                                            .frame(width: 34, height: 34)
                                            .shadow(color: snuffyPink.opacity(0.4), radius: 4, x: 0, y: 2)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(x: 2, y: 2)
                            }
                            
                            // User name
                            Text(viewModel.userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        
                        // MARK: - Info Card (Email + Member Since)
                        VStack(spacing: 0) {
                            // Email Row
                            HStack(spacing: 16) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(snuffyPink)
                                    .frame(width: 24, alignment: .center)
                                
                                Text(viewModel.userEmail)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Member Since Row
                            HStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18))
                                    .foregroundColor(snuffyPink)
                                    .frame(width: 24, alignment: .center)
                                
                                Text("Member since")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(viewModel.memberSince.isEmpty ? "—" : viewModel.memberSince)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Settings Card (Push Notifications, Help, Data)
                        VStack(spacing: 0) {
                            // Push Notifications
                            HStack(spacing: 16) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(snuffyPink)
                                    .frame(width: 24, alignment: .center)
                                
                                Text("Push Notifications")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("Coming soon")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Help
                            Button(action: { openURL(helpURL) }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(snuffyPink)
                                        .frame(width: 24, alignment: .center)

                                    Text("Help")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }

                            Divider()
                                .padding(.leading, 56)

                            // See how your data is managed
                            Button(action: { openURL(dataPolicyURL) }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 18))
                                        .foregroundColor(snuffyPink)
                                        .frame(width: 24, alignment: .center)

                                    Text("See how your data is managed")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Sign Out
                        Button(action: {
                            viewModel.logout()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Sign Out")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(snuffyPink.opacity(0.12))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // MARK: - Delete Account
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: 10) {
                                if viewModel.isDeletingAccount {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                } else {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                Text("Delete Account")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isDeletingAccount)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.uploadProfilePicture(image)
                }
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
        } message: {
            Text("This permanently removes your profile, pets, bookings, and history from Snuffy. This action cannot be undone.")
        }
        .alert(
            "Couldn't delete account",
            isPresented: Binding(
                get: { viewModel.deleteAccountError != nil },
                set: { if !$0 { viewModel.deleteAccountError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.deleteAccountError = nil }
        } message: {
            Text(viewModel.deleteAccountError ?? "")
        }
    }
    
    // MARK: - Initials Avatar
    private var initialsAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [snuffyPink.opacity(0.6), snuffyPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 110, height: 110)
            .overlay(
                Text(viewModel.userInitials)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: snuffyPink.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(viewModel: HomeViewModel())
    }
}
