import SwiftUI

struct PetMedicationListView: View {
    let petId: String
    @StateObject private var viewModel: PetMedicationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    @Environment(\.dismiss) var dismiss
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetMedicationViewModel(petId: petId))
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
                    
                    Text("Medication Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.shouldShowAddMedication = true
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
                
                if viewModel.isLoading && viewModel.medications.isEmpty {
                    ProgressView()
                        .tint(snuffyPink)
                } else if viewModel.medications.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(snuffyPink.opacity(0.15))
                                .frame(width: 110, height: 110)
                            Image(systemName: "pills.fill")
                                .font(.system(size: 46))
                                .foregroundColor(snuffyPink)
                        }
                        Text("No medications yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Nothing prescribed yet.\nAdd a medication to track your pet's treatment.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.medications, id: \.medicationId) { medication in
                                NavigationLink(destination: MedicationDetailView(medication: medication)) {
                                    MedicationRow(medication: medication)
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
            .sheet(isPresented: $viewModel.shouldShowAddMedication) {
                NavigationStack {
                    AddPetMedicationView(petId: petId)
                }
            }
        }
    }
    
    struct MedicationRow: View {
        let medication: PetMedicationDetails
        private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
        
        private var typeIcon: String {
            switch medication.medicineType.lowercased() {
            case "tablet": return "pills.fill"
            case "syrup", "liquid": return "drop.fill"
            case "injection": return "syringe.fill"
            case "ointment", "cream": return "bandage.fill"
            case "drops": return "drop.triangle.fill"
            default: return "cross.vial.fill"
            }
        }
        
        var body: some View {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(snuffyPink.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: typeIcon)
                        .font(.system(size: 22))
                        .foregroundColor(snuffyPink)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(medication.medicineName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(medication.purpose)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Dosage badge
                        HStack(spacing: 4) {
                            Image(systemName: "pill.fill")
                                .font(.system(size: 10))
                            Text(medication.dosage)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(snuffyPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(snuffyPink.opacity(0.12))
                        .cornerRadius(6)
                        
                        // Frequency badge
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 10))
                            Text(medication.frequency)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text("\(medication.startDate) – \(medication.endDate)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
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
