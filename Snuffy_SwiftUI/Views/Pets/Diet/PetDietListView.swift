//
//  PetDietListView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI

struct PetDietListView: View {
    let petId: String
    @StateObject private var viewModel: PetDietViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    @Environment(\.dismiss) var dismiss
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetDietViewModel(petId: petId))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Diet Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.shouldShowAddDiet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(snuffyPink)
                            .clipShape(Circle())
                            .shadow(color: snuffyPink.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
                
                if viewModel.isLoading && viewModel.diets.isEmpty {
                    ProgressView()
                        .tint(snuffyPink)
                } else if viewModel.diets.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(snuffyPink.opacity(0.15))
                                .frame(width: 110, height: 110)
                            Image(systemName: "fork.knife")
                                .font(.system(size: 46))
                                .foregroundColor(snuffyPink)
                        }
                        Text("No diet plan yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Every great meal plan starts with one entry.\nAdd your pet's first diet!")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.diets, id: \.dietId) { diet in
                                NavigationLink(destination: DietDetailView(diet: diet)) {
                                    DietRow(diet: diet)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                }
                
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.shouldShowAddDiet) {
                NavigationStack {
                    AddPetDietView(petId: petId)
                }
            }
        }
    }
    
    struct DietRow: View {
        let diet: PetDietDetails
        private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
        
        private var mealIcon: String {
            switch diet.mealType.lowercased() {
            case "breakfast": return "sunrise.fill"
            case "lunch": return "sun.max.fill"
            case "dinner": return "moon.fill"
            case "snack": return "leaf.fill"
            default: return "fork.knife"
            }
        }
        
        var body: some View {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(snuffyPink.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: mealIcon)
                        .font(.system(size: 22))
                        .foregroundColor(snuffyPink)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(diet.foodName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        // Meal type badge
                        Text(diet.mealType)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(snuffyPink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(snuffyPink.opacity(0.12))
                            .cornerRadius(6)
                        
                        // Category badge
                        Text(diet.foodCategory)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Text(diet.portionSize)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Text(diet.servingTime)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Text(diet.feedingFrequency)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }
}
