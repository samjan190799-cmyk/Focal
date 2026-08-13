//
// ToDoListView.swift
// FocalApp
//
// Интерактивный список задач с анимацией зачеркивания и прикреплением медиа-миниатюр
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
public struct ToDoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: FocalNote
    @State private var selectedThumbnailData: Data? = nil
    @State private var showThumbnailSheet: Bool = false
    @State private var newTodoText: String = ""
    
    public init(note: FocalNote) {
        self.note = note
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок и кольцевой индикатор прогресса
            HStack {
                Text("Список задач")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Spacer()
                
                ProgressRingView(
                    progress: note.completionPercentage,
                    ratioText: note.completedRatioText,
                    ringSize: 32,
                    lineWidth: 4
                )
            }
            .padding(.bottom, 4)
            
            // Элементы задач
            if note.todoItems.isEmpty {
                Text("Нет задач")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(note.todoItems) { item in
                    ToDoItemRow(
                        item: item,
                        onToggle: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                item.isCompleted.toggle()
                                note.updatedAt = Date()
                                try? modelContext.save()
                            }
                            HapticManager.shared.impactMedium()
                        },
                        onDelete: {
                            withAnimation(.spring()) {
                                modelContext.delete(item)
                                note.todoItems.removeAll(where: { $0.id == item.id })
                                note.updatedAt = Date()
                                try? modelContext.save()
                            }
                            HapticManager.shared.impactLight()
                        },
                        onTapThumbnail: { data in
                            selectedThumbnailData = data
                            showThumbnailSheet = true
                        }
                    )
                }
            }
            
            // Инпут добавления новой задачи
            HStack(spacing: 8) {
                TextField("Новая задача...", text: $newTodoText)
                    .font(.system(size: 14, weight: .regular))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(10)
                    .onSubmit {
                        addNewItem()
                    }
                
                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(FocalTheme.gradientPrimary)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .sheet(isPresented: $showThumbnailSheet) {
            if let selectedThumbnailData {
                ThumbnailDetailView(imageData: selectedThumbnailData)
            }
        }
    }
    
    private func addNewItem() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        let textToAdd = trimmed.isEmpty ? "Новая задача" : trimmed
        
        let newItem = ToDoItem(text: textToAdd, isCompleted: false, priority: .medium)
        newItem.note = note
        modelContext.insert(newItem)
        if !note.todoItems.contains(where: { $0.id == newItem.id }) {
            note.todoItems.append(newItem)
        }
        note.updatedAt = Date()
        try? modelContext.save()
        newTodoText = ""
        HapticManager.shared.impactMedium()
    }
}

// MARK: - Строка задачи (ToDoItemRow)

@MainActor
public struct ToDoItemRow: View {
    @Bindable var item: ToDoItem
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onTapThumbnail: (Data) -> Void
    
    public var body: some View {
        HStack(spacing: 10) {
            // Интерактивный Чекбокс
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .scaleEffect(item.isCompleted ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
            
            // Редактируемый текст задачи с зачеркиванием при выполнении
            TextField("Задача...", text: $item.text)
                .font(.system(size: 14, weight: item.isCompleted ? .regular : .medium))
                .foregroundColor(item.isCompleted ? .secondary : .primary)
                .strikethrough(item.isCompleted, color: .secondary)
                .textFieldStyle(.plain)
            
            Spacer()
            
            // Бедж приоритета
            Menu {
                ForEach(Priority.allCases, id: \.self) { p in
                    Button(action: {
                        item.priority = p
                        HapticManager.shared.selection()
                    }) {
                        Text(p.titleRu)
                    }
                }
            } label: {
                Text(item.priority.titleRu)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(priorityColor(item.priority).opacity(0.18))
                    .foregroundColor(priorityColor(item.priority))
                    .cornerRadius(6)
            }
            
            // Кнопка удаления задачи
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            // Медиа-миниатюра при наличии
            if let thumbData = item.thumbnailData, let image = imageFromData(thumbData) {
                Button(action: { onTapThumbnail(thumbData) }) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return FocalTheme.priorityHigh
        case .medium: return FocalTheme.priorityMedium
        case .low: return FocalTheme.priorityLow
        }
    }
    
    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

// MARK: - Полноэкранный просмотрщик изображений (ThumbnailDetailView)

@MainActor
public struct ThumbnailDetailView: View {
    let imageData: Data
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            Spacer()
            
            if let image = imageFromData(imageData) {
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .padding()
            }
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}
