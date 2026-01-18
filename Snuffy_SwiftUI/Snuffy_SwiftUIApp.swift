//
//  Snuffy_SwiftUIApp.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 30/12/25.
//


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
