//
//  LiquidGlassModifiers.swift
//  starving
//
//  Created by Alan Haro on 1/10/25.
//

import SwiftUI

// MARK: - Advanced Glass Card Modifier with Layered Translucency
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    @State private var shimmerPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Layer 1: Base ultra-thin material (60% opacity)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                    
                    // Layer 2: Thin material overlay (30% opacity)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .opacity(0.3)
                    
                    // Layer 3: Color tint gradient for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Layer 4: Shimmer effect for "liquid" feel
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerPhase)
                        .mask(RoundedRectangle(cornerRadius: cornerRadius))
                }
                // Multi-layer shadows for depth
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                // Layered borders
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            )
            .onAppear {
                // Continuous shimmer animation
                withAnimation(
                    .linear(duration: 3)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 400
                }
            }
    }
}

// MARK: - Glass Button Style with Lensing Effect
struct GlassButtonStyle: ButtonStyle {
    var useCapsule: Bool = true
    @State private var lensingIntensity: CGFloat = 0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                Group {
                    if useCapsule {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                            .overlay(
                                // Lensing effect - radial gradient
                                Capsule()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.white.opacity(0.3 + lensingIntensity),
                                                Color.white.opacity(0.1),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 100
                                        )
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onAppear {
                // Subtle pulsing lensing effect
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    lensingIntensity = 0.1
                }
            }
    }
}

// MARK: - Glass Text Field Modifier
struct GlassTextFieldModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Glass List Background
struct GlassListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
    }
}

// MARK: - Glass Section Background
struct GlassSectionModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Gradient Background
struct GradientBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.15, blue: 0.2)]
                    : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.88, green: 0.9, blue: 0.95)]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            content
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    func glassTextField(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(GlassTextFieldModifier(cornerRadius: cornerRadius))
    }
    
    func glassListBackground() -> some View {
        self.modifier(GlassListBackgroundModifier())
    }
    
    func glassSection(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassSectionModifier(cornerRadius: cornerRadius))
    }
    
    func gradientBackground() -> some View {
        self.modifier(GradientBackgroundModifier())
    }
}
