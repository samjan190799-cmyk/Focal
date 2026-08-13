//
// HapticManager.swift
// FocalApp
//
// Менеджер тактильной отдачи (Haptic Feedback) под iOS и macOS
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class HapticManager {
    public static let shared = HapticManager()
    
    private init() {}
    
    public func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
    
    public func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}
