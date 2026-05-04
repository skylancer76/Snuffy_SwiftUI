//
//  FindingProviderOverlay.swift
//  Snuffy_SwiftUI
//

import SwiftUI

/// Full-screen overlay shown over a booking-info screen while the request is
/// still in the "Requested" state — i.e. the caretaker / dog walker hasn't
/// accepted yet. Renders an animated magnifying-glass icon plus a localized
/// "Finding you a suitable …" message.
struct FindingProviderOverlay: View {
    enum Provider {
        case caretaker
        case dogWalker

        var label: String {
            switch self {
            case .caretaker: return "caretaker"
            case .dogWalker: return "dog walker"
            }
        }
    }

    let provider: Provider

    @State private var pulse: Bool = false
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0.6

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            // Frosted backdrop on top of the blurred booking content
            Color.black.opacity(0.05).ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    // Expanding outer ring
                    Circle()
                        .stroke(snuffyPink.opacity(ringOpacity), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)

                    // Soft pink halo
                    Circle()
                        .fill(snuffyPink.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    // Solid pink core with the search icon
                    Circle()
                        .fill(snuffyPink)
                        .frame(width: 78, height: 78)
                        .shadow(color: snuffyPink.opacity(0.45), radius: 14, x: 0, y: 6)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(pulse ? 8 : -8))
                }
                .frame(width: 160, height: 160)

                VStack(spacing: 8) {
                    Text("Finding you a suitable \(provider.label)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    Text("We'll unlock the booking details as soon as the service provider accepts your request.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulse = true
        }
        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
            ringScale = 1.25
            ringOpacity = 0.0
        }
    }
}

#Preview {
    FindingProviderOverlay(provider: .caretaker)
}
