//
//  AuthenticationModifier.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import CryptoKit

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        // Check if user is already signed in
        self.user = Auth.auth().currentUser
        self.isSignedIn = user != nil
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isSignedIn = user != nil
            }
        }
    }
    
    // MARK: - Sign In with Apple
    func signInWithApple() {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let delegate = AppleSignInDelegate(authManager: self, nonce: nonce)
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        authorizationController.performRequests()
    }
    
    // MARK: - Sign In with Google
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "No client ID found"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "No root view controller found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self?.errorMessage = "Failed to get Google ID token"
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Functions
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

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let authManager: AuthenticationManager
    private var currentNonce: String?
    
    init(authManager: AuthenticationManager, nonce: String) {
        self.authManager = authManager
        self.currentNonce = nonce
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = getCurrentNonce() else {
                authManager.errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                authManager.errorMessage = "Unable to fetch identity token"
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                authManager.errorMessage = "Unable to serialize token string from data"
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.authManager.errorMessage = error.localizedDescription
                    }
                }
            }
        }
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
    
    private func getCurrentNonce() -> String? {
        return currentNonce
    }
    
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

// MARK: - Authentication View Modifier
struct AuthenticationModifier: ViewModifier {
    @StateObject private var authManager = AuthenticationManager()
    
    func body(content: Content) -> some View {
        content
            .environmentObject(authManager)
    }
}

extension View {
    func withAuthentication() -> some View {
        self.modifier(AuthenticationModifier())
    }
}
