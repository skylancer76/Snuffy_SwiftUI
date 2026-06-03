import SwiftUI

struct RequestScheduledView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @State private var rotationAngle: Double = 0
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Image(systemName: "seal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .foregroundColor(snuffyPink)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(snuffyPink)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(
                            Animation.linear(duration: 12)
                                .repeatForever(autoreverses: false)
                        ) {
                            rotationAngle = 360
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    Text("Booking Request Sent")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Your request has been sent! ❤️ Sit tight while we review and accept your booking.")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button(action: {
                    navigateToHome()
                }) {
                    Text("Okay")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(snuffyPink)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Methods
    
    private func navigateToHome() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

#Preview {
    RequestScheduledView()
}
