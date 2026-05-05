//
//  WaitingListView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 21/01/26.
//

import SwiftUI
import Combine
import FirebaseAuth

struct WaitingListView: View {

    @ObservedObject var roleVM: UserRoleViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    // Auto-refresh every 60 s so user lands on Home as soon as admin approves
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [snuffyPink.opacity(0.18), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back Button
                HStack {
                    Button(action: {
                        try? Auth.auth().signOut()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()

                // Paw animation
                ZStack {
                    Circle()
                        .fill(snuffyPink.opacity(0.12))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(snuffyPink.opacity(0.08))
                        .frame(width: 120, height: 120)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [snuffyPink, snuffyPink.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse)
                }
                .padding(.bottom, 36)

                // Heading
                Text("You're on the Waitlist!")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)

                Text("We've received your application and our team is reviewing your profile. We'll get back to you shortly!")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 40)

                // Status card
                VStack(spacing: 16) {
                    statusRow(icon: "checkmark.circle.fill",
                              color: .green,
                              label: "Profile submitted",
                              done: true)
                    statusDivider
                    statusRow(icon: "person.badge.clock.fill",
                              color: snuffyPink,
                              label: "Admin review in progress",
                              done: false)
                    statusDivider
                    statusRow(icon: "house.fill",
                              color: .gray,
                              label: "Access granted",
                              done: false)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 4)
                .padding(.horizontal, 28)

                Spacer()

                // Refresh hint
                VStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text("This screen refreshes automatically.\nYou'll be taken to the home screen once approved.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            roleVM.refresh()
        }
    }

    // MARK: - Helpers
    private var statusDivider: some View {
        HStack {
            Spacer().frame(width: 24)
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 2, height: 20)
            Spacer()
        }
    }

    private func statusRow(icon: String, color: Color, label: String, done: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(done ? color : color.opacity(0.5))
            Text(label)
                .font(.system(size: 14, weight: done ? .semibold : .regular))
                .foregroundColor(done ? .primary : .secondary)
            Spacer()
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    WaitingListView(roleVM: UserRoleViewModel())
}
