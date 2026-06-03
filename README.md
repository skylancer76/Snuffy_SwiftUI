# Snuffy

Snuffy is a modern, premium iOS application built with SwiftUI that connects pet owners with trusted, verified pet caregivers. Whether you need a daily dog walker or a weekend pet sitter, Snuffy provides a seamless platform for scheduling, managing, and reviewing pet care services.

## Features

### For Pet Owners
- **Find Caregivers**: Browse profiles for verified Caretakers and Dog Walkers in your area.
- **Easy Booking**: Seamlessly schedule pet sitting or dog walking services.
- **Manage Pets**: Keep detailed profiles for your furry friends.
- **Community Hub**: Connect with other pet owners in the Snuffy community.
- **Rating System**: Leave reviews and rate your experience with caregivers.

### For Caregivers (Dog Walkers & Caretakers)
- **Dedicated Dashboard**: A custom home screen to manage incoming requests and upcoming bookings.
- **Real-time Notifications**: Get instant alerts when a new booking request arrives.
- **Verification System**: Secure onboarding and waitlist flow to ensure trust and safety.
- **Schedule Management**: Accept or reject requests with a single tap.
- **Resource Library**: Access helpful articles and resources tailored to your role.

## Tech Stack

- **Framework**: SwiftUI (iOS 16.0+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Backend**: Firebase 
  - Authentication (User Login & Registration)
  - Cloud Firestore (Real-time database for users, pets, and bookings)
- **Package Management**: Swift Package Manager (SPM)
- **Image Loading**: Kingfisher

## App Structure

The app is cleanly separated into feature domains:
- `Views/Home`: Core navigation, custom tab bars, and user/caregiver home screens.
- `Views/Booking`: Everything related to scheduling, viewing, and managing booking requests.
- `ViewModels`: Business logic and Firebase integration, keeping views lightweight.
- `Models`: Data models bridging Firestore documents and Swift structs.
- `Services`: Singleton managers (e.g., `FirebaseManager`) handling API/Network layers.

## Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- CocoaPods / SPM (Dependencies resolve automatically)

### Installation
1. Clone the repository to your local machine.
2. Open `Snuffy_SwiftUI.xcworkspace` (if using CocoaPods) or `Snuffy_SwiftUI.xcodeproj` (if strictly using SPM) in Xcode.
3. Wait for Xcode to resolve Swift Package Manager dependencies (Firebase, Kingfisher).
4. Select a simulator or connected iOS device (iOS 16.0+).
5. Build and run the project using `⌘ + R`.

### Firebase Configuration
Ensure that your `GoogleService-Info.plist` is properly added to the root of the Xcode project to enable backend functionality.

## Design Philosophy
Snuffy prioritizes a rich, vibrant aesthetic utilizing curated color palettes (like `snuffyPink`), smooth micro-animations, glassmorphism (`.ultraThinMaterial`), and a dynamic, responsive UI.

## Copyright & License
Copyright for this project is registered under IDF reference number CR_202608. All rights reserved.
