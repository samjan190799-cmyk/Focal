//
// FocalCardView.swift
// FocalApp
//
// Визуальная карточка заметки Focal с неоморфным стилем, адаптивным контрастом и интерактивным содержимым
//

import SwiftUI
import SwiftData

@MainActor
public struct FocalCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: FocalNote
    
    @State private var textColor: Color = .primary
    @State private var shadowOpacity: Double = 0.0
    @State private var showInspector: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedReminderDate: Date = Date().addingTimeInterval(3600)
    @State private var showExportPreview: Bool = false
    @State private var exportedImage: Image? = nil
    
    public init(note: FocalNote) {
        self.note = note
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Визуальный движок фона (Background Engine)
                BackgroundViewManager(
                    mode: note.backgroundMode,
                    imageData: note.backgroundImageData,
                    blurRadius: note.blurRadius,
                    overlayOpacity: note.overlayOpacity
                )
                
                // Контент карточки поверх фона
                VStack(alignment: .leading, spacing: 14) {
                    // Шапка заметки в стиле iPad ("FOR ANNA" style с бейджем перетаскивания и выбором шрифта)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("DRAG")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.12))
                                .cornerRadius(4)
                                .foregroundColor(textColor.opacity(0.7))
                            
                            Spacer()
                            
                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                        
                        TextField("Название заметки...", text: $note.title)
                            .font(.system(size: 22, weight: .bold, design: note.fontDesignStyle))
                            .foregroundColor(textColor)
                            .shadow(color: .black.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
                    }
                    .padding(12)
                    .glassmorphicCard(opacity: 0.2, cornerRadius: 16)
                    
                    // Панель живого инспектора (BLUR %, OVERLAY %, FONTS & POSITION)
                    if showInspector {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ИНСПЕКТОР ФОНА И ШРИФТОВ")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { withAnimation(.spring()) { showInspector = false } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 1. Блюр фона (BLUR 0-100%)
                            HStack {
                                Text("BLUR \(Int(note.blurRadius * 5))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $note.blurRadius, in: 0...20)
                            }
                            
                            // 2. Затемнение (OVERLAY 0-100%)
                            HStack {
                                Text("OVERLAY \(Int(note.overlayOpacity * 125))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $note.overlayOpacity, in: 0...0.8)
                            }
                            
                            // 3. Выбор гарнитуры шрифта (FONTS: Serif / Sans / Rounded)
                            HStack(spacing: 8) {
                                Text("ШРИФТ:")
                                    .font(.system(size: 11, weight: .bold))
                                
                                Button("Serif") {
                                    withAnimation { note.setFontDesign(.serif) }
                                }
                                .buttonStyle(.bordered)
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                
                                Button("Sans") {
                                    withAnimation { note.setFontDesign(.default) }
                                }
                                .buttonStyle(.bordered)
                                .font(.system(size: 11, weight: .bold, design: .default))
                                
                                Button("Rounded") {
                                    withAnimation { note.setFontDesign(.rounded) }
                                }
                                .buttonStyle(.bordered)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                        }
                        .padding(12)
                        .glassmorphicCard(opacity: 0.3, cornerRadius: 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Блок со списком задач ACTIVE TASKS (RICH LIST)
                    ToDoListView(note: note)
                        .padding(12)
                        .glassmorphicCard(opacity: 0.15, cornerRadius: 18)
                    
                    Spacer(minLength: 8)
                    
                    // Компактная нижняя док-панель инструментов iPhone (iPhone Dock Toolbar)
                    iPhoneDockToolbarView(
                        note: note,
                        onAddBlock: {
                            let newItem = ToDoItem(text: "Новый блок", isCompleted: false)
                            newItem.note = note
                            modelContext.insert(newItem)
                            note.todoItems.append(newItem)
                            try? modelContext.save()
                            HapticManager.shared.impactMedium()
                        },
                        onAddList: {
                            let newItem = ToDoItem(text: "Новая задача", isCompleted: false)
                            newItem.note = note
                            modelContext.insert(newItem)
                            note.todoItems.append(newItem)
                            try? modelContext.save()
                            HapticManager.shared.impactMedium()
                        },
                        onToggleStyles: {
                            withAnimation(.spring()) {
                                showInspector.toggle()
                            }
                            HapticManager.shared.selection()
                        },
                        onOpenSettings: {
                            showExportPreview = false
                        }
                    )
                    .padding(.top, 4)
                    
                    // Нижняя панель действий (Card Action Bar: Like, Bookmark, Reminder, Share)
                    CardActionBarView(
                        note: note,
                        onShare: {
                            generateExportStory()
                        },
                        onReminderTap: {
                            showDatePicker = true
                        }
                    )
                }
                .padding(14)
            }
        }
        .frame(minHeight: 400)
        .neumorphicCard(cornerRadius: 24)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear {
            updateContrast()
        }
        .onChange(of: note.backgroundImageData) { _, _ in
            updateContrast()
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 20) {
                Text("Установите напоминание")
                    .font(.headline)
                    .padding(.top)
                
                DatePicker("Время напоминания", selection: $selectedReminderDate, in: Date()...)
                    .datePickerStyle(.graphical)
                    .padding()
                
                HStack(spacing: 16) {
                    Button("Удалить") {
                        note.reminderDate = nil
                        NotificationManager.shared.cancelNotification(for: note.id.uuidString)
                        showDatePicker = false
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Сохранить") {
                        note.reminderDate = selectedReminderDate
                        Task {
                            await NotificationManager.shared.scheduleNotification(
                                id: note.id.uuidString,
                                title: note.title.isEmpty ? "Заметка Focal" : note.title,
                                body: "Не забудьте выполнить задачи (\(note.completedRatioText))",
                                date: selectedReminderDate,
                                thumbnailData: note.todoItems.first(where: { $0.thumbnailData != nil })?.thumbnailData
                            )
                        }
                        showDatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showExportPreview) {
            if let exportedImage {
                VStack(spacing: 16) {
                    Text("Экспорт заметки (9:16 Story)")
                        .font(.headline)
                        .padding(.top)
                    
                    exportedImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 500)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    
                    Button("Закрыть") {
                        showExportPreview = false
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom)
                }
            }
        }
    }
    
    private func updateContrast() {
        if note.backgroundImageData != nil {
            withAnimation {
                self.textColor = .white
                self.shadowOpacity = 0.6
            }
        } else {
            withAnimation {
                self.textColor = .primary
                self.shadowOpacity = 0.0
            }
        }
    }
    
    private func generateExportStory() {
        Task {
            if let image = await ExportManager.shared.renderStory(for: note) {
                self.exportedImage = image
                self.showExportPreview = true
            }
        }
    }
    
    private func deleteNote() {
        withAnimation(.spring()) {
            modelContext.delete(note)
            try? modelContext.save()
        }
        HapticManager.shared.impactMedium()
    }
}

