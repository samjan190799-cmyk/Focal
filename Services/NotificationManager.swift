//
// NotificationManager.swift
// FocalApp
//
// Менеджер локальных уведомлений UNUserNotificationCenter с фото-вложениями
//

import Foundation
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    /// Запрос прав на отправку уведомлений
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Ошибка запроса прав на уведомления: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Планирование локального уведомления с фото-вложением
    public func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        thumbnailData: Data? = nil
    ) async {
        let isAuthorized = await requestAuthorization()
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Добавление фото-вложения в уведомление при наличии
        if let thumbnailData, let attachment = createTempAttachment(from: thumbnailData, identifier: id) {
            content.attachments = [attachment]
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Ошибка добавления уведомления: \(error.localizedDescription)")
        }
    }
    
    /// Отмена запланированного уведомления
    public func cancelNotification(for id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    // MARK: - Вспомогательный метод сохранения во временный файл для UNNotificationAttachment
    private func createTempAttachment(from data: Data, identifier: String) -> UNNotificationAttachment? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(identifier)_thumb.jpg")
        
        do {
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(identifier: identifier, url: fileURL, options: nil)
            return attachment
        } catch {
            print("Не удалось создать attachment для уведомления: \(error)")
            return nil
        }
    }
}
