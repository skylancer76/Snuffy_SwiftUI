//
//  MainTabView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham on 19/01/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var roleVM = UserRoleViewModel()
    @Namespace private var tabAnimation
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var isCaregiver: Bool {
        roleVM.role == .caretaker || roleVM.role == .dogWalker
    }

    var body: some View {
        if roleVM.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack(alignment: .bottom) {
                // Main Content
                Group {
                    if isCaregiver {
                        // MARK: Caregiver Entry Blocker
                        if !roleVM.isProfileComplete {
                            // Step 1 — New caregiver: collect profile details
                            NavigationStack {
                                CaretakerOnboardingView(role: roleVM.role, roleVM: roleVM)
                            }
                        } else if !roleVM.isVerified {
                            // Step 2 — Profile submitted: wait for admin approval
                            NavigationStack {
                                WaitingListView(roleVM: roleVM)
                            }
                        } else {
                            // Step 3 — Approved: show normal caregiver home
                            switch selectedTab {
                            case 0:
                                NavigationStack { CaretakerHomeView() }
                            case 1:
                                NavigationStack { CaregiverBookingsView() }
                            default:
                                NavigationStack { CaretakerHomeView() }
                            }
                        }
                    } else {
                        switch selectedTab {
                        case 0:
                            HomeView(selectedTab: $selectedTab)
                        case 1:
                            MyBookingsView()
                        case 2:
                            MyPetsView()
                        case 3:
                            NavigationStack {
                                CommunityView()
                            }
                        default:
                            HomeView(selectedTab: $selectedTab)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating Tab Bar — hidden during onboarding / waitlist
                if showTabBar {
                    HStack(spacing: 0) {
                        ForEach(currentTabItems.indices, id: \.self) { i in
                            let item = currentTabItems[i]
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
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(.spring(response: 0.35), value: showTabBar)
        }
    }

    private var currentTabItems: [(icon: String, label: String)] {
        if isCaregiver {
            return [
                ("house.fill",          "Home"),
                ("list.clipboard.fill", "Bookings")
            ]
        } else {
            return [
                ("heart.fill",          "Home"),
                ("list.clipboard.fill", "My Bookings"),
                ("pawprint.fill",       "My Pets"),
                ("person.3.fill",       "Community")
            ]
        }
    }

    /// The floating tab bar is hidden while a caregiver is still
    /// in the onboarding or waiting-for-approval flow.
    private var showTabBar: Bool {
        if isCaregiver {
            return roleVM.isProfileComplete && roleVM.isVerified
        }
        return true
    }
}

// MARK: - Role-Aware Tab View (for Caretakers & DogWalkers)
struct CaregiverMainTabView: View {
    @State private var selectedTab = 0
    @Namespace private var tabAnimation
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        CaretakerHomeView()
                    }
                case 1:
                    NavigationStack {
                        CaregiverBookingsView()
                    }
                default:
                    NavigationStack {
                        CaretakerHomeView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(caregiverTabItems.indices, id: \.self) { i in
                    let item = caregiverTabItems[i]
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
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var caregiverTabItems: [(icon: String, label: String)] = [
        ("house.fill",          "Home"),
        ("list.clipboard.fill", "Bookings")
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
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isSelected ? color : Color(.black))
            .padding(.vertical, 7)
            .padding(.horizontal, 4)
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
