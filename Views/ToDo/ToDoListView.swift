//
// ToDoListView.swift
// FocalApp
//
// Интерактивный список задач с анимацией зачеркивания и прикреплением медиа-миниатюр
//

import SwiftUI
import SwiftData

public struct ToDoListView: View {
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
                Text("Нет добавлена задач")
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
                            }
                            HapticManager.shared.impact(.medium)
                        },
                        onTapThumbnail: { data in
                            selectedThumbnailData = data
                            showThumbnailSheet = true
                        }
                    )
                }
            }
            
            // Инпут добавления новой задачи
            HStack {
                TextField("Новая задача...", text: $newTodoText)
                    .font(.system(size: 14, weight: .regular))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                
                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(FocalTheme.gradientPrimary)
                }
                .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
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
        guard !trimmed.isEmpty else { return }
        
        let newItem = ToDoItem(text: trimmed, isCompleted: false, priority: .medium)
        note.todoItems.append(newItem)
        note.updatedAt = Date()
        newTodoText = ""
        HapticManager.shared.impact(.light)
    }
}

// MARK: - Строка задачи (ToDoItemRow)

public struct ToDoItemRow: View {
    @Bindable var item: ToDoItem
    var onToggle: () -> Void
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
            
            // Текст задачи с анимированным зачеркиванием
            Text(item.text)
                .font(.system(size: 14, weight: item.isCompleted ? .regular : .medium))
                .foregroundColor(item.isCompleted ? .secondary : .primary)
                .strikethrough(item.isCompleted, color: .secondary)
            
            Spacer()
            
            // Бедж приоритета
            Text(item.priority.titleRu)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor(item.priority).opacity(0.15))
                .foregroundColor(priorityColor(item.priority))
                .cornerRadius(6)
            
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
