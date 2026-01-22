//
//  UserProfile.swift
//  starving
//
//  Created by Alan Haro on 1/19/26.
//

import Foundation
import FirebaseFirestore

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var provider: AuthProvider
    var createdAt: Date
    var lastUpdated: Date
    
    enum AuthProvider: String, Codable {
        case apple
        case google
        case email
    }
    
    init(userId: String, displayName: String, email: String? = nil, photoURL: String? = nil, provider: AuthProvider) {
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.provider = provider
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}
