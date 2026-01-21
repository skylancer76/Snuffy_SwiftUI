//
//  GetStartedView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 06/01/26.
//

import SwiftUI

struct GetStartedView: View {
    @StateObject private var viewModel = GetStartedViewModel()
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                

                Text("Welcome to Snuffy")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 60)
                

                VStack(alignment: .leading, spacing: 40) {
                    FeatureRow(
                        icon: "person.2.fill",
                        iconColor: snuffyPink,
                        title: "Find the best Caretakers",
                        description: "Now you can find the best caretakers for your pets near you."
                    )
                    
                    FeatureRow(
                        icon: "pawprint.fill",
                        iconColor: snuffyPink,
                        title: "Dog walks made easy",
                        description: "Your one step solution for your dogs routine walks."
                    )
                    
                    FeatureRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: snuffyPink,
                        title: "Pet care updates",
                        description: "Keep a Track of all your pet updates while they are away from you."
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    viewModel.handleGetStarted()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(snuffyPink)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                UserLoginView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    GetStartedView()
}
