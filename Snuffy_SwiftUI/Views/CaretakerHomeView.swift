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
    
    @State private var selectedDay = 15 // Default selected day for mock calendar
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // 1. Banner Section
                    Image("Home Screen Banner")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(25)
                        .padding(.horizontal, 20)
                    
                    // 2. Upcoming Bookings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Bookings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        if viewModel.isLoading && viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                            ProgressView()
                                .padding(.vertical, 30)
                                .frame(maxWidth: .infinity)
                        } else if viewModel.scheduleRequests.isEmpty && viewModel.dogWalkerRequests.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No Upcoming Bookings")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
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
                                        .frame(width: 320)
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
                                        .frame(width: 320)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10) // padding to avoid shadow clipping
                            }
                        }
                    }
                    
                    // 3. Calendar Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Schedule")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(1...30, id: \.self) { day in
                                    CalendarDayView(day: day, isSelected: day == selectedDay)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedDay = day
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                    }
                    
                    // 4. Articles Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("For Caretakers")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            ArticleCard(
                                category: "WELLNESS",
                                title: "10 Tips for Calming Anxious Pets",
                                readTime: "4 min read",
                                iconName: "heart.text.square.fill",
                                iconColor: Color.orange
                            )
                            ArticleCard(
                                category: "SAFETY",
                                title: "Recognizing Signs of Heatstroke in Dogs",
                                readTime: "6 min read",
                                iconName: "thermometer.sun.fill",
                                iconColor: Color.red
                            )
                            ArticleCard(
                                category: "BUSINESS",
                                title: "Perfecting the Meet & Greet",
                                readTime: "5 min read",
                                iconName: "hand.wave.fill",
                                iconColor: Color.blue
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
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

struct CalendarDayView: View {
    let day: Int
    let isSelected: Bool
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayOfWeek(day: day))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
            
            Text("\(day)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isSelected ? .white : .black)
            
            // Mock busy/free dot
            Circle()
                .fill(isSelected ? .white : (day % 3 == 0 ? snuffyPink : Color.clear))
                .frame(width: 4, height: 4)
        }
        .frame(width: 50, height: 75)
        .background(isSelected ? snuffyPink : Color.white)
        .cornerRadius(20)
        .shadow(color: isSelected ? snuffyPink.opacity(0.4) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    private func dayOfWeek(day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[(day - 1) % 7]
    }
}

struct ArticleCard: View {
    let category: String
    let title: String
    let readTime: String
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(iconColor)
                    .tracking(1)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(readTime)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
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
