//
//  MedicationDetailView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 21/01/26.
//

import SwiftUI

struct MedicationDetailView: View {
    let medication: PetMedicationDetails
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
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        DetailRow(icon: "pills.fill", label: "Medicine Name", value: medication.medicineName)
                        Divider()
                        DetailRow(icon: "tag", label: "Medicine Type", value: medication.medicineType)
                        Divider()
                        DetailRow(icon: "heart.text.square", label: "Purpose", value: medication.purpose)
                        Divider()
                        DetailRow(icon: "number", label: "Dosage", value: medication.dosage)
                        Divider()
                        DetailRow(icon: "repeat", label: "Frequency", value: medication.frequency)
                        Divider()
                        DetailRow(icon: "calendar", label: "Start Date", value: medication.startDate)
                        Divider()
                        DetailRow(icon: "calendar", label: "End Date", value: medication.endDate)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Medication Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete") {
                    dismiss()
                }
                .foregroundColor(snuffyPink)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MedicationDetailView(medication: PetMedicationDetails(
            medicationId: "1",
            medicineName: "NexGard",
            medicineType: "Tablet",
            purpose: "Flea and Tick Prevention",
            frequency: "Monthly",
            dosage: "1 Tablet",
            startDate: "01/01/26",
            endDate: "01/06/26"
        ))
    }
}
