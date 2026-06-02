import SwiftUI
import Combine

struct EventParticipantsView: View {
    let event: CommunityEvent
    @ObservedObject var vm: EventDetailViewModel

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if vm.isLoadingParticipants {
                ProgressView().tint(snuffyPink)
            } else if vm.participants.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(vm.participants.count) participant\(vm.participants.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        ForEach(vm.participants) { participant in
                            ParticipantRow(participant: participant, snuffyPink: snuffyPink)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .task { await vm.loadParticipants() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: "person.2.slash")
                    .font(.system(size: 46))
                    .foregroundColor(snuffyPink)
            }
            Text("No registrations yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text("Participants will appear here\nonce they register for this event.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: EventParticipant
    let snuffyPink: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(snuffyPink.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "person.fill")
                    .foregroundColor(snuffyPink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(participant.userName)
                    .font(.headline)
                Text("Registered \(participant.registeredAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
