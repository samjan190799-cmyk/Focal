//
// SettingsView.swift
// FocalApp
//
// Полнофункциональный экран настроек Focal: темы оформления, тактильный отклик,
// чувствительность свайпов и управление данными.
//

import SwiftUI
import SwiftData

@MainActor
public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [FocalNote]
    
    @AppStorage("userPreferredColorScheme") private var userPreferredColorScheme: String = "system"
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("hapticIntensity") private var hapticIntensity: String = "medium"
    @AppStorage("swipeSensitivity") private var swipeSensitivity: Double = 80.0
    @AppStorage("defaultFontDesign") private var defaultFontDesign: String = "rounded"
    @AppStorage("appLanguage") private var appLanguage: String = "ru"
    
    @State private var showDeleteConfirmation: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.10)
                    .ignoresSafeArea()
                
                List {
                    // MARK: - 0. Язык и Локализация
                    let currentLang = AppLanguage(rawValue: appLanguage) ?? .russian
                    Section(header: Text(currentLang.localizedSettingsHeader).foregroundColor(.white.opacity(0.6))) {
                        Picker(currentLang.localizedLanguagePickerTitle, selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: appLanguage) { _, _ in
                            HapticManager.shared.selection()
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // MARK: - 1. Оформление и Темы
                    Section(header: Text("Внешний вид и Тема").foregroundColor(.white.opacity(0.6))) {
                        Picker("Тема оформления", selection: $userPreferredColorScheme) {
                            Text("Системная").tag("system")
                            Text("Тёмная «Saved News»").tag("dark")
                            Text("Светлая").tag("light")
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Шрифт заметок", selection: $defaultFontDesign) {
                            Text("Скруглённый (Rounded)").tag("rounded")
                            Text("Классический (Sans)").tag("default")
                            Text("с засечками (Serif)").tag("serif")
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // MARK: - 2. Свайпы и Жесты
                    Section(header: Text("Жесты и Листание карточек").foregroundColor(.white.opacity(0.6))) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Порог свайпа")
                                Spacer()
                                Text("\(Int(swipeSensitivity)) px")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FocalTheme.accentPastelPurple)
                            }
                            
                            Slider(value: $swipeSensitivity, in: 40...140, step: 10)
                                .tint(FocalTheme.accentPastelPurple)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // MARK: - 3. Тактильный отклик (Haptics)
                    Section(header: Text("Вибрация и Тактильный отклик").foregroundColor(.white.opacity(0.6))) {
                        Toggle("Тактильный отклик Taptic Engine", isOn: $hapticFeedbackEnabled)
                            .tint(FocalTheme.accentPastelPurple)
                            .onChange(of: hapticFeedbackEnabled) { _, newValue in
                                if newValue { HapticManager.shared.impactMedium() }
                            }
                        
                        if hapticFeedbackEnabled {
                            Picker("Сила отклика", selection: $hapticIntensity) {
                                Text("Слабая").tag("light")
                                Text("Средняя").tag("medium")
                                Text("Сильная").tag("heavy")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: hapticIntensity) { _, level in
                                switch level {
                                case "light": HapticManager.shared.impactLight()
                                case "heavy": HapticManager.shared.impactHeavy()
                                default: HapticManager.shared.impactMedium()
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // MARK: - 4. Данные и Память
                    Section(header: Text("Данные и Хранилище").foregroundColor(.white.opacity(0.6))) {
                        HStack {
                            Text("Всего элементов")
                            Spacer()
                            Text("\(allNotes.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Удалить все данные")
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // MARK: - 5. Информация о приложении
                    Section(header: Text("О приложении").foregroundColor(.white.opacity(0.6))) {
                        HStack {
                            Text("Версия Focal")
                            Spacer()
                            Text("1.2 (Build 2026)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Сборка")
                            Spacer()
                            Text("Swift 6 Strict Concurrency")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FocalTheme.accentPastelPurple)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }
            .confirmationDialog("Вы уверены, что хотите удалить все элементы?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить всё", role: .destructive) {
                    withAnimation {
                        for note in allNotes {
                            modelContext.delete(note)
                        }
                        try? modelContext.save()
                    }
                    HapticManager.shared.notification(1)
                }
                Button("Отмена", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }
}
