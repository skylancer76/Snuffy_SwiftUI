# Snuffy

> [!NOTE]
> This project was developed as part of the End Semester **Major Project (21CSP402L)** during my final year of undergraduate study at SRM Institute of Science and Technology.
> #### Project Report: [Final Major Project Report.pdf](https://github.com/user-attachments/files/28592781/Final.Major.Project.Report.pdf)

## Problem Statement

Pet owners often struggle to find **reliable and trustworthy caretakers** when they are unavailable. Whether it's for a short walk or an extended stay, they are always in a constant state of dilemma.

## Our Solution

**Snuffy** is a modern, premium iOS application built with SwiftUI that connects pet owners with trusted, verified pet caregivers. Whether you need a daily dog walker or a weekend pet sitter, Snuffy provides a seamless platform for scheduling, managing, and reviewing pet care services. It allows pet owners to:

-  Book **pet caretaking** and **dog walking** services.
-  Track their pet in **real-time** using **live updates using mapkit**.
-  Store and manage all pet-related information in one place:
  - Vaccination records
  - Diet plans
  - Medication schedules
-  Connect with other pet owners in the Snuffy community.

Snuffy ensures secure, seamless connections between pet owners and caretakers, complete with **in-app messaging**, **voice calls**, and **booking confirmations**.

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

```text
Snuffy_SwiftUI/
├── Models/                 # Data models bridging Firestore documents and Swift structs
├── ViewModels/             # Business logic and Firebase integration, keeping views lightweight
├── Views/                  # UI layer built entirely with SwiftUI
│   ├── Authentication/     # Login, Signup, and Firebase Auth flows
│   ├── Home/               # Core navigation, custom tab bars, and main dashboard
│   ├── Booking/            # Scheduling, viewing, and managing booking requests
│   ├── Community/          # Social features, user interaction, and posts
│   ├── Pets/               # Pet profiles, medical history, and management
│   └── ServiceProvider/    # Caregiver application, onboarding, and waitlist logic
├── Services/               # Singleton managers (e.g., FirebaseManager) handling APIs
└── Utils/                  # Reusable components, formatters, and helper extensions
```

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

> [!IMPORTANT]
> ### Copyright & License
> Copyright for this project is registered under IDF reference number CR_202608. All rights reserved.
