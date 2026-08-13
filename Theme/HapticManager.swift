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
    
    public func impact(_ style: Int = 1) {
        #if os(iOS)
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case 0: feedbackStyle = .light
        case 2: feedbackStyle = .heavy
        default: feedbackStyle = .medium
        }
        let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public func notification(_ type: Int = 0) {
        #if os(iOS)
        let feedbackType: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case 1: feedbackType = .warning
        case 2: feedbackType = .error
        default: feedbackType = .success
        }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(feedbackType)
        #endif
    }
    
    public func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
    
    public func impactLight() { impact(0) }
    public func impactMedium() { impact(1) }
    public func impactHeavy() { impact(2) }
}
