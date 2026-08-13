//
// ExportManager.swift
// FocalApp
//
// Менеджер экспорта карточки заметки в сюжет 9:16 (Story) через ImageRenderer
//

import SwiftUI

@MainActor
public final class ExportManager {
    public static let shared = ExportManager()
    
    private init() {}
    
    /// Рендерит заметку в вертикальный формат истории 9:16
    public func renderStory(for note: FocalNote) async -> Image? {
        let storyView = StoryExportContainerView(note: note)
            .frame(width: 1080 / 3.0, height: 1920 / 3.0) // Пропорция 9:16
        
        let renderer = ImageRenderer(content: storyView)
        renderer.scale = 3.0
        
        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            return Image(nsImage: nsImage)
        }
        #endif
        
        return nil
    }
}

// MARK: - Макет 9:16 для экспорта карточки (StoryExportContainerView)

@MainActor
public struct StoryExportContainerView: View {
    let note: FocalNote
    
    public var body: some View {
        ZStack {
            // Фон истории
            BackgroundViewManager(
                mode: note.backgroundMode,
                imageData: note.backgroundImageData,
                blurRadius: note.blurRadius,
                overlayOpacity: note.overlayOpacity
            )
            
            VStack(alignment: .leading, spacing: 20) {
                // Бренд-шапка Focal
                HStack {
                    Image(systemName: "f.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(FocalTheme.gradientPrimary)
                    
                    Text("Focal Story")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(note.createdAt.formatted(date: .numeric, time: .omitted))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Заголовок заметки
                Text(note.title.isEmpty ? "Без названия" : note.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 6)
                
                // Список ключевых задач
                if !note.todoItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(note.todoItems.prefix(5)) { item in
                            HStack {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .white.opacity(0.7))
                                
                                Text(item.text)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .strikethrough(item.isCompleted)
                            }
                        }
                    }
                    .padding(16)
                    .glassmorphicCard(opacity: 0.3, cornerRadius: 18)
                }
                
                Spacer()
                
                // Водяной знак снизу
                HStack {
                    Spacer()
                    Text("Создано в Focal App")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding(24)
        }
    }
}
