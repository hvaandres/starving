//
//  LoginView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo Section
            VStack {
                Image("starving-black")
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .padding(.top, 60)
                
                Spacer()
            }
            
            // Content Section
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Welcome Back!")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Sign in to continue managing your grocery lists and keep your family organized.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Authentication Buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                authManager.handleAppleSignInResult(authorization: authorization)
                            case .failure(let error):
                                authManager.errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // Sign in with Google
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.white)
                            Text("Sign in with Google")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .disabled(authManager.isLoading)
                }
                
                // Loading indicator
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding(.top, 20)
                }
                
                // Back to onboarding button
                Button(action: {
                    hasCompletedOnboarding = false
                }) {
                    Text("Back to Welcome")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: authManager.errorMessage) { errorMessage in
            showingError = errorMessage != nil
        }
    }
}

// MARK: - Preview
#Preview {
    @State var hasCompletedOnboarding = true
    return LoginView(hasCompletedOnboarding: $hasCompletedOnboarding)
        .environmentObject(AuthenticationManager())
}
