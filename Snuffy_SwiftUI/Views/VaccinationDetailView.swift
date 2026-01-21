//
//  VaccinationDetailView.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 21/01/26.
//

import SwiftUI

struct VaccinationDetailView: View {
    let vaccination: VaccinationDetails
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
                    // Info Section
                    VStack(spacing: 0) {
                        DetailRow(icon: "syringe.fill", label: "Vaccine Name", value: vaccination.vaccineName)
                        Divider()
                        DetailRow(icon: "calendar", label: "Date of Vaccine", value: vaccination.dateOfVaccination)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Expiry Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXPIRY INFO")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                        
                        VStack(spacing: 0) {
                            DetailRow(icon: "calendar.badge.exclamationmark", label: "Expires", value: vaccination.expires ? "Yes" : "No")
                            if vaccination.expires, let expiryDate = vaccination.expiryDate {
                                Divider()
                                DetailRow(icon: "calendar", label: "Expiry Date", value: expiryDate)
                            }
                            Divider()
                            ToggleRow(icon: "bell.fill", label: "Notify upon expiry", isOn: .constant(true))
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    // Notes Section
                    if let notes = vaccination.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NOTES")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                            
                            VStack(alignment: .leading) {
                                Text(notes)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Vaccination Details")
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
        VaccinationDetailView(vaccination: VaccinationDetails(
            vaccineId: "1",
            vaccineName: "Distemper",
            dateOfVaccination: "22/01/26",
            expires: true,
            expiryDate: "21/01/26",
            notifyUponExpiry: true,
            notes: "Routine vaccination"
        ))
    }
}
