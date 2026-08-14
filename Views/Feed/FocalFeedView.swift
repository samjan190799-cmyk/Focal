//
// FocalFeedView.swift
// FocalApp
//
// Единый ультра-премиальный полноэкранный интерфейс Focal («Saved News» Design System)
// Унифицированная концепция для всех экранов: Заметки, Задачи, Закладки, Любимые и Напоминания.
//

import SwiftUI
import SwiftData

@MainActor
public struct FocalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocalNote.createdAt, order: .reverse) private var allNotes: [FocalNote]
    
    @State private var searchText: String = ""
    @State private var selectedFilter: FeedFilter = .notes
    @State private var viewMode: ViewMode = .interactiveDeck
    @State private var activeCardIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @AppStorage("userPreferredColorScheme") private var userPreferredColorScheme: String = "system"
    
    public enum ViewMode {
        case interactiveDeck // Веерная колода со свайпом
        case cascadeList     // Каскадная скролл-лента
    }
    
    public enum FeedFilter: String, CaseIterable, Identifiable {
        case notes = "Заметки"
        case tasks = "Задачи"
        case bookmarked = "Закладки"
        case liked = "Любимые"
        case reminders = "Напоминания"
        
        public var id: String { rawValue }
        
        public var headerTitle: String {
            switch self {
            case .notes: return "Saved Notes"
            case .tasks: return "Saved Tasks"
            case .bookmarked: return "Bookmarks"
            case .liked: return "Favorites"
            case .reminders: return "Reminders"
            }
        }
    }
    
    public init() {}
    
    private var colorSchemeOverride: ColorScheme? {
        switch userPreferredColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    public var filteredNotes: [FocalNote] {
        allNotes.filter { note in
            let matchesFilter: Bool
            switch selectedFilter {
            case .notes:
                matchesFilter = note.todoItems.isEmpty || !note.bodyText.isEmpty || !note.title.isEmpty
            case .tasks:
                matchesFilter = !note.todoItems.isEmpty
            case .bookmarked:
                matchesFilter = note.isBookmarked
            case .liked:
                matchesFilter = note.isLiked
            case .reminders:
                matchesFilter = note.reminderDate != nil
            }
            
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
            if trimmedSearch.isEmpty {
                return matchesFilter
            } else {
                let textMatch = note.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                    note.bodyText.localizedCaseInsensitiveContains(trimmedSearch) ||
                    note.todoItems.contains(where: { $0.text.localizedCaseInsensitiveContains(trimmedSearch) })
                return matchesFilter && textMatch
            }
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Глубокий тёмный фон во весь экран (Saved News Style)
            Color(red: 0.08, green: 0.08, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // MARK: - Единая Полноэкранная Шапка
                HStack(spacing: 14) {
                    // Переключатель темы / Меню
                    Menu {
                        Section("Оформление темы") {
                            Button(action: { userPreferredColorScheme = "system" }) {
                                HStack {
                                    Text("Системная")
                                    if userPreferredColorScheme == "system" { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { userPreferredColorScheme = "light" }) {
                                HStack {
                                    Text("Светлая")
                                    if userPreferredColorScheme == "light" { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { userPreferredColorScheme = "dark" }) {
                                HStack {
                                    Text("Тёмная")
                                    if userPreferredColorScheme == "dark" { Image(systemName: "checkmark") }
                                }
                            }
                        }
                        
                        if !allNotes.isEmpty {
                            Section {
                                Button(role: .destructive, action: deleteAllNotes) {
                                    Label("Очистить все", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: userPreferredColorScheme == "dark" ? "moon.fill" : (userPreferredColorScheme == "light" ? "sun.max.fill" : "circle.half.filled"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedFilter.headerTitle)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(filteredNotes.count) элементов в стеке")
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
                .padding(.top, 50) // Полноэкранный уход под верхний край устройства
                
                // MARK: - Поисковая Строка (Search Bar)
                HStack(spacing: 10) {
                    TextField("Search notes and tasks...", text: $searchText)
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
                
                // MARK: - Чипсы категорий и фильтров
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FeedFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                    activeCardIndex = 0
                                }
                                HapticManager.shared.selection()
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ?
                                        AnyShapeStyle(Color.white) :
                                        AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                                    .foregroundColor(selectedFilter == filter ? .black : .white)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Контент каскадного стека карточек
                if filteredNotes.isEmpty {
                    EmptyStateUnifiedDeckView(
                        filter: selectedFilter,
                        onCreate: { createNewItem(for: selectedFilter) }
                    )
                } else if viewMode == .interactiveDeck {
                    // ИНТЕРАКТИВНЫЙ ВЕЕР КАРТОЧЕК (DECK)
                    UnifiedInteractiveDeckView(
                        notes: filteredNotes,
                        selectedFilter: selectedFilter,
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
                    // КАСКАДНАЯ СКРОЛЛ-ЛЕНТА (CASCADE LIST)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: -60) {
                            ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                                UnifiedSavedCard(
                                    note: note,
                                    index: index,
                                    totalCount: filteredNotes.count,
                                    selectedFilter: selectedFilter
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
            UnifiedFloatingNavigationDock(
                selectedFilter: $selectedFilter,
                onCreate: { createNewItem(for: selectedFilter) }
            )
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
        .preferredColorScheme(colorSchemeOverride)
    }
    
    private func createNewItem(for filter: FeedFilter) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            let newNote = FocalNote(
                title: "",
                bodyText: "",
                backgroundMode: .fullBleed
            )
            if filter == .tasks {
                let initialTask = ToDoItem(text: "", isCompleted: false, priority: .medium)
                initialTask.note = newNote
                newNote.todoItems = [initialTask]
            } else {
                newNote.todoItems = []
                if filter == .bookmarked { newNote.isBookmarked = true }
                if filter == .liked { newNote.isLiked = true }
            }
            modelContext.insert(newNote)
            try? modelContext.save()
        }
        HapticManager.shared.impactMedium()
    }
    
    private func deleteAllNotes() {
        withAnimation(.spring()) {
            for note in allNotes {
                modelContext.delete(note)
            }
            try? modelContext.save()
        }
        HapticManager.shared.notification(1)
    }
}

// MARK: - Интерактивный Веер Карточек

@MainActor
struct UnifiedInteractiveDeckView: View {
    let notes: [FocalNote]
    let selectedFilter: FocalFeedView.FeedFilter
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
                    
                    UnifiedSavedCard(
                        note: note,
                        index: itemIndex,
                        totalCount: count,
                        selectedFilter: selectedFilter
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

// MARK: - Универсальная Пастельная Карточка (Saved News Style)

@MainActor
public struct UnifiedSavedCard: View {
    @Bindable var note: FocalNote
    let index: Int
    let totalCount: Int
    let selectedFilter: FocalFeedView.FeedFilter
    
    var body: some View {
        let pastelBg = FocalTheme.pastelColor(for: index)
        let textDark = Color(red: 0.10, green: 0.10, blue: 0.14)
        
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок карточки и номер
            HStack {
                TextField("Название...", text: $note.title)
                    .font(.system(size: 22, weight: .bold, design: note.fontDesignStyle))
                    .foregroundColor(textDark)
                
                Spacer()
                
                Text("#\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.08))
                    .foregroundColor(textDark.opacity(0.8))
                    .cornerRadius(8)
            }
            
            // Основное содержимое: Списки задач ИЛИ Чистый текст заметки
            if !note.todoItems.isEmpty {
                ToDoListView(note: note)
                    .padding(10)
                    .background(Color.white.opacity(0.55))
                    .cornerRadius(16)
            } else {
                ZStack(alignment: .topLeading) {
                    if note.bodyText.isEmpty {
                        Text("Нажмите, чтобы написать заметку...")
                            .font(.system(size: 14, weight: .regular, design: note.fontDesignStyle))
                            .foregroundColor(textDark.opacity(0.45))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                    
                    TextEditor(text: $note.bodyText)
                        .font(.system(size: 14, weight: .regular, design: note.fontDesignStyle))
                        .foregroundColor(textDark)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 110, maxHeight: 180)
                }
                .padding(6)
                .background(Color.white.opacity(0.55))
                .cornerRadius(16)
            }
            
            // Метаданные автора и время
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
                
                // Кнопка сохранения / Закладка
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
            
            // Нижняя панель действий (Лайк / Поделиться)
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

// MARK: - Пустое Состояние (Empty State)

@MainActor
struct EmptyStateUnifiedDeckView: View {
    let filter: FocalFeedView.FeedFilter
    var onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(FocalTheme.gradientPrimary)
            }
            
            Text("Стек пуст")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Нажмите '+', чтобы добавить элемент в раздел \(filter.rawValue)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreate) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Создать новый элемент")
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

// MARK: - Единый Нижний Навигационный Док (Unified Floating Dock)

@MainActor
struct UnifiedFloatingNavigationDock: View {
    @Binding var selectedFilter: FocalFeedView.FeedFilter
    var onCreate: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 🏠 Заметки (Home)
            Button(action: {
                withAnimation(.spring()) { selectedFilter = .notes }
                HapticManager.shared.selection()
            }) {
                ZStack {
                    if selectedFilter == .notes {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)
            
            // ➕ Создать новый элемент
            Button(action: {
                onCreate()
            }) {
                ZStack {
                    Circle()
                        .fill(FocalTheme.accentPastelPurple)
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            // 🔖 Задачи (Saved Tasks)
            Button(action: {
                withAnimation(.spring()) { selectedFilter = .tasks }
                HapticManager.shared.selection()
            }) {
                ZStack {
                    if selectedFilter == .tasks {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)
            
            // ❤️ Любимые (Favorites)
            Button(action: {
                withAnimation(.spring()) { selectedFilter = .liked }
                HapticManager.shared.selection()
            }) {
                ZStack {
                    if selectedFilter == .liked {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)
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
