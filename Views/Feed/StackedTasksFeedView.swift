//
// StackedTasksFeedView.swift
// FocalApp
//
// Ультра-премиальный полноэкранный интерфейс сохранённых задач («Saved Tasks»)
// с каскадным стек-веером карточек, фильтрацией статусов, поиском и плавающим доком.
//

import SwiftUI
import SwiftData

@MainActor
public struct StackedTasksFeedView: View {
    var notes: [FocalNote]
    var onCreateNote: () -> Void
    var onSwitchToNotes: () -> Void
    
    @State private var searchText: String = ""
    @State private var taskStatusFilter: TaskStatusFilter = .all
    @State private var activeCardIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var viewMode: ViewMode = .interactiveDeck
    
    public enum ViewMode {
        case interactiveDeck // Веерная колода со свайпом
        case cascadeList     // Каскадная скролл-лента
    }
    
    public enum TaskStatusFilter: String, CaseIterable, Identifiable {
        case all = "Все"
        case active = "Активные"
        case completed = "Завершённые"
        case highPriority = "Приоритет"
        
        public var id: String { rawValue }
    }
    
    public init(
        notes: [FocalNote],
        onCreateNote: @escaping () -> Void,
        onSwitchToNotes: @escaping () -> Void
    ) {
        self.notes = notes
        self.onCreateNote = onCreateNote
        self.onSwitchToNotes = onSwitchToNotes
    }
    
    public var filteredNotes: [FocalNote] {
        notes.filter { note in
            // Фильтр только заметок с задачами
            guard !note.todoItems.isEmpty else { return false }
            
            // Фильтр по статусу
            let matchesStatus: Bool
            switch taskStatusFilter {
            case .all:
                matchesStatus = true
            case .active:
                matchesStatus = note.todoItems.contains(where: { !$0.isCompleted })
            case .completed:
                matchesStatus = !note.todoItems.isEmpty && note.todoItems.allSatisfy({ $0.isCompleted })
            case .highPriority:
                matchesStatus = note.todoItems.contains(where: { $0.priority == .high })
            }
            
            // Фильтр по поисковому тексту
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
            if trimmedSearch.isEmpty {
                return matchesStatus
            } else {
                let matchesSearch = note.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                note.todoItems.contains(where: { $0.text.localizedCaseInsensitiveContains(trimmedSearch) })
                return matchesStatus && matchesSearch
            }
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Глубокий тёмный фон во весь экран
            Color(red: 0.08, green: 0.08, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // MARK: - Полноэкранная Шапка в стиле «Saved News»
                HStack(spacing: 14) {
                    Button(action: {
                        HapticManager.shared.impactLight()
                        onSwitchToNotes()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saved Tasks")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(filteredNotes.count) задач в стеке")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Переключатель режима отображения (Веер ↔ Лента)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewMode = (viewMode == .interactiveDeck) ? .cascadeList : .interactiveDeck
                        }
                        HapticManager.shared.selection()
                    }) {
                        Image(systemName: viewMode == .interactiveDeck ? "square.stack.3d.up.fill" : "rectangle.grid.1x2.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50) // Бесшовный уход под статус-бар
                
                // MARK: - Единственная Поисковая Строка (Search Bar)
                HStack(spacing: 10) {
                    TextField("Search tasks...", text: $searchText)
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
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 16)
                }
                .frame(height: 48)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                // MARK: - Чипсы быстрых фильтров статуса
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TaskStatusFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    taskStatusFilter = filter
                                    activeCardIndex = 0
                                }
                                HapticManager.shared.selection()
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        taskStatusFilter == filter ?
                                        AnyShapeStyle(Color.white) :
                                        AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                                    .foregroundColor(taskStatusFilter == filter ? .black : .white)
                                    .cornerRadius(18)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Контент карточек задач
                if filteredNotes.isEmpty {
                    EmptyStateSavedTasksView(onCreateNote: onCreateNote)
                } else if viewMode == .interactiveDeck {
                    // ИНТЕРАКТИВНАЯ ВЕЕРНАЯ КОЛОДА
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
                    // ВЕРТИКАЛЬНАЯ КАСКАДНАЯ СТРОЛЛ-ЛЕНТА
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: -60) {
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
            
            // MARK: - Единый Нижний Навигационный Док (Floating Navigation Dock)
            SavedNewsFloatingDockView(
                onCreateNote: onCreateNote,
                onSwitchToNotes: onSwitchToNotes
            )
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Интерактивный веер карточек

@MainActor
struct InteractiveDeckView: View {
    let notes: [FocalNote]
    @Binding var dragOffset: CGSize
    @Binding var activeCardIndex: Int
    var onSwipeNext: () -> Void
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                let count = notes.count
                let safeIndex = activeCardIndex % max(1, count)
                
                ForEach(0..<min(4, count), id: \.self) { stackPos in
                    let itemIndex = (safeIndex + stackPos) % count
                    let note = notes[itemIndex]
                    let isTop = (stackPos == 0)
                    
                    let yOffset = CGFloat(stackPos * 26) + (isTop ? dragOffset.height * 0.4 : 0)
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
            // Верхняя часть: Заголовок задачи и метка номера
            HStack {
                Text(note.title.isEmpty ? "Без названия" : note.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textDark)
                    .lineLimit(2)
                
                Spacer()
                
                Text("#\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.08))
                    .foregroundColor(textDark.opacity(0.8))
                    .cornerRadius(8)
            }
            
            // Краткое описание / подзадачи
            let previewText = note.todoItems.map { "• " + $0.text }.joined(separator: "\n")
            if !previewText.isEmpty {
                Text(previewText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textDark.opacity(0.75))
                    .lineLimit(3)
                    .lineSpacing(2)
            }
            
            // Внутренний интерактивный список задач
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
                
                // Кнопка сохранения / закладки
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
            
            // Панель действий с кнопками Лайк / Поделиться
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

// MARK: - Пустое состояние (Empty State)

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

// MARK: - Единый плавающий навигационный док (Saved News Floating Navigation Dock)

@MainActor
struct SavedNewsFloatingDockView: View {
    var onCreateNote: () -> Void
    var onSwitchToNotes: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Кнопка Home (Возврат к заметкам)
            Button(action: {
                HapticManager.shared.selection()
                onSwitchToNotes()
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            
            // Центральная кнопка Добавления Задачи (+)
            Button(action: {
                onCreateNote()
            }) {
                ZStack {
                    Circle()
                        .fill(FocalTheme.accentPastelPurple)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            // Выделенный активный таб «Saved Tasks / Bookmarks»
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
        .background(Color.black.opacity(0.88))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 22, x: 0, y: 10)
    }
}
