//
//  CaregiverOnboardingView.swift
//  Snuffy_SwiftUI
//
//  Authored by bhumika sharam
//

import SwiftUI
import PhotosUI

struct CaregiverOnboardingView: View {

    let role: UserRole
    @ObservedObject var roleVM: UserRoleViewModel
    @StateObject private var vm = CaregiverOnboardingViewModel()

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let cardBG     = Color(.systemBackground)
    private let pageBG     = Color(.systemGroupedBackground)

    var body: some View {
        ZStack {
            pageBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Header
                    headerSection

                    // MARK: Form Sections
                    VStack(spacing: 16) {
                        personalSection
                        experienceSection
                        verificationSection
                        gallerySection
                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Loading overlay
            if vm.isLoading {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
                    Text("Submitting your profile…")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Oops!", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [snuffyPink.opacity(0.85), snuffyPink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 6) {
                Image(systemName: role == .caretaker ? "heart.circle.fill" : "figure.walk.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .shadow(radius: 4)

                Text(role == .caretaker ? "Caretaker Profile" : "Dog Walker Profile")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Complete your profile to get approved")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.bottom, 28)
        }
    }

    // MARK: - Personal Section
    private var personalSection: some View {
        OnboardingSectionCard(title: "Personal Details", icon: "person.fill") {
            OnboardingField(
                title: "Full Address",
                placeholder: "Flat no., Street, City, Pincode",
                text: $vm.address,
                icon: "mappin.circle.fill"
            )
            OnboardingField(
                title: "Phone Number",
                placeholder: "+91 90000 00000",
                text: $vm.phoneNumber,
                icon: "phone.fill",
                keyboardType: .phonePad
            )
            OnboardingMultilineField(
                title: "Bio",
                placeholder: "Tell pet owners a little about yourself…",
                text: $vm.bio,
                icon: "text.quote"
            )
        }
    }

    // MARK: - Experience Section
    private var experienceSection: some View {
        OnboardingSectionCard(title: "Experience", icon: "star.fill") {
            if role == .caretaker {
                OnboardingField(
                    title: "Years of Experience",
                    placeholder: "e.g. 3",
                    text: $vm.experience,
                    icon: "calendar.badge.clock",
                    keyboardType: .numberPad
                )
            }
            OnboardingField(
                title: "Total Pets Handled",
                placeholder: "How many pets have you cared for?",
                text: $vm.petsHandled,
                icon: "pawprint.fill",
                keyboardType: .numberPad
            )
        }
    }

    // MARK: - Verification Section
    private var verificationSection: some View {
        OnboardingSectionCard(title: "Verification Documents", icon: "checkmark.seal.fill", iconColor: .green) {
            OnboardingMultilineField(
                title: "Certification",
                placeholder: "Enter your certification details or paste a link (optional)",
                text: $vm.certification,
                icon: "rosette"
            )
            OnboardingMultilineField(
                title: "Letter of Recommendation",
                placeholder: "Paste a link or write brief details (optional)",
                text: $vm.lor,
                icon: "doc.text.fill"
            )
        }
    }

    // MARK: - Gallery Section
    private var gallerySection: some View {
        OnboardingSectionCard(title: "Photos", icon: "photo.stack.fill", iconColor: .purple) {
            Text("Upload up to 4 photos. The first will be your profile photo.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.bottom, 6)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    PhotoSlot(
                        index: i,
                        image: vm.selectedImages[i],
                        selectedItem: $vm.selectedItems[i]
                    ) { item in
                        vm.loadImage(from: item, into: i)
                    }
                }
            }
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            vm.submit(role: role, roleVM: roleVM)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                Text("Submit for Review")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [snuffyPink, snuffyPink.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: snuffyPink.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(vm.isLoading)
        .padding(.top, 8)
    }
}

// MARK: - Section Card Container
struct OnboardingSectionCard<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = Color(red: 1.0, green: 0.4, blue: 0.6)
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.8)
            }

            content
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Single-line Field
struct OnboardingField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(snuffyPink)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(text.isEmpty ? Color.clear : snuffyPink.opacity(0.5), lineWidth: 1.2)
            )
        }
    }
}

// MARK: - Multi-line Field
struct OnboardingMultilineField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(snuffyPink)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .frame(minHeight: 80)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(text.isEmpty ? Color.clear : snuffyPink.opacity(0.5), lineWidth: 1.2)
            )
        }
    }
}

// MARK: - Photo Slot
struct PhotoSlot: View {
    let index: Int
    let image: UIImage?
    @Binding var selectedItem: PhotosPickerItem?
    let onPick: (PhotosPickerItem?) -> Void
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                image != nil ? snuffyPink : Color(.systemGray4),
                                style: StrokeStyle(lineWidth: 1.5, dash: image != nil ? [] : [5])
                            )
                    )

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Profile badge for first slot
                    if index == 0 {
                        VStack {
                            Spacer()
                            Text("Profile")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(snuffyPink)
                                .cornerRadius(6)
                                .padding(6)
                        }
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: index == 0 ? "person.crop.circle.badge.plus" : "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(snuffyPink.opacity(0.7))
                        Text(index == 0 ? "Profile Photo" : "Photo \(index + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: selectedItem) { item in
            onPick(item)
        }
    }
}

#Preview {
    NavigationStack {
        CaregiverOnboardingView(role: .caretaker, roleVM: UserRoleViewModel())
    }
}
