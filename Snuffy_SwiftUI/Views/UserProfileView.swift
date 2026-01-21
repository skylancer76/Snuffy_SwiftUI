
import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var pushNotifications = true
    @State private var emailUpdates = false
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Explore")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(snuffyPink)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 24) {
                    // User Card
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(white: 0.7)) // Grey avatar background
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text(viewModel.userInitials)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.userName)
                                .font(.system(size: 20, weight: .bold))
                            
                            Text(viewModel.userEmail)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Push Notifications Row
                    NavigationRow(title: "Push Notifications", status: pushNotifications ? "On" : "Off")
                        .padding(.horizontal, 16)
                    
                    // Email Updates Row
                    NavigationRow(title: "Email Updates", status: emailUpdates ? "On" : "Off")
                        .padding(.horizontal, 16)
                    
                    // Privacy & Information Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PRIVACY & INFORMATION")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            PrivacyItem(title: "See how your data is managed")
                            Divider().padding(.horizontal, 16)
                            PrivacyItem(title: "Help")
                            Divider().padding(.horizontal, 16)
                            PrivacyItem(title: "Terms & Conditions")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 16)
                    }
                    
                    // Logout Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("LOGOUT")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        
                        Button(action: {
                            viewModel.logout()
                        }) {
                            Text("Logout")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(snuffyPink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(snuffyPink.opacity(0.15))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Footer
                    Text("This app is using your location. You can turn off location services or adjust settings in Settings.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color(white: 0.96))
    }
}

private struct NavigationRow: View {
    let title: String
    let status: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.black)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(status)
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.8))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private struct PrivacyItem: View {
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    UserProfileView(viewModel: HomeViewModel())
}
