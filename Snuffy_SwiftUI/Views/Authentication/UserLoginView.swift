import SwiftUI

struct UserLoginView: View {
    @StateObject private var loginVM = UserLoginViewModel()
    @StateObject private var signUpVM = UserSignUpViewModel()
    @Environment(\.dismiss) var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    @State private var isSignUp: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Focus State to handle pink border highlights when focused
    enum Field: Hashable {
        case loginEmail
        case loginPassword
        case signUpName
        case signUpEmail
        case signUpPassword
    }
    @FocusState private var focusedField: Field?
    
    init(isSignUp: Bool = false) {
        _isSignUp = State(initialValue: isSignUp)
    }
    
    var body: some View {
        ZStack {
            // Strong Snuffy Pink Gradient Background (pink color all the way down)
            LinearGradient(
                colors: [
                    snuffyPink.opacity(0.45),
                    snuffyPink.opacity(0.28),
                    snuffyPink.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header with Back Button (always visible, goes to Get Started screen)
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // Original Snuffy Logo
                        Image("App Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                        
                        // Brand Heading
                        VStack(spacing: 4) {
                            Text("Snuffy")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("for tails that wag")
                                .font(.chalkboard(size: 22))
                                .foregroundColor(snuffyPink)
                        }
                        .padding(.bottom, 28)
                        
                        // Liquid Glass Card Container
                        VStack(spacing: 20) {
                            // Toggle Tab Selector (matching Image 3 RoundedRectangle style)
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isSignUp = false
                                    }
                                }) {
                                    Text("Login")
                                        .font(.system(size: 15, weight: isSignUp ? .medium : .semibold))
                                        .foregroundColor(isSignUp ? .gray : snuffyPink)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            Group {
                                                if !isSignUp {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.white)
                                                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                                                }
                                            }
                                        )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isSignUp = true
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.system(size: 15, weight: isSignUp ? .semibold : .medium))
                                        .foregroundColor(isSignUp ? snuffyPink : .gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            Group {
                                                if isSignUp {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.white)
                                                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                                                }
                                            }
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(4)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.top, 8)
                            
                            // Animated interior form contents
                            if !isSignUp {
                                VStack(spacing: 20) {
                                    loginEmailField
                                    loginPasswordField
                                    loginActionButton
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            } else {
                                VStack(spacing: 20) {
                                    signUpNameField
                                    signUpEmailField
                                    signUpPasswordField
                                    roleSelectionField
                                    signUpActionButton
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(24)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.white.opacity(0.45))
                                RoundedRectangle(cornerRadius: 32)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            // Loading Overlay
            if loginVM.isLoading || signUpVM.isLoading {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $loginVM.shouldNavigateToCaretakerHome) {
            Text("Caretaker Home Screen")
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            signUpVM.hasAgreedToTerms = true
        }
        .onChange(of: loginVM.showAlert) { _, newValue in
            if newValue {
                alertMessage = loginVM.alertMessage
                showAlert = true
            }
        }
        .onChange(of: signUpVM.showAlert) { _, newValue in
            if newValue {
                alertMessage = signUpVM.alertMessage
                showAlert = true
            }
        }
        .onChange(of: loginVM.shouldNavigateToSignUp) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSignUp = true
                }
                loginVM.shouldNavigateToSignUp = false
            }
        }
    }
    
    // MARK: - Input Components
    
    private var loginEmailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(focusedField == .loginEmail ? snuffyPink : snuffyPink.opacity(0.6))
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                TextField("Email address", text: $loginVM.email)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .loginEmail)
                    .onChange(of: loginVM.email) { _ in
                        loginVM.validateEmail()
                    }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.65))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        loginVM.emailErrorMessage != nil ? Color.red.opacity(0.6) : (focusedField == .loginEmail ? snuffyPink : Color.white.opacity(0.5)),
                        lineWidth: focusedField == .loginEmail || loginVM.emailErrorMessage != nil ? 2 : 1
                    )
            )
            
            if let errorMessage = loginVM.emailErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var loginPasswordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(focusedField == .loginPassword ? snuffyPink : snuffyPink.opacity(0.6))
                .font(.system(size: 16))
                .frame(width: 20)
            
            if loginVM.isPasswordVisible {
                TextField("Password", text: $loginVM.password)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .loginPassword)
            } else {
                SecureField("Password", text: $loginVM.password)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .loginPassword)
            }
            
            Spacer()
            
            Button(action: {
                loginVM.isPasswordVisible.toggle()
            }) {
                Image(systemName: loginVM.isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(snuffyPink.opacity(0.8))
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.65))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(focusedField == .loginPassword ? snuffyPink : Color.white.opacity(0.5),
                             lineWidth: focusedField == .loginPassword ? 2 : 1)
        )
    }
    
    private var loginActionButton: some View {
        Button(action: {
            loginVM.login()
        }) {
            HStack(spacing: 8) {
                Spacer()
                Text("Login")
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .frame(height: 52)
            .background(snuffyPink)
            .cornerRadius(16)
            .shadow(color: snuffyPink.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
    
    private var signUpNameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundColor(focusedField == .signUpName ? snuffyPink : snuffyPink.opacity(0.6))
                .font(.system(size: 16))
                .frame(width: 20)
            
            TextField("Name", text: $signUpVM.name)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .textContentType(.name)
                .focused($focusedField, equals: .signUpName)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.65))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(focusedField == .signUpName ? snuffyPink : Color.white.opacity(0.5),
                             lineWidth: focusedField == .signUpName ? 2 : 1)
        )
    }
    
    private var signUpEmailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(focusedField == .signUpEmail ? snuffyPink : snuffyPink.opacity(0.6))
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                TextField("Email address", text: $signUpVM.email)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .signUpEmail)
                    .onChange(of: signUpVM.email) { _ in
                        signUpVM.validateEmail()
                    }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.65))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        signUpVM.emailErrorMessage != nil ? Color.red.opacity(0.6) : (focusedField == .signUpEmail ? snuffyPink : Color.white.opacity(0.5)),
                        lineWidth: focusedField == .signUpEmail || signUpVM.emailErrorMessage != nil ? 2 : 1
                    )
            )
            
            if let errorMessage = signUpVM.emailErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var signUpPasswordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(focusedField == .signUpPassword ? snuffyPink : snuffyPink.opacity(0.6))
                .font(.system(size: 16))
                .frame(width: 20)
            
            if signUpVM.isPasswordVisible {
                TextField("Password", text: $signUpVM.password)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .signUpPassword)
            } else {
                SecureField("Password", text: $signUpVM.password)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .signUpPassword)
            }
            
            Spacer()
            
            Button(action: {
                signUpVM.isPasswordVisible.toggle()
            }) {
                Image(systemName: signUpVM.isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(snuffyPink.opacity(0.8))
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.65))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(focusedField == .signUpPassword ? snuffyPink : Color.white.opacity(0.5),
                             lineWidth: focusedField == .signUpPassword ? 2 : 1)
        )
    }
    
    private var roleSelectionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Role")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(0.6))
                .padding(.leading, 4)
            
            Picker("Role", selection: $signUpVM.selectedRole) {
                Text("Owner").tag(UserRole.petOwner)
                Text("Caretaker").tag(UserRole.caretaker)
                Text("Walker").tag(UserRole.dogWalker)
            }
            .pickerStyle(SegmentedPickerStyle())
            .controlSize(.large)
        }
        .padding(.top, 4)
    }
    
    private var signUpActionButton: some View {
        Button(action: {
            signUpVM.signUp()
        }) {
            HStack(spacing: 8) {
                Spacer()
                Text("Sign Up")
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .frame(height: 52)
            .background(snuffyPink)
            .cornerRadius(16)
            .shadow(color: snuffyPink.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        UserLoginView()
    }
}
