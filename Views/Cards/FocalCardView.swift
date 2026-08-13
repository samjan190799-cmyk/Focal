//
// FocalCardView.swift
// FocalApp
//
// Визуальная карточка заметки Focal с неоморфным стилем, адаптивным контрастом и интерактивным содержимым
//

import SwiftUI
import SwiftData

public struct FocalCardView: View {
    @Bindable var note: FocalNote
    
    @State private var textColor: Color = .primary
    @State private var shadowOpacity: Double = 0.0
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
                    // Шапка заметки
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Название заметки...", text: $note.title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(textColor)
                                .shadow(color: .black.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
                            
                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(textColor.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Селектор режима фона
                        Menu {
                            ForEach(BackgroundMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        note.backgroundMode = mode
                                    }
                                    HapticManager.shared.selection()
                                }) {
                                    HStack {
                                        Text(mode.titleRu)
                                        if note.backgroundMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                                .foregroundColor(textColor)
                        }
                    }
                    
                    Divider()
                        .background(textColor.opacity(0.3))
                    
                    // Блок со списком задач To-Do
                    ToDoListView(note: note)
                        .padding(12)
                        .glassmorphicCard(opacity: 0.15, cornerRadius: 18)
                    
                    Spacer(minLength: 12)
                    
                    // Нижняя панель действий (Action Bar)
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
                .padding(16)
            }
        }
        .frame(minHeight: 380)
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
        let analysis = ContrastEngine.shared.analyzeLuminance(imageData: note.backgroundImageData)
        withAnimation {
            self.textColor = analysis.recommendedColor
            self.shadowOpacity = analysis.shadowOpacity
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
}
