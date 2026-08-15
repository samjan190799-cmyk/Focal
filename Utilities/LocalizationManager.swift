//
// LocalizationManager.swift
// FocalApp
//
// Менеджер локализации интерфейса с поддержкой Русского, Английского и Армянского языков.
//

import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case armenian = "hy"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .russian: return "🇷🇺 Русский"
        case .english: return "🇬🇧 English"
        case .armenian: return "🇦🇲 Հայերեն"
        }
    }
    
    public var localizedSettingsHeader: String {
        switch self {
        case .russian: return "Язык и Локализация"
        case .english: return "Language & Region"
        case .armenian: return "Լեզու և Տեղայնացում"
        }
    }
    
    public var localizedLanguagePickerTitle: String {
        switch self {
        case .russian: return "Язык интерфейса"
        case .english: return "App Language"
        case .armenian: return "Ծրագրի լեզուն"
        }
    }
}
