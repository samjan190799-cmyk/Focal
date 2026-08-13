//
// FocalWidget.swift
// FocalApp
//
// Виджет WidgetKit для отображения наиболее приоритетных и срочных задач на Home/Lock screen
//

import SwiftUI
import WidgetKit

public struct FocalWidgetEntry: TimelineEntry {
    public let date: Date
    public let urgentTasks: [UrgentTaskDTO]
    
    public init(date: Date, urgentTasks: [UrgentTaskDTO]) {
        self.date = date
        self.urgentTasks = urgentTasks
    }
}

public struct UrgentTaskDTO: Identifiable {
    public let id: UUID
    public let text: String
    public let priority: Priority
    public let noteTitle: String
    
    public init(id: UUID = UUID(), text: String, priority: Priority, noteTitle: String) {
        self.id = id
        self.text = text
        self.priority = priority
        self.noteTitle = noteTitle
    }
}

public struct FocalWidgetProvider: TimelineProvider {
    public func placeholder(in context: Context) -> FocalWidgetEntry {
        FocalWidgetEntry(date: Date(), urgentTasks: [
            UrgentTaskDTO(text: "Подготовить презентацию", priority: .high, noteTitle: "Проект Focal"),
            UrgentTaskDTO(text: "Отправить коммерческое предложение", priority: .medium, noteTitle: "Работа")
        ])
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (FocalWidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<FocalWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct FocalWidgetEntryView: View {
    var entry: FocalWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [FocalTheme.cardSurfaceDark, Color(red: 0.16, green: 0.18, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(FocalTheme.accentPastelPurple)
                    Text("Срочные задачи")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                if entry.urgentTasks.isEmpty {
                    Text("Все задачи выполнены! 🎉")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.urgentTasks.prefix(family == .systemSmall ? 2 : 4)) { task in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(task.priority == .high ? FocalTheme.priorityHigh : FocalTheme.priorityMedium)
                                    .frame(width: 6, height: 6)
                                
                                Text(task.text)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
}

public struct FocalWidget: Widget {
    let kind: String = "FocalWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocalWidgetProvider()) { entry in
            FocalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focal Срочные Задачи")
        .description("Отображает список приоритетных задач на рабочем столе.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
