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
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Diet Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Diet Details")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
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
                            
                            FormRow(label: "Food Name", value: $viewModel.foodName, placeholder: "e.g. Chicken & Rice")
                            
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
                            
                            FormRow(label: "Portion Size", value: $viewModel.portionSize, placeholder: "e.g. 2/3 cup")
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Feeding Frequency", value: $viewModel.feedingFrequency, placeholder: "e.g. Twice daily")
                            
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
                            .background(Color.white)
                        }
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Add Diet Button
                    Button(action: {
                        viewModel.saveDiet()
                    }) {
                        Text("Add Diet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical, 24)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
            }
        }
        .navigationTitle("Add Diet")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
