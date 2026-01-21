//
//  DietDetailView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 21/01/26.
//

import SwiftUI

struct DietDetailView: View {
    let diet: PetDietDetails
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Main Info
                    VStack(spacing: 0) {
                        DetailRow(icon: "fork.knife", label: "Food Name", value: diet.foodName)
                        Divider()
                        DetailRow(icon: "tag", label: "Food Category", value: diet.foodCategory)
                        Divider()
                        DetailRow(icon: "clock", label: "Meal Type", value: diet.mealType)
                        Divider()
                        DetailRow(icon: "timer", label: "Serving Time", value: diet.servingTime)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIET DETAILS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                        
                        VStack(spacing: 0) {
                            DetailRow(icon: "scalemass", label: "Portion Size", value: diet.portionSize)
                            Divider()
                            DetailRow(icon: "repeat", label: "Frequency", value: diet.feedingFrequency)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Diet Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        // Delete logic here
                        dismiss()
                    }
                    .foregroundColor(snuffyPink)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DietDetailView(diet: PetDietDetails(
            dietId: "1",
            mealType: "Breakfast",
            foodName: "Royal Canin",
            foodCategory: "Dry Food",
            portionSize: "100g",
            feedingFrequency: "Daily",
            servingTime: "08:00 AM"
        ))
    }
}

