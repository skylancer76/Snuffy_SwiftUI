import SwiftUI
import Combine

struct AddPetMedicationView: View {
    let petId: String
    @StateObject private var viewModel: AddPetMedicationViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: AddPetMedicationViewModel(petId: petId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Medication Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medication Details")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            FormRow(label: "Medicine Name", value: $viewModel.medicineName, placeholder: "e.g. Amoxicillin")
                            
                            Divider().padding(.leading, 16)
                            
                            Menu {
                                ForEach(viewModel.medicineTypes, id: \.self) { type in
                                    Button(type) {
                                        viewModel.medicineType = type
                                    }
                                }
                            } label: {
                                SelectionRow(label: "Medicine Type", value: viewModel.medicineType)
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Purpose", value: $viewModel.purpose, placeholder: "e.g. Infection treatment")
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Frequency", value: $viewModel.frequency, placeholder: "e.g. Twice daily")
                            
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Dosage", value: $viewModel.dosage, placeholder: "e.g. 250mg")
                            
                            Divider().padding(.leading, 16)
                            
                            HStack {
                                Text("Start Date")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(snuffyPink)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.white)
                            
                            Divider().padding(.leading, 16)
                            
                            HStack {
                                Text("End Date")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
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
                    
                    // Add Medication Button
                    Button(action: {
                        viewModel.saveMedication()
                    }) {
                        Text("Add Medication")
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
        .navigationTitle("Add Medication")
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
