//
//  MyPetsView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 19/01/26.
//

import SwiftUI

struct MyPetsView: View {
    @StateObject private var viewModel = MyPetsViewModel()
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [snuffyPink.opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {

                    HStack(alignment: .center) {
                        Text("My Pets")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button {
                            viewModel.shouldShowAddPet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(snuffyPink)
                                .clipShape(Circle())
                                .shadow(color: snuffyPink.opacity(0.4), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 15)
                    
                    if viewModel.isLoading && viewModel.pets.isEmpty {
                        Spacer()
                        ProgressView("Loading your pets...")
                            .tint(snuffyPink)
                        Spacer()
                    } else if viewModel.pets.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "pawprint.circle")
                                .font(.system(size: 80))
                                .foregroundColor(snuffyPink.opacity(0.5))
                            Text("No pets added yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(viewModel.pets) { pet in
                                    PetCardView(pet: pet)
                                        .onTapGesture {
                                            viewModel.selectedPet = pet
                                            viewModel.shouldNavigateToPetProfile = true
                                        }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 100) // Extra padding for floating bar
                        }
                    }
                }
                
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPetProfile) {
                if let pet = viewModel.selectedPet {
                    PetProfileView(petId: pet.petId)
                }
            }
            .sheet(isPresented: $viewModel.shouldShowAddPet) {
                AddPetView()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct AddPetButtonCard: View {
    let action: () -> Void
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(snuffyPink)
                Text("Add Pet")
                    .font(.subheadline)
                    .foregroundColor(snuffyPink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(snuffyPink.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(snuffyPink.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
        }
    }
}

#Preview {
    MyPetsView()
}
