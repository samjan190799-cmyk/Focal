//
// CanvasElement.swift
// FocalApp
//
// Модель интерактивного элемента на свободном холсте (SwiftData)
//

import Foundation
import SwiftData

@Model
public final class CanvasElement: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var contentTypeRaw: String
    public var positionX: Double
    public var positionY: Double
    public var scale: Double
    public var rotation: Double
    public var contentData: String
    
    public var note: FocalNote?
    
    public var contentType: ElementType {
        get { ElementType(rawValue: contentTypeRaw) ?? .text }
        set { contentTypeRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        contentType: ElementType = .text,
        positionX: Double = 0.0,
        positionY: Double = 0.0,
        scale: Double = 1.0,
        rotation: Double = 0.0,
        contentData: String = ""
    ) {
        self.id = id
        self.contentTypeRaw = contentType.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
        self.contentData = contentData
    }
}
