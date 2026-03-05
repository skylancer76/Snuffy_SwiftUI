//
//  CaregiverPetProfileView.swift
//  Snuffy_SwiftUI
//
//  Read-only pet profile for caregivers (caretakers & dog walkers).
//  Each row navigates to a read-only detail screen — no add/edit/delete controls.
//

import SwiftUI

// MARK: - Main Caregiver Pet Profile View
struct CaregiverPetProfileView: View {
    let petId: String
    @StateObject private var viewModel: PetProfileViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetProfileViewModel(petId: petId))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.3), Color.clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 400)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(snuffyPink)
            } else if let pet = viewModel.pet {
                ScrollView {
                    VStack(spacing: 24) {
                        // Pet image + name
                        VStack(spacing: 16) {
                            PetProfileImageView(imageUrl: pet.petImage)
                            VStack(spacing: 4) {
                                Text(pet.petName ?? "Unknown")
                                    .font(.system(size: 28, weight: .bold)).foregroundColor(.black)
                                Text(pet.petBreed ?? "Unknown")
                                    .font(.system(size: 18)).foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 20)

                        // Weight / Gender / Age
                        HStack(spacing: 0) {
                            InfoItem(title: "Weight", value: pet.petWeight ?? "–")
                            InfoItem(title: "Gender", value: pet.petGender ?? "–")
                            InfoItem(title: "Age",    value: pet.petAge    ?? "–")
                        }
                        .padding(.vertical, 16)
                        .background(snuffyPink.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        // Read-only option rows
                        VStack(spacing: 0) {
                            NavigationLink(destination: CaregiverVaccinationListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Vaccinations", icon: "syringe.fill")
                            }
                            Divider().padding(.leading, 72)
                            NavigationLink(destination: CaregiverDietListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Diet", icon: "fork.knife")
                            }
                            Divider().padding(.leading, 72)
                            NavigationLink(destination: CaregiverMedicationListView(petId: petId)) {
                                ProfileOptionRow(title: "Pet Medications", icon: "pills.fill")
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 40)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.slash").font(.system(size: 50)).foregroundColor(.gray.opacity(0.5))
                    Text("Pet not found").foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Pet Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Read-only Vaccination List + Detail
struct CaregiverVaccinationListView: View {
    let petId: String
    @StateObject private var viewModel: PetVaccinationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetVaccinationViewModel(petId: petId))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if viewModel.isLoading && viewModel.vaccinations.isEmpty {
                ProgressView().tint(snuffyPink)
            } else if viewModel.vaccinations.isEmpty {
                caregiverEmptyState(icon: "syringe.fill", label: "No vaccination records", pink: snuffyPink)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.vaccinations, id: \.vaccineId) { v in
                            NavigationLink(destination: CaregiverVaccinationDetailView(vaccination: v)) {
                                CaregiverVaccinationRow(vaccination: v)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Vaccination Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CaregiverVaccinationRow: View {
    let vaccination: VaccinationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(snuffyPink.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: "syringe.fill").foregroundColor(snuffyPink)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(vaccination.vaccineName).font(.headline)
                Text("Given: \(vaccination.dateOfVaccination)").font(.subheadline).foregroundColor(.gray)
                if vaccination.expires, let expiry = vaccination.expiryDate {
                    Text("Expires: \(expiry)").font(.caption).foregroundColor(.gray)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
        }
        .padding(16).background(Color.white).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct CaregiverVaccinationDetailView: View {
    let vaccination: VaccinationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header icon
                    ZStack {
                        Circle().fill(snuffyPink.opacity(0.15)).frame(width: 80, height: 80)
                        Image(systemName: "syringe.fill").foregroundColor(snuffyPink).font(.system(size: 36))
                    }
                    .padding(.top, 28).padding(.bottom, 20)

                    // Detail card
                    VStack(spacing: 0) {
                        detailRow(label: "Vaccine Name",          value: vaccination.vaccineName)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Date of Vaccination",   value: vaccination.dateOfVaccination)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Expires",               value: vaccination.expires ? "Yes" : "No")
                        if vaccination.expires, let expiry = vaccination.expiryDate {
                            Divider().padding(.leading, 16)
                            detailRow(label: "Expiry Date",       value: expiry)
                        }
                        Divider().padding(.leading, 16)
                        detailRow(label: "Notify on Expiry",      value: vaccination.notifyUponExpiry ? "Yes" : "No")
                        if let notes = vaccination.notes, !notes.isEmpty {
                            Divider().padding(.leading, 16)
                            detailRowMultiLine(label: "Notes", value: notes)
                        }
                    }
                    .background(Color.white).cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(vaccination.vaccineName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func detailRowMultiLine(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 15)).foregroundColor(.black)
            Text(value).font(.system(size: 14)).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Read-only Diet List + Detail
struct CaregiverDietListView: View {
    let petId: String
    @StateObject private var viewModel: PetDietViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetDietViewModel(petId: petId))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if viewModel.isLoading && viewModel.diets.isEmpty {
                ProgressView().tint(snuffyPink)
            } else if viewModel.diets.isEmpty {
                caregiverEmptyState(icon: "fork.knife", label: "No diet details found", pink: snuffyPink)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.diets, id: \.dietId) { d in
                            NavigationLink(destination: CaregiverDietDetailView(diet: d)) {
                                CaregiverDietRow(diet: d)
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
    }
}

struct CaregiverDietRow: View {
    let diet: PetDietDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(snuffyPink.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: "fork.knife").foregroundColor(snuffyPink)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(diet.foodName).font(.headline)
                HStack(spacing: 4) {
                    Text(diet.mealType).font(.caption).foregroundColor(snuffyPink)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(snuffyPink.opacity(0.1)).cornerRadius(4)
                    Text("at \(diet.servingTime)").font(.caption).foregroundColor(.gray)
                }
                Text("\(diet.portionSize) · \(diet.feedingFrequency)").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
        }
        .padding(16).background(Color.white).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct CaregiverDietDetailView: View {
    let diet: PetDietDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(snuffyPink.opacity(0.15)).frame(width: 80, height: 80)
                        Image(systemName: "fork.knife").foregroundColor(snuffyPink).font(.system(size: 36))
                    }
                    .padding(.top, 28).padding(.bottom, 20)

                    VStack(spacing: 0) {
                        detailRow(label: "Food Name",        value: diet.foodName)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Meal Type",        value: diet.mealType)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Food Category",    value: diet.foodCategory)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Portion Size",     value: diet.portionSize)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Feeding Frequency",value: diet.feedingFrequency)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Serving Time",     value: diet.servingTime)
                    }
                    .background(Color.white).cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(diet.foodName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Read-only Medication List + Detail
struct CaregiverMedicationListView: View {
    let petId: String
    @StateObject private var viewModel: PetMedicationViewModel
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetMedicationViewModel(petId: petId))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if viewModel.isLoading && viewModel.medications.isEmpty {
                ProgressView().tint(snuffyPink)
            } else if viewModel.medications.isEmpty {
                caregiverEmptyState(icon: "pills.fill", label: "No medication records", pink: snuffyPink)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.medications, id: \.medicationId) { m in
                            NavigationLink(destination: CaregiverMedicationDetailView(medication: m)) {
                                CaregiverMedicationRow(medication: m)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Medication Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CaregiverMedicationRow: View {
    let medication: PetMedicationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(snuffyPink.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: "pills.fill").foregroundColor(snuffyPink)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicineName).font(.headline)
                Text(medication.medicineType).font(.subheadline).foregroundColor(.gray)
                Text("Dosage: \(medication.dosage) · \(medication.frequency)").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 14))
        }
        .padding(16).background(Color.white).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct CaregiverMedicationDetailView: View {
    let medication: PetMedicationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            LinearGradient(colors: [snuffyPink.opacity(0.3), Color.clear],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(snuffyPink.opacity(0.15)).frame(width: 80, height: 80)
                        Image(systemName: "pills.fill").foregroundColor(snuffyPink).font(.system(size: 36))
                    }
                    .padding(.top, 28).padding(.bottom, 20)

                    VStack(spacing: 0) {
                        detailRow(label: "Medicine Name",  value: medication.medicineName)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Type",           value: medication.medicineType)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Purpose",        value: medication.purpose)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Dosage",         value: medication.dosage)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Frequency",      value: medication.frequency)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Start Date",     value: medication.startDate)
                        Divider().padding(.leading, 16)
                        detailRow(label: "End Date",       value: medication.endDate)
                    }
                    .background(Color.white).cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(medication.medicineName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundColor(.black)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Shared empty state helper
private func caregiverEmptyState(icon: String, label: String, pink: Color) -> some View {
    VStack {
        HStack(spacing: 20) {
            ZStack {
                Circle().fill(pink).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(.white).font(.system(size: 20))
            }
            Text(label).font(.system(size: 18, weight: .medium)).foregroundColor(.black)
            Spacer()
        }
        .padding(20).background(Color.white).cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16).padding(.top, 20)
        Spacer()
    }
}
