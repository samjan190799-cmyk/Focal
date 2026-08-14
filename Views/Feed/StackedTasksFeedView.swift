//
// StackedTasksFeedView.swift
// FocalApp
//
// Интерактивный каскадный стек пастельных карточек задач в точном стиле «Saved News»
// с поддержкой плавного свайпа, драг-жестов и плавающего нижнего дока.
//

import SwiftUI
import SwiftData

@MainActor
public struct StackedTasksFeedView: View {
    var notes: [FocalNote]
    var onCreateNote: () -> Void
    
    @State private var searchText: String = ""
    @State private var activeCardIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var viewMode: ViewMode = .interactiveDeck
    @Environment(\.dismiss) private var dismiss
    
    public enum ViewMode {
        case interactiveDeck // Веерная колода со свайпом
        case cascadeList     // Каскадная скролл-лента
    }
    
    public init(notes: [FocalNote], onCreateNote: @escaping () -> Void) {
        self.notes = notes
        self.onCreateNote = onCreateNote
    }
    
    public var filteredNotes: [FocalNote] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return notes
        }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.todoItems.contains(where: { $0.text.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Глубокий тёмный фон как на макете «Saved News»
            Color(red: 0.08, green: 0.08, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // MARK: - Шапка экрана в стиле «Saved News»
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.impactLight()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Text("Saved Tasks")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Переключатель режима отображения (Веер / Лента)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewMode = (viewMode == .interactiveDeck) ? .cascadeList : .interactiveDeck
                        }
                        HapticManager.shared.selection()
                    }) {
                        Image(systemName: viewMode == .interactiveDeck ? "square.stack.3d.up.fill" : "rectangle.grid.1x2.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // MARK: - Строка поиска (Search Bar)
                HStack(spacing: 12) {
                    TextField("Search tasks", text: $searchText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.trailing, 16)
                }
                .frame(height: 50)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                // MARK: - Контент с карточками задач
                if filteredNotes.isEmpty {
                    EmptyStateSavedTasksView(onCreateNote: onCreateNote)
                } else if viewMode == .interactiveDeck {
                    // ИНТЕРАКТИВНАЯ КОЛОДА КАРТОЧЕК СО СВАЙПОМ
                    InteractiveDeckView(
                        notes: filteredNotes,
                        dragOffset: $dragOffset,
                        activeCardIndex: $activeCardIndex,
                        onSwipeNext: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                activeCardIndex = (activeCardIndex + 1) % max(1, filteredNotes.count)
                                dragOffset = .zero
                            }
                            HapticManager.shared.impactMedium()
                        }
                    )
                } else {
                    // ВЕРТИКАЛЬНАЯ КАСКАДНАЯ СКРОЛЛ-ЛЕНТА
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: -65) {
                            ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                                SavedNewsTaskCard(
                                    note: note,
                                    index: index,
                                    totalCount: filteredNotes.count,
                                    isTopCard: false
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // MARK: - Нижний плавающий док (Floating Navigation Dock)
            SavedNewsFloatingDockView(onCreateNote: onCreateNote)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - Интерактивный веер карточек с реалистичной физикой свайпа

@MainActor
struct InteractiveDeckView: View {
    let notes: [FocalNote]
    @Binding var dragOffset: CGSize
    @Binding var activeCardIndex: Int
    var onSwipeNext: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let count = notes.count
                let safeIndex = activeCardIndex % max(1, count)
                
                // Отображаем до 4 висящих карточек в глубине стопки
                ForEach(0..<min(4, count), id: \.self) { stackPos in
                    let itemIndex = (safeIndex + stackPos) % count
                    let note = notes[itemIndex]
                    let isTop = (stackPos == 0)
                    
                    let yOffset = CGFloat(stackPos * 28) + (isTop ? dragOffset.height * 0.4 : 0)
                    let xOffset = isTop ? dragOffset.width : 0
                    let scale = 1.0 - (CGFloat(stackPos) * 0.05) + (isTop ? 0.02 : 0)
                    let rotation = isTop ? Double(dragOffset.width / 18.0) : Double(stackPos * 2 - 2)
                    
                    SavedNewsTaskCard(
                        note: note,
                        index: itemIndex,
                        totalCount: count,
                        isTopCard: isTop
                    )
                    .scaleEffect(scale)
                    .offset(x: xOffset, y: yOffset)
                    .rotationEffect(.degrees(rotation))
                    .zIndex(Double(count - stackPos))
                    .gesture(
                        isTop ?
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
                                if abs(value.translation.width) > threshold || abs(value.translation.height) > threshold {
                                    onSwipeNext()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                    }
                                }
                            } : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

// MARK: - Дизайн пастельной карточки задачи в стиле «Saved News»

@MainActor
public struct SavedNewsTaskCard: View {
    @Bindable var note: FocalNote
    let index: Int
    let totalCount: Int
    let isTopCard: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public var body: some View {
        let pastelBg = FocalTheme.pastelColor(for: index)
        let textDark = Color(red: 0.10, green: 0.10, blue: 0.14)
        
        VStack(alignment: .leading, spacing: 14) {
            // Верхняя часть: Заголовок и метка времени
            HStack {
                Text(note.title.isEmpty ? "Без названия" : note.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textDark)
                    .lineLimit(2)
                
                Spacer()
                
                // Бейдж категории / индекса
                Text("#\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.08))
                    .foregroundColor(textDark.opacity(0.8))
                    .cornerRadius(8)
            }
            
            // Краткий предварительный просмотр текста/описания
            let previewText = note.todoItems.map { "• " + $0.text }.joined(separator: "\n")
            if !previewText.isEmpty {
                Text(previewText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textDark.opacity(0.75))
                    .lineLimit(4)
                    .lineSpacing(3)
            }
            
            // Внутренний интерактивный блок задач To-Do
            ToDoListView(note: note)
                .padding(10)
                .background(Color.white.opacity(0.55))
                .cornerRadius(16)
            
            // Аватар автора и метаданные
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(FocalTheme.accentPastelPurple.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(FocalTheme.accentPastelPurple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Создано")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textDark.opacity(0.5))
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textDark)
                }
                
                Spacer()
                
                // Кнопка Статуса / Закладки
                Button(action: {
                    withAnimation(.spring()) {
                        note.isBookmarked.toggle()
                        try? note.modelContext?.save()
                    }
                    HapticManager.shared.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: note.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 12, weight: .bold))
                        Text(note.isBookmarked ? "Saved" : "Save")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            
            // Нижняя панель действий (Like / Bookmark / Share)
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        note.isLiked.toggle()
                        try? note.modelContext?.save()
                    }
                    HapticManager.shared.impactLight()
                }) {
                    Image(systemName: note.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(note.isLiked ? .blue : textDark.opacity(0.6))
                        .padding(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    HapticManager.shared.selection()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textDark.opacity(0.6))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(pastelBg)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 16, x: 0, y: 10)
    }
}

// MARK: - Элемент пустого состояния (Empty State)

@MainActor
struct EmptyStateSavedTasksView: View {
    var onCreateNote: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "bookmark.circle.fill")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(FocalTheme.gradientPrimary)
            }
            
            Text("Нет сохранённых задач")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Создайте свою первую задачу в стиле Saved News с помощью кнопки ниже")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreateNote) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Добавить задачу")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(FocalTheme.pastelCream)
                .cornerRadius(24)
                .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - Нижний плавающий док (Saved News Floating Navigation Dock)

@MainActor
struct SavedNewsFloatingDockView: View {
    var onCreateNote: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Кнопка Home
            Button(action: {
                HapticManager.shared.selection()
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            
            // Кнопка Search / Add
            Button(action: {
                onCreateNote()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            
            // Выделенный активный таб «Saved / Bookmarks»
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}
