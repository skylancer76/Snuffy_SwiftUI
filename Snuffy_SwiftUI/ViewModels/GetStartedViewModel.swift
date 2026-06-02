import SwiftUI
import Combine

@MainActor
class GetStartedViewModel: ObservableObject {
    @Published var shouldNavigate = false

    func handleGetStarted() {
        shouldNavigate = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
