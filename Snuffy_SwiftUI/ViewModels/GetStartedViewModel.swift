//
//  GetStartedViewModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 06/01/26.
//

import SwiftUI
import Combine

@MainActor
class GetStartedViewModel: ObservableObject {
    @Published var shouldNavigate = false
    
    func handleGetStarted() {
        // Add your navigation logic here
        // For example, update user defaults, trigger navigation, etc.
        shouldNavigate = true
        
        // Example: Save that user has seen onboarding
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        print("Get Started button tapped")
    }
}
