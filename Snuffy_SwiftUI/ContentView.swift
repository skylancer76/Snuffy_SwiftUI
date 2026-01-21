//
//  ContentView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 30/12/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                GetStartedView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { auth, user in
                isLoggedIn = (user != nil)
            }
        }
    }
}

#Preview {
    ContentView()
}

