//
// StackedTasksFeedView.swift
// FocalApp
//
// Каскадный стек пастельных карточек для раздела «Задачи» с плавной физикой скролла
//

import SwiftUI
import SwiftData

@MainActor
public struct StackedTasksFeedView: View {
    var notes: [FocalNote]
    var onCreateNote: () -> Void
    
    public init(notes: [FocalNote], onCreateNote: @escaping () -> Void) {
        self.notes = notes
        self.onCreateNote = onCreateNote
    }
    
    public var body: some View {
        Group {
            if notes.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text("Нет активных задач")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Создайте свою первую задачу в каскадном стеке")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: onCreateNote) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Создать задачу")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(FocalTheme.gradientPrimary)
                        .cornerRadius(22)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: -38) {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                            StackedCardItemRow(
                                note: note,
                                index: index,
                                totalCount: notes.count
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 60)
                }
                .scrollBounceBehavior(.always)
            }
        }
    }
}

// MARK: - Элемент каскадной карточки в стеке (StackedCardItemRow)

@MainActor
public struct StackedCardItemRow: View {
    @Bindable var note: FocalNote
    let index: Int
    let totalCount: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    public var body: some View {
        let cardBgColor = note.backgroundImageData == nil ? FocalTheme.pastelColor(for: index) : Color.clear
        let isDarkTheme = colorScheme == .dark && note.backgroundImageData == nil
        let textPrimaryColor: Color = isDarkTheme ? Color.primary : (note.backgroundImageData != nil ? .white : Color(red: 0.12, green: 0.12, blue: 0.16))
        
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Движок фона (Картинка или Пастельный цвет из палитры)
                if note.backgroundImageData != nil {
                    BackgroundViewManager(
                        mode: note.backgroundMode,
                        imageData: note.backgroundImageData,
                        blurRadius: note.blurRadius,
                        overlayOpacity: note.overlayOpacity
                    )
                } else {
                    cardBgColor
                }
                
                // Контент карточки
                VStack(alignment: .leading, spacing: 12) {
                    // Шапка каскадной карточки
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("ЗАДАЧА #\(index + 1)")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.08))
                                    .cornerRadius(4)
                                    .foregroundColor(textPrimaryColor.opacity(0.8))
                                
                                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(textPrimaryColor.opacity(0.7))
                            }
                            
                            TextField("Название задачи...", text: $note.title)
                                .font(.system(size: 20, weight: .bold, design: note.fontDesignStyle))
                                .foregroundColor(textPrimaryColor)
                        }
                        
                        Spacer()
                    }
                    .padding(10)
                    .glassmorphicCard(opacity: 0.2, cornerRadius: 14)
                    
                    // Блок со списком задач ACTIVE TASKS (RICH LIST)
                    ToDoListView(note: note)
                        .padding(10)
                        .glassmorphicCard(opacity: 0.15, cornerRadius: 16)
                    
                    // Нижняя док-панель инструментов iPhone
                    iPhoneDockToolbarView(
                        note: note,
                        onAddBlock: {
                            let newItem = ToDoItem(text: "Новый блок", isCompleted: false)
                            newItem.note = note
                            note.todoItems.append(newItem)
                            HapticManager.shared.impactMedium()
                        },
                        onAddList: {
                            let newItem = ToDoItem(text: "Новая задача", isCompleted: false)
                            newItem.note = note
                            note.todoItems.append(newItem)
                            HapticManager.shared.impactMedium()
                        },
                        onToggleStyles: {},
                        onOpenSettings: {}
                    )
                    .padding(.top, 2)
                    
                    // Нижняя панель действий (Card Action Bar)
                    CardActionBarView(
                        note: note,
                        onShare: {},
                        onReminderTap: {}
                    )
                }
                .padding(14)
            }
        }
        .frame(minHeight: 340)
        .background(cardBgColor)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 6)
        .zIndex(Double(totalCount - index))
    }
}
