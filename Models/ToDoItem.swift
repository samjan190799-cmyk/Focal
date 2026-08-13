//
// ToDoItem.swift
// FocalApp
//
// Модель элемента списка задач To-Do в SwiftData
//

import Foundation
import SwiftData

@Model
public final class ToDoItem: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var isCompleted: Bool
    public var priorityRaw: String
    @Attribute(.externalStorage) public var thumbnailData: Data?
    public var dueDate: Date?
    
    public var note: FocalNote?
    
    public var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        text: String = "",
        isCompleted: Bool = false,
        priority: Priority = .medium,
        thumbnailData: Data? = nil,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.priorityRaw = priority.rawValue
        self.thumbnailData = thumbnailData
        self.dueDate = dueDate
    }
}
