//
// FocalFeedView.swift
// FocalApp
//
// Главная лента карточек заметок Focal с поиском, фильтрацией и добавлением заметок
//

import SwiftUI
import SwiftData

public struct FocalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocalNote.createdAt, order: .reverse) private var allNotes: [FocalNote]
    
    @State private var searchText: String = ""
    @State private var selectedFilter: FeedFilter = .all
    @State private var isCreatingNote: Bool = false
    
    public enum FeedFilter: String, CaseIterable, Identifiable {
        case all = "Все"
        case bookmarked = "Закладки"
        case liked = "Любимые"
        case reminders = "Напоминания"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
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
                // Фоновый гранжево-пастельный софт градиент
                LinearGradient(
                    colors: [FocalTheme.backgroundLight, Color(red: 0.90, green: 0.92, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
                        .padding(10)
                        .glassmorphicCard(opacity: 0.2, cornerRadius: 14)
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
                                                AnyShapeStyle(Color.primary.opacity(0.06))
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
                        VStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("Нет заметок")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("Нажмите '+', чтобы создать первую визуальную заметку Focal")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(FocalTheme.gradientPrimary)
                        .clipShape(Circle())
                        .shadow(color: FocalTheme.accentPastelPurple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Focal")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: seedSampleData) {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
        }
    }
    
    private func createNewNote() {
        let newNote = FocalNote(
            title: "Новая заметка Focal",
            backgroundMode: .fullBleed
        )
        let sampleTask = ToDoItem(text: "Нажмите для редактирования", isCompleted: false, priority: .medium)
        newNote.todoItems.append(sampleTask)
        
        modelContext.insert(newNote)
        HapticManager.shared.impact(.medium)
    }
    
    private func seedSampleData() {
        let note1 = FocalNote(
            title: "Запуск проекта Focal",
            isLiked: true,
            isBookmarked: true,
            backgroundMode: .structuredTop
        )
        note1.todoItems = [
            ToDoItem(text: "Спроектировать SwiftData схему", isCompleted: true, priority: .high),
            ToDoItem(text: "Реализовать Neumorphic Feed", isCompleted: true, priority: .high),
            ToDoItem(text: "Протестировать ContrastEngine", isCompleted: false, priority: .medium)
        ]
        
        let note2 = FocalNote(
            title: "Идеи дизайна и UI 2026",
            isLiked: false,
            isBookmarked: true,
            backgroundMode: .floating
        )
        note2.todoItems = [
            ToDoItem(text: "Настроить тактильную отдачу (Haptics)", isCompleted: true, priority: .medium),
            ToDoItem(text: "Экспорт Story 9:16", isCompleted: false, priority: .low)
        ]
        
        modelContext.insert(note1)
        modelContext.insert(note2)
        HapticManager.shared.notification(.success)
    }
}
