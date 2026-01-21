//
//  UserSignUpView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 13/01/26.
//

import SwiftUI

struct UserSignUpView: View {
    @StateObject private var viewModel = UserSignUpViewModel()
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
                            .padding(.top, 50)
                        
                        VStack(spacing: 0) {
                            
                            Text("Snuffy")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("for tails that wag")
                                .font(.chalkboard(size: 24))
                                .foregroundColor(snuffyPink)
                        }
                    }
                    .padding(.bottom, 40)
                    
                    // Name TextField
                    TextField("Enter your name", text: $viewModel.name)
                        .textFieldStyle(SnuffyTextFieldStyle(
                            isValid: !viewModel.name.isEmpty,
                            showError: false,
                            snuffyPink: snuffyPink
                        ))
                        .textContentType(.name)
                        .padding(.horizontal, 32)
                    
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
                    .padding(.top, 16)
                    
                    
                    // Password TextField
                    HStack {
                        if viewModel.isPasswordVisible {
                            TextField("Enter your password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .autocapitalization(.none)
                        } else {
                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.newPassword)
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
                    
                    // Terms and Conditions
                    Button(action: {
                        viewModel.hasAgreedToTerms.toggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.hasAgreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 24))
                                .foregroundColor(snuffyPink)
                            
                            Text("Agree with terms and conditions")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 25)
                    
                    // Role Segmented Control
                    Picker("Role", selection: $viewModel.selectedRole) {
                        Text("Pet Owner").tag(UserRole.petOwner)
                        Text("Pet Caretaker").tag(UserRole.caretaker)
                        Text("Pet Walker").tag(UserRole.dogWalker)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 32)
                    .padding(.top, 25)
                    
                    // Sign Up Button
                    Button(action: {
                        viewModel.signUp()
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(snuffyPink)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .disabled(viewModel.isLoading)
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
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    NavigationStack {
        UserSignUpView()
    }
}
