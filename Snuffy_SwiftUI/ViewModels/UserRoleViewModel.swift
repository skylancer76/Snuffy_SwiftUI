import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class UserRoleViewModel: ObservableObject {
    @Published var role: UserRole = .petOwner
    @Published var isLoading = true
    @Published var isVerified = false
    @Published var isProfileComplete = false

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    init() {
        detectRole()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    func detectRole() {
        guard let uid = Auth.auth().currentUser?.uid else {
            role = .petOwner
            isLoading = false
            return
        }

        let email = Auth.auth().currentUser?.email ?? ""
        isLoading = true

        // 1. Caretakers — query by email (covers legacy custom-ID docs like "C9")
        //    then fall back to UID-keyed doc (covers new app-onboarded caretakers)
        let ctEmailListener = db.collection("caretakers")
            .whereField("email", isEqualTo: email)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.documents.first?.data(),
                      Self.isRealProfileDoc(data) else { return }
                let verified = data["isVerified"] as? Bool ?? false
                let complete = Self.profileComplete(from: data, isVerified: verified)
                DispatchQueue.main.async {
                    self.role = .caretaker
                    // Monotonic merge — once true, stay true. Prevents a stub-doc listener
                    // from clobbering good values set by the real-profile listener.
                    self.isVerified = self.isVerified || verified
                    self.isProfileComplete = self.isProfileComplete || complete
                    self.isLoading = false
                }
            }

        let ctUidListener = db.collection("caretakers").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      snap?.exists == true,
                      Self.isRealProfileDoc(data) else { return }
                let verified = data["isVerified"] as? Bool ?? false
                let complete = Self.profileComplete(from: data, isVerified: verified)
                DispatchQueue.main.async {
                    self.role = .caretaker
                    self.isVerified = self.isVerified || verified
                    self.isProfileComplete = self.isProfileComplete || complete
                    self.isLoading = false
                }
            }

        // 2. Dog Walkers — same dual lookup
        let dwEmailListener = db.collection("dogwalkers")
            .whereField("email", isEqualTo: email)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.documents.first?.data(),
                      Self.isRealProfileDoc(data) else { return }
                let verified = data["isVerified"] as? Bool ?? false
                let complete = Self.profileComplete(from: data, isVerified: verified)
                DispatchQueue.main.async {
                    self.role = .dogWalker
                    self.isVerified = self.isVerified || verified
                    self.isProfileComplete = self.isProfileComplete || complete
                    self.isLoading = false
                }
            }

        let dwUidListener = db.collection("dogwalkers").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      snap?.exists == true,
                      Self.isRealProfileDoc(data) else { return }
                let verified = data["isVerified"] as? Bool ?? false
                let complete = Self.profileComplete(from: data, isVerified: verified)
                DispatchQueue.main.async {
                    self.role = .dogWalker
                    self.isVerified = self.isVerified || verified
                    self.isProfileComplete = self.isProfileComplete || complete
                    self.isLoading = false
                }
            }

        // 3. Fallback for pure Pet Owners
        let poListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let snap = snap, snap.exists else { return }
                DispatchQueue.main.async {
                    if self.isLoading && self.role == .petOwner {
                        self.isLoading = false
                    }
                }
            }

        listeners.append(contentsOf: [ctEmailListener, ctUidListener,
                                      dwEmailListener, dwUidListener, poListener])

        // Safety timeout in case of network lag
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            if self.isLoading { self.isLoading = false }
        }
    }

    func refresh() {
        // Just let the active snapshot listeners do their job
    }

    // A real profile doc carries identity fields. Pure-stub docs (registration
    // placeholders, cross-collection index entries) lack these and must be ignored
    // so they don't clobber good values from the real-profile listener.
    private static func isRealProfileDoc(_ data: [String: Any]) -> Bool {
        return data["name"] != nil
            || data["email"] != nil
            || data["phoneNumber"] != nil
    }

    // Profile is complete if:
    // • the isProfileComplete flag is set, OR
    // • admin already verified them (they must have submitted a full profile), OR
    // • all three core fields are present (covers manually-added DB entries)
    private static func profileComplete(from data: [String: Any], isVerified: Bool) -> Bool {
        if data["isProfileComplete"] as? Bool == true { return true }
        if isVerified { return true }
        let address = (data["address"]     as? String ?? "").trimmingCharacters(in: .whitespaces)
        let bio     = (data["bio"]         as? String ?? "").trimmingCharacters(in: .whitespaces)
        let phone   = (data["phoneNumber"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        return !address.isEmpty && !bio.isEmpty && !phone.isEmpty
    }
}
