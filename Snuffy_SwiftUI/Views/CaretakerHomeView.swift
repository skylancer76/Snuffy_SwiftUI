//
//  CaretakerHomeView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI
import Kingfisher

struct CaretakerHomeView: View {
    @StateObject private var viewModel = CaretakerHomeViewModel()
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Home")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    viewModel.shouldNavigateToProfile = true
                }) {
                    Circle()
                        .fill(snuffyPink)
                        .frame(width: 40, height: 40)
                        .shadow(color: snuffyPink.opacity(0.3), radius: 5, x: 0, y: 3)
                        .overlay(
                            Text(viewModel.userInitials)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)
            
            if viewModel.isLoading && viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Pending Requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.scheduleRequests, id: \.requestId) { request in
                            RequestCard(
                                petName: request.petName,
                                ownerName: request.userName,
                                breed: request.petBreed ?? "Breed Not Available",
                                duration: request.duration,
                                imageUrl: request.petImageUrl,
                                onAccept: {
                                    viewModel.acceptCaretakerRequest(request: request)
                                }
                            )
                        }
                        
                        ForEach(viewModel.dogWalkerRequests, id: \.requestId) { request in
                            RequestCard(
                                petName: request.petName,
                                ownerName: request.userName,
                                breed: request.petBreed ?? "Breed Not Available",
                                duration: request.duration,
                                imageUrl: request.petImageUrl,
                                onAccept: {
                                    viewModel.acceptDogWalkerRequest(request: request)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [snuffyPink.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .onAppear {
            viewModel.checkUserRoleAndFetchRequests()
            viewModel.fetchUserProfile()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitle("", displayMode: .inline)
        .fullScreenCover(isPresented: $viewModel.shouldNavigateToProfile) {
            // Need a shim for HomeViewModel if UserProfileView strictly requires it.
            // Let's create a proxy HomeViewModel or modify UserProfileView.
            // Actually, UserProfileView uses HomeViewModel for logout and initials.
            // I'll create a compat view.
            ProfileCompatibilityView(caretakerVM: viewModel)
        }
        .alert(item: Binding<AlertError?>(
            get: { viewModel.errorMessage.map { AlertError(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct RequestCard: View {
    let petName: String
    let ownerName: String
    let breed: String
    let duration: String
    let imageUrl: String?
    let onAccept: () -> Void
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            // Pet Image
            if let urlStr = imageUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image("DogPlaceholder")
                            .resizable()
                            .scaledToFill()
                    }
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .clipped()
            } else {
                Image("DogPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(petName)
                    .font(.system(size: 18, weight: .bold))
                
                Text(ownerName)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(breed)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(duration)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer(minLength: 8)
                
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(snuffyPink)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        CaretakerHomeView()
    }
}

// MARK: - Bridge to UserProfileView
struct ProfileCompatibilityView: View {
    @ObservedObject var caretakerVM: CaretakerHomeViewModel
    @StateObject private var homeVM = HomeViewModel()
    
    var body: some View {
        UserProfileView(viewModel: homeVM)
            .onAppear {
                homeVM.userName = caretakerVM.userName
                homeVM.userEmail = caretakerVM.userEmail
                homeVM.userInitials = caretakerVM.userInitials
            }
            .onChange(of: homeVM.shouldNavigateToLogin) { newValue in
                if newValue {
                    caretakerVM.logout()
                }
            }
    }
}
