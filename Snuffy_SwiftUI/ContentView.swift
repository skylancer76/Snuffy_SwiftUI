import SwiftUI
import FirebaseAuth

struct ContentView: View {

    // MARK: - Properties

    @State private var isLoggedIn = false

    // MARK: - Body

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                GetStartedView()
            }
        }
        .onAppear {
            UIApplication.shared.installDismissKeyboardOnTap()
            Auth.auth().addStateDidChangeListener { auth, user in
                isLoggedIn = (user != nil)
            }
        }
    }
}
