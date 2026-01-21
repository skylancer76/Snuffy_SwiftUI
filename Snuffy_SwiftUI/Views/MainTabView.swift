//
//  MainTabView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(selectedTab: $selectedTab)
                case 1:
                    Text("My Bookings Screen")
                case 2:
                    MyPetsView()
                default:
                    HomeView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Tab Bar
            HStack(spacing: 0) {
                TabButton(index: 0, icon: "heart.fill", label: "Home", selectedTab: $selectedTab, color: snuffyPink)
                TabButton(index: 1, icon: "doc.text.fill", label: "My Bookings", selectedTab: $selectedTab, color: snuffyPink)
                TabButton(index: 2, icon: "pawprint.fill", label: "My Pets", selectedTab: $selectedTab, color: snuffyPink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TabButton: View {
    let index: Int
    let icon: String
    let label: String
    @Binding var selectedTab: Int
    let color: Color
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == index ? color : Color.gray.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
}
