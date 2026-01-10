//
//  LoginView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var showingError = false
    @State private var appleSignInDelegate: AppleSignInCoordinator?
    
    var body: some View {
        ZStack {
            // Black background for logo visibility
            Color.black
                .ignoresSafeArea()
            
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
                        Text("Welcome Back")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to manage your grocery lists")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    
                    // Authentication Buttons
                    VStack(spacing: 16) {
                        // Sign in with Apple
                        AppleSignInButton(
                            authManager: authManager,
                            delegate: $appleSignInDelegate
                        )
                        
                        // Sign in with Google
                        Button(action: {
                            authManager.signInWithGoogle()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                Text("Sign in with Google")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                            )
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
                            .foregroundColor(.white.opacity(0.6))
                            .font(.footnote)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
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

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let authManager: AuthenticationManager
    private var currentNonce: String?
    
    init(authManager: AuthenticationManager, nonce: String) {
        self.authManager = authManager
        self.currentNonce = nonce
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        authManager.handleAppleSignInResult(authorization: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authManager.errorMessage = error.localizedDescription
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Apple Sign In Button
struct AppleSignInButton: View {
    let authManager: AuthenticationManager
    @Binding var delegate: AppleSignInCoordinator?
    
    var body: some View {
        Button(action: handleAppleSignIn) {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))
                Text("Sign in with Apple")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
        .padding(.horizontal, 20)
        .disabled(authManager.isLoading)
    }
    
    private func handleAppleSignIn() {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let coordinator = AppleSignInCoordinator(authManager: authManager, nonce: nonce)
        delegate = coordinator
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
    }
    
    // Helper functions
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Preview
#Preview {
    @State var hasCompletedOnboarding = true
    return LoginView(hasCompletedOnboarding: $hasCompletedOnboarding)
        .environmentObject(AuthenticationManager())
}
