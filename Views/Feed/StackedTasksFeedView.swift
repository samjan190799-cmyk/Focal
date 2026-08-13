//
// StackedTasksFeedView.swift
// FocalApp
//
// Ультра-плавный каскадный стек пастельных карточек задач в стиле премиального UI
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
                VStack(spacing: 18) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(FocalTheme.accentPastelPurple.opacity(0.12))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundColor(FocalTheme.accentPastelPurple)
                    }
                    
                    Text("Каскадный стек задач пуст")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Нажмите '+', чтобы добавить новую задачу в стопку")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: onCreateNote) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Создать первую задачу")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(FocalTheme.gradientPrimary)
                        .cornerRadius(24)
                        .shadow(color: FocalTheme.accentPastelPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: -55) {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                            StackedCardItemRow(
                                note: note,
                                index: index,
                                totalCount: notes.count
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
                .scrollBounceBehavior(.always)
            }
        }
    }
}

// MARK: - Элемент пастельной каскадной карточки (StackedCardItemRow)

@MainActor
public struct StackedCardItemRow: View {
    @Bindable var note: FocalNote
    let index: Int
    let totalCount: Int
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded: Bool = false
    
    public var body: some View {
        let pastelBg = FocalTheme.pastelColor(for: index)
        let isDarkTheme = colorScheme == .dark && note.backgroundImageData == nil
        let textPrimaryColor: Color = isDarkTheme ? Color.primary : (note.backgroundImageData != nil ? .white : Color(red: 0.10, green: 0.10, blue: 0.14))
        
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Задний фон: Пастельный цвет или загруженное фоновое фото
                if note.backgroundImageData != nil {
                    BackgroundViewManager(
                        mode: note.backgroundMode,
                        imageData: note.backgroundImageData,
                        blurRadius: note.blurRadius,
                        overlayOpacity: note.overlayOpacity
                    )
                } else {
                    pastelBg
                }
                
                // Содержимое карточки
                VStack(alignment: .leading, spacing: 14) {
                    // Верхний бар с индикатором стопки и названием
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(FocalTheme.accentPastelPurple)
                                .frame(width: 8, height: 8)
                            
                            Text("КАРТОЧКА ЗАДАЧ #\(index + 1)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(textPrimaryColor.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.06))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textPrimaryColor.opacity(0.6))
                    }
                    
                    // Поле названия задачи
                    TextField("Заголовок задачи...", text: $note.title)
                        .font(.system(size: 22, weight: .bold, design: note.fontDesignStyle))
                        .foregroundColor(textPrimaryColor)
                        .padding(.horizontal, 4)
                    
                    // Внутренний список чек-листов задач (ToDoListView)
                    ToDoListView(note: note)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.65))
                        )
                    
                    // Нижний компактный док-бар действий
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
                    
                    // Панель действий с кнопками Like/Share/Bookmark
                    CardActionBarView(
                        note: note,
                        onShare: {},
                        onReminderTap: {}
                    )
                }
                .padding(18)
            }
        }
        .frame(minHeight: 320)
        .background(note.backgroundImageData == nil ? pastelBg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 8)
        .zIndex(Double(totalCount - index))
    }
}
