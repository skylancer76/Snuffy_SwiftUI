import SwiftUI
import Firebase

@main
struct Snuffy_SwiftUIApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
