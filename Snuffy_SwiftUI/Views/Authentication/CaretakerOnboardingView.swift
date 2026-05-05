//
//  CaregiverOnboardingView.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//

import SwiftUI
import PhotosUI

struct CaretakerOnboardingView: View {

    let role: UserRole
    @ObservedObject var roleVM: UserRoleViewModel
    @StateObject private var vm = CaregiverOnboardingViewModel()
    @Environment(\.dismiss) var dismiss

    // MARK: - Design Tokens
    private let snuffyPink      = Color(red: 0.92, green: 0.28, blue: 0.48)
    private let snuffyPinkLight = Color(red: 0.95, green: 0.4, blue: 0.58)
    private let glassStroke     = Color.white.opacity(0.22)

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundGradient

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.bottom, 4)

                    personalSection
                    experienceSection
                    verificationSection
                    gallerySection
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)

            if vm.isLoading {
                loadingOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    vm.logout()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            // Triggers the native iOS location permission dialog
            vm.requestLocationPermission()
        }
        .alert("Something Went Wrong", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    // MARK: - Ambient Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("App Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .shadow(color: snuffyPink.opacity(0.2), radius: 15, y: 5)

            VStack(spacing: 6) {
                Text(role == .dogWalker ? "Dog Walker Profile" : "Caretaker Profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Complete your profile to get started")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.top, 8)
    }

    // MARK: - Personal Section
    private var personalSection: some View {
        GlassSectionCard(title: "Personal Details",
                         icon: "person.text.rectangle",
                         accentColor: snuffyPink) {
            GlassTextField(
                title: "Full Address",
                placeholder: "Flat no., Street, City, Pin code",
                text: $vm.address,
                icon: "mappin.and.ellipse",
                accentColor: snuffyPink
            )
            GlassTextField(
                title: "Phone Number",
                placeholder: "+91 90000 00000",
                text: $vm.phoneNumber,
                icon: "phone.fill",
                accentColor: snuffyPink,
                keyboardType: .phonePad
            )
            GlassMultilineField(
                title: "Bio",
                placeholder: "Tell pet owners a little about yourself",
                text: $vm.bio,
                icon: "text.quote",
                accentColor: snuffyPink
            )
        }
    }

    // MARK: - Experience Section
    private var experienceSection: some View {
        GlassSectionCard(title: "Experience",
                         icon: "star.circle",
                         accentColor: snuffyPink) {
            if role == .caretaker {
                GlassTextField(
                    title: "Years of Experience",
                    placeholder: "e.g. 3",
                    text: $vm.experience,
                    icon: "calendar.badge.clock",
                    accentColor: snuffyPink,
                    keyboardType: .numberPad
                )
            }
            GlassTextField(
                title: "Total Pets Handled",
                placeholder: "How many pets have you cared for?",
                text: $vm.petsHandled,
                icon: "pawprint.fill",
                accentColor: snuffyPink,
                keyboardType: .numberPad
            )
        }
    }

    // MARK: - Verification Section
    private var verificationSection: some View {
        GlassSectionCard(title: "Verification",
                         icon: "checkmark.seal",
                         accentColor: .green) {
            GlassMultilineField(
                title: "Certification",
                placeholder: "Enter certification details or paste a link (optional)",
                text: $vm.certification,
                icon: "rosette",
                accentColor: snuffyPink
            )
            GlassMultilineField(
                title: "Letter of Recommendation",
                placeholder: "Paste a link or write brief details (optional)",
                text: $vm.lor,
                icon: "doc.text",
                accentColor: snuffyPink
            )
        }
    }

    // MARK: - Gallery Section
    private var gallerySection: some View {
        GlassSectionCard(title: "Photos",
                         icon: "photo.on.rectangle.angled",
                         accentColor: .purple) {
            Text("Upload up to 4 photos. The first will be your profile photo.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(0..<4, id: \.self) { i in
                    GlassPhotoSlot(
                        index: i,
                        image: vm.selectedImages[i],
                        selectedItem: $vm.selectedItems[i],
                        accentColor: snuffyPink
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
                    .font(.system(size: 16, weight: .semibold))
                Text("Submit for Review")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(red: 1.0, green: 0.42, blue: 0.61)) // Vibrant pink from the login button image
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(red: 1.0, green: 0.42, blue: 0.61).opacity(0.35), radius: 12, y: 6)
        }
        .disabled(vm.isLoading)
        .opacity(vm.isLoading ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
        .padding(.top, 8)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(snuffyPink)

                Text("Submitting your profile")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(glassStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
        }
    }
}

// MARK: - Glass Section Card
struct GlassSectionCard<Content: View>: View {
    let title: String
    let icon: String
    var accentColor: Color = Color(red: 0.92, green: 0.28, blue: 0.48)
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .tracking(0.8)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.white.opacity(0.4)
                BlurView(style: .systemUltraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 10)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Glass Text Field
struct GlassTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var accentColor: Color = Color(red: 0.92, green: 0.28, blue: 0.48)
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isFocused || !text.isEmpty ? accentColor : .secondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(title, text: $text)
                .font(.system(size: 15))
                .keyboardType(keyboardType)
                .focused($isFocused)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Group {
                if isFocused || !text.isEmpty {
                    Color.white
                } else {
                    ZStack {
                        Color.white.opacity(0.6)
                        BlurView(style: .systemThinMaterial)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused || !text.isEmpty ? accentColor.opacity(0.6) : Color.white.opacity(0.4),
                    lineWidth: isFocused || !text.isEmpty ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Glass Multiline Field
struct GlassMultilineField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var accentColor: Color = Color(red: 0.92, green: 0.28, blue: 0.48)

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isFocused || !text.isEmpty ? accentColor : .secondary)
                .frame(width: 20)
                .padding(.leading, 14)
                .padding(.top, 14)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.leading, 44)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .frame(minHeight: 80)
                    .padding(.leading, 40)
                    .padding(.trailing, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
            }
        }
        .background(
            Group {
                if isFocused || !text.isEmpty {
                    Color.white
                } else {
                    ZStack {
                        Color.white.opacity(0.6)
                        BlurView(style: .systemThinMaterial)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused || !text.isEmpty ? accentColor.opacity(0.6) : Color.white.opacity(0.4),
                    lineWidth: isFocused || !text.isEmpty ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Glass Photo Slot
struct GlassPhotoSlot: View {
    let index: Int
    let image: UIImage?
    @Binding var selectedItem: PhotosPickerItem?
    var accentColor: Color = Color(red: 0.92, green: 0.28, blue: 0.48)
    let onPick: (PhotosPickerItem?) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)

                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: index == 0
                                      ? "person.crop.circle.badge.plus"
                                      : "plus.circle")
                                    .font(.system(size: 24, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(accentColor.opacity(0.7))
                                Text(index == 0 ? "Profile Photo" : "Photo \(index + 1)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if image != nil && index == 0 {
                            VStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text("Profile")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .background(accentColor.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(8)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            image != nil
                                ? accentColor.opacity(0.4)
                                : accentColor.opacity(0.3),
                            style: StrokeStyle(
                                lineWidth: 1.5,
                                dash: image != nil ? [] : [6]
                            )
                        )
                )
        }
        .onChange(of: selectedItem) { item in
            onPick(item)
        }
    }
}

#Preview {
    NavigationStack {
        CaretakerOnboardingView(role: .caretaker, roleVM: UserRoleViewModel())
    }
}
