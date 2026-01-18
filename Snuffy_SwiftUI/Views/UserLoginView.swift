//
//  UserLoginView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 13/01/26.
//

import SwiftUI

struct UserLoginView: View {
    @StateObject private var viewModel = UserLoginViewModel()
    @Environment(\.dismiss) var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    snuffyPink.opacity(0.5),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo Section
                    VStack(spacing: 24) {
                        Image("App Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .padding(.top, 100)
                        
                        VStack(spacing: 0) {
                            Text("Snuffy")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("for tails that wag")
                                .font(.chalkboard(size: 24))
                                .foregroundColor(snuffyPink)
                        }
                    }
                    .padding(.bottom, 60)
                    
                    // Email TextField
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(SnuffyTextFieldStyle(
                                isValid: viewModel.emailErrorMessage == nil && !viewModel.email.isEmpty,
                                showError: viewModel.emailErrorMessage != nil,
                                snuffyPink: snuffyPink
                            ))
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .onChange(of: viewModel.email) { _ in
                                viewModel.validateEmail()
                            }
                        
                        if let errorMessage = viewModel.emailErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Password TextField
                    HStack {
                        if viewModel.isPasswordVisible {
                            TextField("Enter your password", text: $viewModel.password)
                                .textContentType(.password)
                                .autocapitalization(.none)
                        } else {
                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.password)
                                .autocapitalization(.none)
                        }
                        
                        Button(action: {
                            viewModel.isPasswordVisible.toggle()
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(snuffyPink)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    // Login Button
                    Button(action: {
                        viewModel.login()
                    }) {
                        Text("Login")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .disabled(viewModel.isLoading)
                    
                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account ?")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                        
                        Button(action: {
                            viewModel.shouldNavigateToSignUp = true
                        }) {
                            Text("Create One!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(snuffyPink)
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            
            // Loading Indicator
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $viewModel.shouldNavigateToSignUp) {
            UserSignUpView()
        }
        .navigationDestination(isPresented: $viewModel.shouldNavigateToHome) {
            // Replace with your home view
            Text("Home Screen")
        }
        .navigationDestination(isPresented: $viewModel.shouldNavigateToCaretakerHome) {
            // Replace with your caretaker home view
            Text("Caretaker Home Screen")
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// Custom TextField Style
struct SnuffyTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    let showError: Bool
    let snuffyPink: Color
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        showError ? Color.red : (isValid ? snuffyPink : Color.gray.opacity(0.3)),
                        lineWidth: showError || isValid ? 2 : 1
                    )
            )
    }
}

#Preview {
    NavigationStack {
        UserLoginView()
    }
}
