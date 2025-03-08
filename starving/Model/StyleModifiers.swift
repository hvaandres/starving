//
//  StyleModifiers.swift
//  starving
//
//  Created by Alan Haro on 3/5/25.
//

import SwiftUI

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15) // Standardized vertical padding
            .padding(.horizontal, 20) // Standardized horizontal padding
            .background(Color(.label))
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 20) // Consistent outer horizontal padding
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
}

