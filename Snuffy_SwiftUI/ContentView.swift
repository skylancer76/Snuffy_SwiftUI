import SwiftUI
import FirebaseAuth

struct ContentView: View {

    // MARK: - Properties

    @State private var isLoggedIn = false
    @State private var showSplash = true

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    // MARK: - Body

    var body: some View {
        ZStack {
            if showSplash {
                splashView
                    .transition(.opacity)
            } else {
                Group {
                    if isLoggedIn {
                        MainTabView()
                    } else {
                        GetStartedView()
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            UIApplication.shared.installDismissKeyboardOnTap()
            Auth.auth().addStateDidChangeListener { auth, user in
                isLoggedIn = (user != nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }

    // MARK: - Subviews

    private var splashView: some View {
        ZStack {
            LinearGradient(
                colors: [snuffyPink.opacity(0.25), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("App Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .shadow(color: snuffyPink.opacity(0.25), radius: 12, x: 0, y: 6)
        }
    }
}
