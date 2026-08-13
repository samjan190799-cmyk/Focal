//
// FocalNote.swift
// FocalApp
//
// Главная модель визуальной заметки Focal в SwiftData
//

import Foundation
import SwiftData

@Model
public final class FocalNote: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isLiked: Bool
    public var isBookmarked: Bool
    public var backgroundModeRaw: String
    
    @Attribute(.externalStorage) public var backgroundImageData: Data?
    public var blurRadius: Double
    public var overlayOpacity: Double
    public var reminderDate: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \CanvasElement.note)
    public var canvasElements: [CanvasElement]
    
    @Relationship(deleteRule: .cascade, inverse: \ToDoItem.note)
    public var todoItems: [ToDoItem]
    
    public var backgroundMode: BackgroundMode {
        get { BackgroundMode(rawValue: backgroundModeRaw) ?? .fullBleed }
        set { backgroundModeRaw = newValue.rawValue }
    }
    
    public var completedRatioText: String {
        guard !todoItems.isEmpty else { return "0/0" }
        let completed = todoItems.filter { $0.isCompleted }.count
        return "\(completed)/\(todoItems.count)"
    }
    
    public var completionPercentage: Double {
        guard !todoItems.isEmpty else { return 0.0 }
        let completed = todoItems.filter { $0.isCompleted }.count
        return Double(completed) / Double(todoItems.count)
    }
    
    public init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        backgroundMode: BackgroundMode = .fullBleed,
        backgroundImageData: Data? = nil,
        blurRadius: Double = 0.0,
        overlayOpacity: Double = 0.3,
        reminderDate: Date? = nil,
        canvasElements: [CanvasElement] = [],
        todoItems: [ToDoItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.backgroundModeRaw = backgroundMode.rawValue
        self.backgroundImageData = backgroundImageData
        self.blurRadius = blurRadius
        self.overlayOpacity = overlayOpacity
        self.reminderDate = reminderDate
        self.canvasElements = canvasElements
        self.todoItems = todoItems
    }
}
