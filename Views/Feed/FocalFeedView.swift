//
// FocalFeedView.swift
// FocalApp
//
// Главная лента карточек заметок Focal с поиском, фильтрацией и добавлением заметок
//

import SwiftUI
import SwiftData

@MainActor
public struct FocalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocalNote.createdAt, order: .reverse) private var allNotes: [FocalNote]
    
    @State private var searchText: String = ""
    @State private var selectedFilter: FeedFilter = .all
    @AppStorage("userPreferredColorScheme") private var userPreferredColorScheme: String = "system"
    
    public enum FeedFilter: String, CaseIterable, Identifiable {
        case all = "Все"
        case bookmarked = "Закладки"
        case liked = "Любимые"
        case reminders = "Напоминания"
        
        public var id: String { rawValue }
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
            case .all: matchesFilter = true
            case .bookmarked: matchesFilter = note.isBookmarked
            case .liked: matchesFilter = note.isLiked
            case .reminders: matchesFilter = note.reminderDate != nil
            }
            
            if searchText.isEmpty {
                return matchesFilter
            } else {
                let textMatch = note.title.localizedCaseInsensitiveContains(searchText) ||
                    note.todoItems.contains(where: { $0.text.localizedCaseInsensitiveContains(searchText) })
                return matchesFilter && textMatch
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Классический фон системной группы (нейтральный светлый/темный)
                #if os(iOS)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                #else
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                #endif
                
                VStack(spacing: 12) {
                    // Панель поиска и фильтров
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Поиск заметок и задач...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(14)
                        .padding(.horizontal)
                        
                        // Сегментные фильтры
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FeedFilter.allCases) { filter in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                        HapticManager.shared.selection()
                                    }) {
                                        Text(filter.rawValue)
                                            .font(.system(size: 13, weight: .bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedFilter == filter ?
                                                AnyShapeStyle(FocalTheme.gradientPrimary) :
                                                AnyShapeStyle(Color.primary.opacity(0.07))
                                            )
                                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Лента карточек заметок
                    if filteredNotes.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 54))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("Нет заметок")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Нажмите '+', чтобы создать новую заметку")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: createNewNote) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Создать заметку")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(FocalTheme.gradientPrimary)
                                .cornerRadius(20)
                            }
                            .padding(.top, 6)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredNotes) { note in
                                    FocalCardView(note: note)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                
                // Плавающая FAB-кнопка создания новой заметки
                Button(action: createNewNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(FocalTheme.gradientPrimary)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Focal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
                                    Text("Классическая Светлая")
                                    if userPreferredColorScheme == "light" { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { userPreferredColorScheme = "dark" }) {
                                HStack {
                                    Text("Классическая Темная")
                                    if userPreferredColorScheme == "dark" { Image(systemName: "checkmark") }
                                }
                            }
                        }
                        
                        if !allNotes.isEmpty {
                            Section {
                                Button(role: .destructive, action: deleteAllNotes) {
                                    Label("Удалить все заметки", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: userPreferredColorScheme == "dark" ? "moon.fill" : (userPreferredColorScheme == "light" ? "sun.max.fill" : "circle.half.filled"))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createNewNote) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(colorSchemeOverride)
        .onAppear {
            cleanDemoData()
        }
    }
    
    private func cleanDemoData() {
        var needsSave = false
        for note in allNotes {
            let isDemoTitle = note.title == "Новая заметка Focal" || note.title == "Запуск проекта Focal" || note.title == "Идеи дизайна и UI 2026"
            let hasDemoTasks = note.todoItems.contains(where: {
                $0.text == "Нажмите для редактирования" ||
                $0.text == "Спроектировать SwiftData схему" ||
                $0.text == "Реализовать Neumorphic Feed" ||
                $0.text == "Протестировать ContrastEngine" ||
                $0.text == "Настроить тактильную отдачу (Haptics)" ||
                $0.text == "Экспорт Story 9:16"
            })
            if isDemoTitle || hasDemoTasks {
                modelContext.delete(note)
                needsSave = true
            }
        }
        if needsSave {
            try? modelContext.save()
        }
    }
    
    private func createNewNote() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            let newNote = FocalNote(
                title: "",
                backgroundMode: .fullBleed
            )
            newNote.todoItems = []
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

