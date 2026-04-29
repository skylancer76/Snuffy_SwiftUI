//
//  EndServiceSheet.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma

import SwiftUI

struct EndServiceSheet: View {
    @ObservedObject var vm: ServiceFlowViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var reason = ""
    @FocusState private var reasonFocused: Bool

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    private var isEarly: Bool { vm.isEarlyEndForCaretaker }

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
                Text(isEarly ? "End Service Early?" : "Complete Service")
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
            .padding(.bottom, 24)

            // MARK: - Body content
            if isEarly {
                earlyEndContent
            } else {
                onScheduleContent
            }

            // MARK: - Error
            if let err = vm.endError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()

            // MARK: - Action button
            Button {
                reasonFocused = false
                Task { await vm.endService(reason: isEarly ? reason : nil) }
            } label: {
                Group {
                    if vm.isEndingService {
                        ProgressView().tint(.white)
                    } else {
                        Text(isEarly ? "Submit & End Service" : "Confirm Completion")
                            .font(.body.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canSubmit ? snuffyPink : Color(uiColor: .tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .disabled(vm.isEndingService || !canSubmit)
            .animation(.easeInOut(duration: 0.2), value: reason)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: vm.firestoreStatus) { _, status in
            if status == "completed" { dismiss() }
        }
    }

    private var canSubmit: Bool {
        if isEarly { return !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return true
    }

    // MARK: - On-schedule confirmation content

    private var onScheduleContent: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(snuffyPink)
            }

            Text("Ready to wrap up?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Confirming will mark this booking as completed\nand notify the pet owner.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Early end content

    private var earlyEndContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Warning banner
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 18))
                Text("You're ending before the scheduled end date. Please provide a reason.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)

            // Reason label
            (Text("Reason")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
             + Text("  Required")
                .font(.subheadline)
                .foregroundStyle(.tertiary))
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // Text editor
            ZStack(alignment: .topLeading) {
                if reason.isEmpty {
                    Text("Describe why the service is ending early…")
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $reason)
                    .font(.body)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .focused($reasonFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
        }
    }
}
