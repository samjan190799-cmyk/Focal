//
// FocalApp.swift
// FocalApp
//
// Точка входа приложения Focal с инициализацией контейнера SwiftData и CloudKit
//

import SwiftUI
import SwiftData

@main
struct FocalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocalNote.self,
            ToDoItem.self,
            CanvasElement.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            FocalFeedView()
        }
        .modelContainer(sharedModelContainer)
    }
}
