//
// iPhoneDockToolbarView.swift
// FocalApp
//
// Компактная плавающая панель инструментов в стиле iPad Dock, адаптированная для iPhone
//

import SwiftUI
import PhotosUI

@MainActor
public struct iPhoneDockToolbarView: View {
    @Bindable var note: FocalNote
    var onAddBlock: () -> Void
    var onAddList: () -> Void
    var onToggleStyles: () -> Void
    var onOpenSettings: () -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    public init(
        note: FocalNote,
        onAddBlock: @escaping () -> Void,
        onAddList: @escaping () -> Void,
        onToggleStyles: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.note = note
        self.onAddBlock = onAddBlock
        self.onAddList = onAddList
        self.onToggleStyles = onToggleStyles
        self.onOpenSettings = onOpenSettings
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 1. + Блок (NEW BLOCK)
            Button(action: onAddBlock) {
                VStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                    Text("БЛОК")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundColor(.primary)
                .frame(minWidth: 44)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 24)
            
            // 2. ≡ Список (LIST)
            Button(action: onAddList) {
                VStack(spacing: 3) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 15, weight: .bold))
                    Text("СПИСОК")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundColor(.primary)
                .frame(minWidth: 44)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 24)
            
            // 3. 📎 Медиа (ATTACH MEDIA - Photo Background Picker)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 3) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 15, weight: .bold))
                    Text("МЕДИА")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundColor(.primary)
                .frame(minWidth: 44)
            }
            .buttonStyle(.plain)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            withAnimation(.spring()) {
                                note.backgroundImageData = data
                            }
                            HapticManager.shared.notification(1)
                        }
                    }
                }
            }
            
            Divider()
                .frame(height: 24)
            
            // 4. 🎨 Стили (STYLES & INSPECTOR)
            Button(action: onToggleStyles) {
                VStack(spacing: 3) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold))
                    Text("СТИЛИ")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundColor(FocalTheme.accentPastelPurple)
                .frame(minWidth: 44)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 24)
            
            // 5. ⚙️ ЕЩЕ (SETTINGS)
            Button(action: onOpenSettings) {
                VStack(spacing: 3) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                    Text("ЕЩЕ")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundColor(.primary)
                .frame(minWidth: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassmorphicCard(opacity: 0.25, cornerRadius: 20)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
