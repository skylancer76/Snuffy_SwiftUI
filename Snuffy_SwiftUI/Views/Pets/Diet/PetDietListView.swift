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
                    VStack(spacing: 16) {
                        ForEach(viewModel.diets, id: \.dietId) { diet in
                            NavigationLink(destination: DietDetailView(diet: diet)) {
                                DietRow(diet: diet)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Diet Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shouldShowAddDiet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(snuffyPink)
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowAddDiet) {
            AddPetDietView(petId: petId)
        }
    }
}

struct DietRow: View {
    let diet: PetDietDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "fork.knife")
                    .foregroundColor(snuffyPink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(diet.foodName)
                    .font(.headline)
                HStack {
                    Text(diet.mealType)
                        .font(.subheadline)
                        .foregroundColor(snuffyPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(snuffyPink.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("at \(diet.servingTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text("\(diet.portionSize) (\(diet.feedingFrequency))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        PetDietListView(petId: "sample")
    }
}
