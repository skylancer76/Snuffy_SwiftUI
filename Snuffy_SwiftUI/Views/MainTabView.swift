//
//  MainTabView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham on 19/01/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Namespace private var tabAnimation
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(selectedTab: $selectedTab)
                case 1:
                    MyBookingsView()
                case 2:
                    MyPetsView()
                default:
                    HomeView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Tab Bar
            HStack(spacing: 0) {
                ForEach(tabItems.indices, id: \.self) { i in
                    let item = tabItems[i]
                    TabButton(
                        index: i,
                        icon: item.icon,
                        label: item.label,
                        selectedTab: $selectedTab,
                        color: snuffyPink,
                        namespace: tabAnimation
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var tabItems: [(icon: String, label: String)] = [
        ("heart.fill",          "Home"),
        ("list.clipboard.fill", "My Bookings"),
        ("pawprint.fill",       "My Pets")
    ]
}

struct TabButton: View {
    let index: Int
    let icon: String
    let label: String
    @Binding var selectedTab: Int
    let color: Color
    var namespace: Namespace.ID

    var isSelected: Bool { selectedTab == index }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? color : Color(.black))
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(color.opacity(0.2), lineWidth: 0.8)
                        )
                        .matchedGeometryEffect(id: "TAB_BG", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
