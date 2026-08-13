//
// FocalTheme.swift
// FocalApp
//
// Дизайн-система Focal: Неоморфизм, Глассморфизм, Пастельная палитра и Типографика
//

import SwiftUI

public enum FocalTheme {
    // MARK: - Цвета
    public static let backgroundLight = Color(red: 0.94, green: 0.95, blue: 0.97)
    public static let backgroundDark = Color(red: 0.10, green: 0.11, blue: 0.13)
    
    public static let cardSurfaceLight = Color(red: 0.96, green: 0.97, blue: 0.99)
    public static let cardSurfaceDark = Color(red: 0.14, green: 0.15, blue: 0.18)
    
    public static let accentPastelPurple = Color(red: 0.72, green: 0.65, blue: 0.94)
    public static let accentPastelBlue = Color(red: 0.60, green: 0.78, blue: 0.98)
    public static let accentPastelPink = Color(red: 0.96, green: 0.68, blue: 0.81)
    public static let accentPastelGreen = Color(red: 0.64, green: 0.88, blue: 0.75)
    
    public static let priorityHigh = Color(red: 0.95, green: 0.40, blue: 0.40)
    public static let priorityMedium = Color(red: 0.96, green: 0.70, blue: 0.30)
    public static let priorityLow = Color(red: 0.45, green: 0.80, blue: 0.60)
    
    public static let gradientPrimary = LinearGradient(
        colors: [accentPastelPurple, accentPastelBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Неоморфные тени
    public static func neumorphicShadow(colorScheme: ColorScheme) -> (light: Color, dark: Color) {
        if colorScheme == .dark {
            return (light: Color.black.opacity(0.6), dark: Color.white.opacity(0.04))
        } else {
            return (light: Color.black.opacity(0.12), dark: Color.white.opacity(0.9))
        }
    }
}

// MARK: - View Modifiers для Неоморфизма и Глассморфизма

public struct NeumorphicCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 24) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        let shadows = FocalTheme.neumorphicShadow(colorScheme: colorScheme)
        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? FocalTheme.cardSurfaceDark : FocalTheme.cardSurfaceLight)
                    .shadow(color: shadows.light, radius: 12, x: 6, y: 6)
                    .shadow(color: shadows.dark, radius: 12, x: -6, y: -6)
            )
    }
}

public struct GlassmorphicOverlayModifier: ViewModifier {
    var opacity: Double
    var cornerRadius: CGFloat
    
    public init(opacity: Double = 0.25, cornerRadius: CGFloat = 24) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    public func neumorphicCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(NeumorphicCardModifier(cornerRadius: cornerRadius))
    }
    
    public func glassmorphicCard(opacity: Double = 0.25, cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassmorphicOverlayModifier(opacity: opacity, cornerRadius: cornerRadius))
    }
}
