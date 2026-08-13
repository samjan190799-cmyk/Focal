//
// FocalTheme.swift
// FocalApp
//
// Дизайн-система Focal: Классические Светлая и Темная темы, Неоморфизм и Глассморфизм
//

import SwiftUI

public enum FocalTheme {
    // MARK: - Цвета Классических тем
    #if os(iOS)
    public static let backgroundLight = Color(uiColor: .systemGroupedBackground)
    public static let cardSurfaceLight = Color(uiColor: .secondarySystemGroupedBackground)
    public static let backgroundDark = Color(uiColor: .systemGroupedBackground)
    public static let cardSurfaceDark = Color(uiColor: .secondarySystemGroupedBackground)
    #else
    public static let backgroundLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    public static let cardSurfaceLight = Color.white
    public static let backgroundDark = Color(red: 0.08, green: 0.08, blue: 0.10)
    public static let cardSurfaceDark = Color(red: 0.15, green: 0.16, blue: 0.20)
    #endif
    
    public static let accentPastelPurple = Color(red: 0.55, green: 0.45, blue: 0.92)
    public static let accentPastelBlue = Color(red: 0.35, green: 0.60, blue: 0.95)
    public static let accentPastelPink = Color(red: 0.92, green: 0.45, blue: 0.68)
    public static let accentPastelGreen = Color(red: 0.35, green: 0.75, blue: 0.55)
    
    public static let priorityHigh = Color(red: 0.90, green: 0.30, blue: 0.30)
    public static let priorityMedium = Color(red: 0.92, green: 0.58, blue: 0.18)
    public static let priorityLow = Color(red: 0.30, green: 0.72, blue: 0.48)
    
    public static let gradientPrimary = LinearGradient(
        colors: [accentPastelPurple, accentPastelBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Неоморфные тени
    public static func neumorphicShadow(colorScheme: ColorScheme) -> (light: Color, dark: Color) {
        if colorScheme == .dark {
            return (light: Color.black.opacity(0.5), dark: Color.white.opacity(0.04))
        } else {
            return (light: Color.black.opacity(0.08), dark: Color.white.opacity(0.85))
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
                    .shadow(color: shadows.light, radius: 10, x: 4, y: 6)
                    .shadow(color: shadows.dark, radius: 10, x: -4, y: -4)
            )
    }
}

public struct GlassmorphicOverlayModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
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
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
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

