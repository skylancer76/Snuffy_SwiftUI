//
//  AddPetDietView.swift
//  Snuffy_SwiftUI
//

import SwiftUI

struct AddPetDietView: View {
    let petId: String
    @StateObject private var viewModel: AddPetDietViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: AddPetDietViewModel(petId: petId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(snuffyPink)
                
                Spacer()
                
                Text("Add Diet")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveDiet()
                }
                .foregroundColor(snuffyPink)
                .bold()
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Diet Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIET DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        
                        VStack(spacing: 0) {
                            Menu {
                                ForEach(viewModel.mealTypes, id: \.self) { type in
                                    Button(type) {
                                        viewModel.mealType = type
                                    }
                                }
                            } label: {
                                SelectionRow(label: "Meal Type", value: viewModel.mealType)
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Food Name", value: $viewModel.foodName, placeholder: "Value")
                            
                            Divider().padding(.leading, 16)
                            
                            Menu {
                                ForEach(viewModel.foodCategories, id: \.self) { type in
                                    Button(type) {
                                        viewModel.foodCategory = type
                                    }
                                }
                            } label: {
                                SelectionRow(label: "Food Category", value: viewModel.foodCategory)
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Portion Size", value: $viewModel.portionSize, placeholder: "Value")
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Feeding Frequency", value: $viewModel.feedingFrequency, placeholder: "Value")
                            
                            Divider().padding(.leading, 16)
                            
                            HStack {
                                Text("Serving Time")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $viewModel.servingTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(snuffyPink)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                dismiss()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
