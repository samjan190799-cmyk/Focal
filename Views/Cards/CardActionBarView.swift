//
// CardActionBarView.swift
// FocalApp
//
// Нижняя панель действий карточки: Like, Bookmark, Share (Story 9:16) и Напоминание
//

import SwiftUI

public struct CardActionBarView: View {
    @Bindable var note: FocalNote
    var onShare: () -> Void
    var onReminderTap: () -> Void
    
    public var body: some View {
        HStack(spacing: 20) {
            // Кнопка Лайка (с анимированным переключением и откликом)
            Button(action: toggleLike) {
                HStack(spacing: 4) {
                    Image(systemName: note.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(note.isLiked ? .red : .primary.opacity(0.7))
                        .scaleEffect(note.isLiked ? 1.2 : 1.0)
                }
            }
            .buttonStyle(.plain)
            
            // Кнопка Закладки
            Button(action: toggleBookmark) {
                Image(systemName: note.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(note.isBookmarked ? FocalTheme.accentPastelPurple : .primary.opacity(0.7))
                    .scaleEffect(note.isBookmarked ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Кнопка Напоминания (с индикатором активной даты)
            Button(action: onReminderTap) {
                HStack(spacing: 4) {
                    Image(systemName: note.reminderDate == nil ? "bell" : "bell.badge.fill")
                        .foregroundColor(note.reminderDate == nil ? .primary.opacity(0.7) : .orange)
                    if let reminderDate = note.reminderDate {
                        Text(reminderDate.formatted(date: .numeric, time: .shortened))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Кнопка Поделиться (Экспорт в 9:16 Story)
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.primary.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassmorphicCard(opacity: 0.2, cornerRadius: 16)
    }
    
    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            note.isLiked.toggle()
        }
        HapticManager.shared.impactLight()
    }
    
    private func toggleBookmark() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            note.isBookmarked.toggle()
        }
        HapticManager.shared.impactLight()
    }
}
