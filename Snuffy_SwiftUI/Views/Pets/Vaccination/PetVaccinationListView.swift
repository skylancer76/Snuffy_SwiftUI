//
//  PetVaccinationListView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI

struct PetVaccinationListView: View {
    let petId: String
    @StateObject private var viewModel: PetVaccinationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    @Environment(\.dismiss) var dismiss
    
    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetVaccinationViewModel(petId: petId))
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
                    
                    Text("Vaccination Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.shouldShowAddVaccine = true
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
                
                if viewModel.isLoading && viewModel.vaccinations.isEmpty {
                    ProgressView()
                        .tint(snuffyPink)
                } else if viewModel.vaccinations.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(snuffyPink.opacity(0.15))
                                .frame(width: 110, height: 110)
                            Image(systemName: "syringe.fill")
                                .font(.system(size: 46))
                                .foregroundColor(snuffyPink)
                        }
                        Text("No vaccinations yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Keep your pet healthy!\nAdd their first vaccination record.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.vaccinations, id: \.vaccineId) { vaccination in
                                NavigationLink(destination: VaccinationDetailView(vaccination: vaccination)) {
                                    VaccinationRow(vaccination: vaccination)
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
            .sheet(isPresented: $viewModel.shouldShowAddVaccine) {
                NavigationStack {
                    AddPetVaccinationView(petId: petId)
                }
            }
        }
    }
    
    struct VaccinationRow: View {
        let vaccination: VaccinationDetails
        private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
        
        private var isExpired: Bool {
            guard vaccination.expires, let expiryStr = vaccination.expiryDate else { return false }
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            guard let expiryDate = formatter.date(from: expiryStr) else { return false }
            return expiryDate < Date()
        }
        
        var body: some View {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(snuffyPink.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 22))
                        .foregroundColor(snuffyPink)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(vaccination.vaccineName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(vaccination.dateOfVaccination)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if vaccination.expires, let expiry = vaccination.expiryDate {
                        HStack(spacing: 6) {
                            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "clock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(isExpired ? .red : .orange)
                            Text(isExpired ? "Expired \(expiry)" : "Expires \(expiry)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isExpired ? .red : .orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((isExpired ? Color.red : Color.orange).opacity(0.1))
                        .cornerRadius(6)
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
