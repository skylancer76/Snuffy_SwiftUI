//
//  RequestScheduledView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI

struct RequestScheduledView: View {
    @Environment(\.dismiss) var dismiss
    @State private var rotationAngle: Double = 0
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Rotating Seal Icon
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(snuffyPink)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false)
                        ) {
                            rotationAngle = 360
                        }
                    }
                
                VStack(spacing: 16) {
                    Text("Booking Request Sent")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Your request has been sent! ❤️ Sit tight while we review and accept your booking.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Okay Button
                Button(action: {
                    navigateToHome()
                }) {
                    Text("Okay")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(snuffyPink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func navigateToHome() {
        // Navigate back to home tab
        // This will need to be handled by the parent TabView
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Reset to tab bar and select home tab
            // You'll need to handle this based on your app structure
            dismiss()
        }
    }
}

#Preview {
    RequestScheduledView()
}
