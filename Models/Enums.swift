//
// Enums.swift
// FocalApp
//
// Создано для Swift 6 (Strict Concurrency)
//

import Foundation

/// Режим отображения фонового изображения в карточке заметки
public enum BackgroundMode: String, Codable, CaseIterable, Sendable {
    case fullBleed = "fullBleed"
    case structuredTop = "structuredTop"
    case structuredBottom = "structuredBottom"
    case floating = "floating"
    
    public var titleRu: String {
        switch self {
        case .fullBleed: return "На весь экран"
        case .structuredTop: return "Верхний баннер"
        case .structuredBottom: return "Нижний баннер"
        case .floating: return "Интерактивный объект"
        }
    }
}

/// Приоритет выполнения задачи To-Do
public enum Priority: String, Codable, CaseIterable, Comparable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var titleRu: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }
    
    public var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

/// Тип содержимого интерактивного элемента холста
public enum ElementType: String, Codable, CaseIterable, Sendable {
    case text = "text"
    case pngOverlay = "pngOverlay"
    case audioSnippet = "audioSnippet"
}
