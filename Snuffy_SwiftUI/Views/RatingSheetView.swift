import SwiftUI

struct RatingSheetView: View {
    let targetName: String
    @ObservedObject var vm: RatingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStars = 0
    @State private var comment       = ""
    @FocusState private var commentFocused: Bool

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Handle + Header
            Capsule()
                .fill(Color(uiColor: .tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            HStack {
                Spacer()
                Text("Rate \(targetName)")
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

            // MARK: - Stars
            VStack(spacing: 6) {
                Text("How was your experience?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                selectedStars = star
                            }
                        } label: {
                            Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundStyle(star <= selectedStars ? snuffyPink : Color(uiColor: .tertiaryLabel))
                                .scaleEffect(star == selectedStars ? 1.15 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedStars)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)

                Text(ratingLabel)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(snuffyPink)
                    .opacity(selectedStars > 0 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: selectedStars)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)

            // MARK: - Comments
            VStack(alignment: .leading, spacing: 8) {
                Text("Comments")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    + Text("  Optional")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                ZStack(alignment: .topLeading) {
                    if comment.isEmpty {
                        Text("Share your experience…")
                            .font(.body)
                            .foregroundStyle(Color(uiColor: .placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $comment)
                        .font(.body)
                        .frame(minHeight: 90)
                        .scrollContentBackground(.hidden)
                        .focused($commentFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)

            Spacer()

            // MARK: - Error
            if let error = vm.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            // MARK: - Submit
            Button {
                commentFocused = false
                Task { await vm.submitRating(stars: selectedStars, comment: comment) }
            } label: {
                Group {
                    if vm.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit Rating")
                            .font(.body.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(selectedStars > 0 ? snuffyPink : Color(uiColor: .tertiaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .disabled(vm.isSubmitting || selectedStars == 0)
            .animation(.easeInOut(duration: 0.2), value: selectedStars)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: vm.didSubmit) { _, submitted in
            if submitted { dismiss() }
        }
    }

    private var ratingLabel: String {
        switch selectedStars {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent!"
        default: return " "
        }
    }
}
