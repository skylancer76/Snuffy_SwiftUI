import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ServiceFlowViewModel: ObservableObject {
    @Published var servicePin: String?
    @Published var firestoreStatus: String = ""
    @Published var isGeneratingPin  = false
    @Published var isVerifyingOTP   = false
    @Published var isEndingService  = false
    @Published var otpError: String?
    @Published var endError: String?
    @Published var otpSuccessDismiss = false

    private let bookingId:   String
    private let collection:  String
    let bookingType: BookingType
    let startDate:   Date
    let endDate:     Date

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    init(booking: BookingItem) {
        bookingId   = booking.id
        collection  = booking.type == .caretaker ? "scheduleRequests" : "dogWalkerRequests"
        bookingType = booking.type
        startDate   = booking.startDate
        endDate     = booking.endDate
        attachListener()
    }

    deinit { listener?.remove() }

    // MARK: - Firestore listener

    private func attachListener() {
        listener = db.collection(collection).document(bookingId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let data = snap?.data() else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.servicePin     = data["servicePin"] as? String
                    self.firestoreStatus = (data["status"] as? String ?? "").lowercased()
                }
            }
    }

    // MARK: - State helpers

    private var isBookingDayOrLater: Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: Date()) >= cal.startOfDay(for: startDate)
    }

    /// Pet owner: show "Start Service" tap target
    var canStartService: Bool {
        firestoreStatus == "accepted" && isBookingDayOrLater && servicePin == nil
    }

    /// Pet owner: show PIN card (generated, waiting for provider)
    var hasPinPending: Bool {
        firestoreStatus == "accepted" && servicePin != nil
    }

    /// Provider: Booking day reached but pet owner hasn't generated a PIN yet
    var providerWaitingForPin: Bool {
        firestoreStatus == "accepted" && isBookingDayOrLater && servicePin == nil
    }

    /// Provider: OTP entry available once pet owner generated a PIN
    var providerCanEnterOTP: Bool {
        firestoreStatus == "accepted" && isBookingDayOrLater && servicePin != nil
    }

    /// Provider: End Service available once ongoing.
    /// Dog walker must wait until past the scheduled end time.
    var providerCanEndService: Bool {
        guard firestoreStatus == "ongoing" else { return false }
        return bookingType == .dogWalker ? Date() >= endDate : true
    }

    /// Caretaker ending before the scheduled end date
    var isEarlyEndForCaretaker: Bool {
        bookingType == .caretaker && Date() < endDate
    }

    // MARK: - Pet owner action

    func generatePin() async {
        isGeneratingPin = true
        defer { isGeneratingPin = false }
        let pin = String(format: "%04d", Int.random(in: 1000...9999))
        try? await db.collection(collection).document(bookingId)
            .updateData(["servicePin": pin])
    }

    // MARK: - Provider actions

    func verifyOTP(_ entered: String) async {
        guard let stored = servicePin else {
            otpError = "No PIN available yet. Ask the pet owner to generate one."
            return
        }
        isVerifyingOTP = true
        otpError = nil
        defer { isVerifyingOTP = false }
        if entered == stored {
            do {
                try await db.collection(collection).document(bookingId)
                    .updateData(["status": "ongoing"])
                otpSuccessDismiss = true
            } catch {
                otpError = "Failed to update status. Please try again."
            }
        } else {
            otpError = "Incorrect PIN. Please try again."
        }
    }

    func endService(reason: String? = nil) async {
        isEndingService = true
        endError = nil
        defer { isEndingService = false }
        var updates: [String: Any] = ["status": "completed"]
        if let r = reason, !r.isEmpty { updates["endReason"] = r }
        do {
            try await db.collection(collection).document(bookingId).updateData(updates)
        } catch {
            endError = "Failed to end service. Please try again."
        }
    }
}
