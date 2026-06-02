//
//  OTPEntrySheet.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma

import SwiftUI

struct OTPEntrySheet: View {
    @ObservedObject var vm: ServiceFlowViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @FocusState private var pinFocused: Bool

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Handle
            Capsule()
                .fill(Color(uiColor: .tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            // MARK: - Header
            HStack {
                Spacer()
                Text("Enter Service PIN")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)

            Text("Ask the pet owner for the 4-digit PIN shown\non their booking info screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 32)

            // MARK: - PIN boxes
            ZStack {
                // Invisible text field captures keyboard input
                TextField("", text: $pin)
                    .keyboardType(.numberPad)
                    .focused($pinFocused)
                    .onChange(of: pin) { _, val in
                        pin = String(val.filter(\.isNumber).prefix(4))
                    }
                    .opacity(0)
                    .frame(width: 1, height: 1)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { i in
                        let chars = Array(pin)
                        let char: String = i < chars.count ? String(chars[i]) : ""
                        let isFilled = i < chars.count

                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .frame(width: 64, height: 72)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            isFilled ? snuffyPink : Color(uiColor: .separator),
                                            lineWidth: isFilled ? 2 : 1
                                        )
                                )
                            Text(char)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pin.count)
                    }
                }
            }
            .onTapGesture { pinFocused = true }
            .padding(.bottom, 16)

            // MARK: - Error
            if let err = vm.otpError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // MARK: - Submit
            Button {
                pinFocused = false
                Task { await vm.verifyOTP(pin) }
            } label: {
                Group {
                    if vm.isVerifyingOTP {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Service")
                            .font(.body.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(pin.count == 4 ? snuffyPink : Color(uiColor: .tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .disabled(vm.isVerifyingOTP || pin.count < 4)
            .animation(.easeInOut(duration: 0.2), value: pin.count)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pinFocused = true }
        }
        .onChange(of: vm.otpSuccessDismiss) { _, triggered in
            if triggered { dismiss() }
        }
    }
}
