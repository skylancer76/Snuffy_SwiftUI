import SwiftUI

struct AddPetView: View {
    @StateObject private var viewModel = AddPetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var customBreed   = ""
    @State private var showAgePicker = false
    @State private var showWeightPicker = false
    @State private var ageYears  = 1
    @State private var ageMonths = 0
    @State private var weightKg      = 5
    @State private var weightDecimal = 0   // 0 → ".0", 5 → ".5"

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    private var ageDisplay: String {
        var parts: [String] = []
        if ageYears  > 0 { parts.append("\(ageYears) \(ageYears  == 1 ? "Year"  : "Years")") }
        if ageMonths > 0 { parts.append("\(ageMonths) \(ageMonths == 1 ? "Month" : "Months")") }
        return parts.isEmpty ? "Less than 1 month" : parts.joined(separator: " ")
    }

    private var weightDisplay: String {
        weightDecimal == 0 ? "\(weightKg) kg" : "\(weightKg).5 kg"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Image Upload
                        VStack(spacing: 12) {
                            Button(action: { showingImagePicker = true }) {
                                if let image = viewModel.selectedImage {
                                    Image(uiImage: image)
                                        .resizable().scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                } else {
                                    Image(systemName: "camera.circle.fill")
                                        .resizable().scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray.opacity(0.5))
                                        .background(Circle().fill(Color.white)
                                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
                                }
                            }
                        }
                        .padding(.top, 24)

                        // Pet Details Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pet Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {

                                // Name
                                FormRow(label: "Name", value: $viewModel.petName, placeholder: "Your pet's name")
                                Divider().padding(.leading, 16)

                                // Breed
                                Menu {
                                    ForEach(viewModel.breeds, id: \.self) { breed in
                                        Button(breed) { viewModel.petBreed = breed }
                                    }
                                } label: {
                                    SelectionRow(label: "Breed",
                                                 value: viewModel.petBreed.isEmpty ? "Select" : viewModel.petBreed)
                                }

                                // Custom breed when "Other" selected
                                if viewModel.petBreed == "Other" {
                                    Divider().padding(.leading, 16)
                                    FormRow(label: "Breed Name", value: $customBreed,
                                            placeholder: "Enter breed name")
                                }

                                Divider().padding(.leading, 16)

                                // Age — single row, opens wheel sheet
                                Button { showAgePicker = true } label: {
                                    SelectionRow(label: "Age", value: ageDisplay)
                                }
                                .buttonStyle(.plain)

                                Divider().padding(.leading, 16)

                                // Gender
                                Menu {
                                    ForEach(viewModel.genders, id: \.self) { gender in
                                        Button(gender) { viewModel.petGender = gender }
                                    }
                                } label: {
                                    SelectionRow(label: "Gender", value: viewModel.petGender)
                                }

                                Divider().padding(.leading, 16)

                                // Weight — single row, opens wheel sheet
                                Button { showWeightPicker = true } label: {
                                    SelectionRow(label: "Weight", value: weightDisplay)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        // Add Pet Button
                        Button(action: {
                            if viewModel.petBreed == "Other",
                               !customBreed.trimmingCharacters(in: .whitespaces).isEmpty {
                                viewModel.petBreed = customBreed.trimmingCharacters(in: .whitespaces)
                            }
                            viewModel.petAge    = ageDisplay
                            viewModel.petWeight = weightDisplay
                            viewModel.savePet()
                        }) {
                            Text("Add Pet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(snuffyPink)
                                .cornerRadius(30)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .disabled(viewModel.isLoading)
                    }
                }

                if viewModel.isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
                }
            }
            .navigationTitle("Add New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage)
            }
            // Age wheel picker sheet
            .sheet(isPresented: $showAgePicker) {
                AgePickerSheet(years: $ageYears, months: $ageMonths)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
            // Weight wheel picker sheet
            .sheet(isPresented: $showWeightPicker) {
                WeightPickerSheet(kg: $weightKg, decimal: $weightDecimal)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: viewModel.isSuccess) { success in
                if success { dismiss() }
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
}

// MARK: - Age Wheel Picker Sheet

struct AgePickerSheet: View {
    @Binding var years:  Int
    @Binding var months: Int
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 0) {
            // Native-style toolbar
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Age")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .foregroundColor(snuffyPink)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(UIColor.systemBackground))

            Divider()

            HStack(spacing: 0) {
                Picker("Years", selection: $years) {
                    ForEach(0...20, id: \.self) { y in
                        Text("\(y) \(y == 1 ? "Year" : "Years")").tag(y)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Months", selection: $months) {
                    ForEach(0...11, id: \.self) { m in
                        Text("\(m) \(m == 1 ? "Month" : "Months")").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Weight Wheel Picker Sheet

struct WeightPickerSheet: View {
    @Binding var kg:      Int
    @Binding var decimal: Int   // 0 = .0, 5 = .5
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Weight")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .foregroundColor(snuffyPink)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(UIColor.systemBackground))

            Divider()

            HStack(spacing: 0) {
                Picker("kg", selection: $kg) {
                    ForEach(0...100, id: \.self) { k in
                        Text("\(k)").tag(k)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                // Fixed "." separator
                Text(".")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)

                Picker("decimal", selection: $decimal) {
                    Text("0 kg").tag(0)
                    Text("5 kg").tag(5)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Shared Form Components

struct FormRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            TextField(placeholder, text: $value)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16))
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
    }
}

struct SelectionRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.black)
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    AddPetView()
}
