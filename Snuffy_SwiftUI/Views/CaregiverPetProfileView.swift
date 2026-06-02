import SwiftUI

// MARK: - Caregiver Pet Profile (mirrors PetProfileView, read-only — no delete menu)
struct CaregiverPetProfileView: View {
    let petId: String
    @StateObject private var viewModel: PetProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(petId: String) {
        self.petId = petId
        _viewModel = StateObject(wrappedValue: PetProfileViewModel(petId: petId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(snuffyPink)
                    .frame(maxHeight: .infinity)
            } else if let pet = viewModel.pet {
                VStack(spacing: 0) {

                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {

                            PetProfileImageView(imageUrl: pet.petImage)
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                                .padding(.top, 20)
                                .padding(.bottom, 30)

                            VStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    Text(pet.petName ?? "Unknown")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)
                                    Text(pet.petBreed ?? "Unknown")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 32)

                                HStack(spacing: 12) {
                                    AttributeCard(title: "Age",    value: pet.petAge    ?? "Unknown")
                                    AttributeCard(title: "Weight", value: pet.petWeight ?? "Unknown")
                                    AttributeCard(title: "Sex",    value: pet.petGender ?? "Unknown")
                                }
                                .padding(.horizontal, 24)

                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Records")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 24)

                                    VStack(spacing: 16) {
                                        NavigationLink(destination: CaregiverVaccinationListView(petId: petId)) {
                                            RecordRow(
                                                icon: "syringe.fill",
                                                color: .orange,
                                                title: "Vaccination",
                                                subtitle: "Vaccination history"
                                            )
                                        }
                                        NavigationLink(destination: CaregiverDietListView(petId: petId)) {
                                            RecordRow(
                                                icon: "fork.knife",
                                                color: .purple,
                                                title: "Diet",
                                                subtitle: "Meal plan & schedules"
                                            )
                                        }
                                        NavigationLink(destination: CaregiverMedicationListView(petId: petId)) {
                                            RecordRow(
                                                icon: "pills.fill",
                                                color: .blue,
                                                title: "Medication",
                                                subtitle: "Current medications"
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding(.top, 16)

                                Spacer().frame(height: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Pet not found").foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Read-only Vaccination List (mirrors PetVaccinationListView, no plus button)
struct CaregiverVaccinationListView: View {
    let petId: String
    @StateObject private var viewModel: PetVaccinationViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

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
                CaregiverRecordHeader(title: "Vaccination Details", dismiss: dismiss)

                if viewModel.isLoading && viewModel.vaccinations.isEmpty {
                    ProgressView().tint(snuffyPink)
                } else if viewModel.vaccinations.isEmpty {
                    CaregiverEmptyState(
                        icon: "syringe.fill",
                        title: "No vaccinations yet",
                        subtitle: "This pet has no vaccination records on file."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.vaccinations, id: \.vaccineId) { v in
                                NavigationLink(destination: CaregiverVaccinationDetailView(vaccination: v)) {
                                    PetVaccinationListView.VaccinationRow(vaccination: v)
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
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Read-only Vaccination Detail (mirrors VaccinationDetailView, no Delete)
struct CaregiverVaccinationDetailView: View {
    let vaccination: VaccinationDetails
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.2), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 0) {
                        DetailRow(icon: "syringe.fill", label: "Vaccine Name", value: vaccination.vaccineName)
                        Divider()
                        DetailRow(icon: "calendar", label: "Date of Vaccine", value: vaccination.dateOfVaccination)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

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
                            ToggleRow(icon: "bell.fill", label: "Notify upon expiry", isOn: .constant(vaccination.notifyUponExpiry))
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

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
    }
}

// MARK: - Read-only Diet List (mirrors PetDietListView, no plus button)
struct CaregiverDietListView: View {
    let petId: String
    @StateObject private var viewModel: PetDietViewModel
    @Environment(\.dismiss) private var dismiss
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

            VStack(spacing: 0) {
                CaregiverRecordHeader(title: "Diet Details", dismiss: dismiss)

                if viewModel.isLoading && viewModel.diets.isEmpty {
                    ProgressView().tint(snuffyPink)
                } else if viewModel.diets.isEmpty {
                    CaregiverEmptyState(
                        icon: "fork.knife",
                        title: "No diet plan yet",
                        subtitle: "This pet has no diet records on file."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.diets, id: \.dietId) { d in
                                NavigationLink(destination: CaregiverDietDetailView(diet: d)) {
                                    PetDietListView.DietRow(diet: d)
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
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Read-only Diet Detail (mirrors DietDetailView, no Delete)
struct CaregiverDietDetailView: View {
    let diet: PetDietDetails
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
                    VStack(spacing: 0) {
                        DetailRow(icon: "fork.knife", label: "Food Name", value: diet.foodName)
                        Divider()
                        DetailRow(icon: "tag", label: "Food Category", value: diet.foodCategory)
                        Divider()
                        DetailRow(icon: "clock", label: "Meal Type", value: diet.mealType)
                        Divider()
                        DetailRow(icon: "timer", label: "Serving Time", value: diet.servingTime)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIET DETAILS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 12)

                        VStack(spacing: 0) {
                            DetailRow(icon: "scalemass", label: "Portion Size", value: diet.portionSize)
                            Divider()
                            DetailRow(icon: "repeat", label: "Frequency", value: diet.feedingFrequency)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Diet Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Read-only Medication List (mirrors PetMedicationListView, no plus button)
struct CaregiverMedicationListView: View {
    let petId: String
    @StateObject private var viewModel: PetMedicationViewModel
    @Environment(\.dismiss) private var dismiss
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

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
                CaregiverRecordHeader(title: "Medication Details", dismiss: dismiss)

                if viewModel.isLoading && viewModel.medications.isEmpty {
                    ProgressView().tint(snuffyPink)
                } else if viewModel.medications.isEmpty {
                    CaregiverEmptyState(
                        icon: "pills.fill",
                        title: "No medications yet",
                        subtitle: "This pet has no medication records on file."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.medications, id: \.medicationId) { m in
                                NavigationLink(destination: CaregiverMedicationDetailView(medication: m)) {
                                    PetMedicationListView.MedicationRow(medication: m)
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
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Read-only Medication Detail (mirrors MedicationDetailView, no Delete)
struct CaregiverMedicationDetailView: View {
    let medication: PetMedicationDetails
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
    }
}

// MARK: - Shared header used by all read-only caregiver record lists
private struct CaregiverRecordHeader: View {
    let title: String
    let dismiss: DismissAction
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        HStack {
            Button { dismiss() } label: {
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

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            // Spacer placeholder to balance the chevron — keeps the title centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}

private struct CaregiverEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: icon)
                    .font(.system(size: 46))
                    .foregroundColor(snuffyPink)
            }
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
