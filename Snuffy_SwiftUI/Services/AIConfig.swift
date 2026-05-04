//
//  AIConfig.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma
//

// The Gemini API key now lives server-side, exposed only to the
// `geminiChat` Cloud Function via Firebase Secrets. The iOS bundle no
// longer ships any model credentials — `PetBotViewModel` calls the
// function via the FirebaseFunctions SDK instead of hitting Gemini directly.
struct AIConfig {
    static let geminiCallableName = "geminiChat"
    static let geminiModel        = "gemini-2.5-flash"
}
