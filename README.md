# Focal — Visual-First Notes & Task Manager (iOS / macOS)

**Focal** — это визуальный менеджер заметок и задач нового поколения, построенный с использованием SwiftUI 6, SwiftData и CloudKit. Проект разработан в соответствии со стандартами разработки 2026 года (Strict Concurrency, `@Observable`, `@MainActor`, Clean Architecture).

---

## 🎨 Ключевые возможности

1. **Card Feed & Action Bar Engine**:
   - Лента неоморфных карточек заметок с интерактивной нижней панелью действий (Heart Like, Bookmark, Reminder, Story Export).
   - `ContrastEngine`: Автоматический расчет яркости фонового изображения через CoreImage (`CIAreaAverage`) и ITU-R BT.709 для наилучшей читаемости текста.

2. **Background Visual Engine**:
   - **Full Bleed**: Фоновое изображение во всю ширину карточки с регулируемым `blurRadius` и оверлеем.
   - **Structured Layout**: Баннер 1/3 сверху или снизу карточки, текст располагается в независимой чистой области.
   - **Floating Object**: Свободный объект на холсте с жестами перетаскивания (Drag), масштабирования (Pinch) и вращения.

3. **To-Do & Rich Lists**:
   - `ProgressRingView`: Анимированный кольцевой индикатор выполнения задач ("3/5").
   - Чекбоксы с плавным зачеркиванием текста (`.strikethrough(isCompleted)`).
   - Прикрепление фото-вложений (thumbnail) к отдельным задачам с просмотром в полноэкранном режиме.

4. **Reminders, WidgetKit & Story Export**:
   - Планирование локальных уведомлений `UNUserNotificationCenter` с добавлением фото-вложений.
   - Экспорт заметки в 9:16 Story формат для соцсетей через `ImageRenderer`.
   - `FocalWidget`: Виджет WidgetKit для отображения приоритетных задач на рабочем столе.

---

## 📁 Структура проекта `FocalApp`

```
FocalApp/
├── FocalApp.swift                     # Точка входа SwiftUI со SwiftData + CloudKit
├── Models/
│   ├── Enums.swift                    # BackgroundMode, Priority, ElementType
│   ├── FocalNote.swift                # Главная сущность заметки (@Model)
│   ├── ToDoItem.swift                 # Элемент списка задач с медиа-вложением (@Model)
│   └── CanvasElement.swift            # Свободный элемент холста (@Model)
├── Theme/
│   ├── FocalTheme.swift               # Неоморфизм, глассморфизм, палитра и тени
│   └── HapticManager.swift            # Менеджер тактильной отдачи (Haptics)
├── Utilities/
│   └── ContrastEngine.swift           # Динамический расчет контрастности через CoreImage
├── Views/
│   ├── Feed/
│   │   └── FocalFeedView.swift        # Лента заметок с поиском и фильтрами
│   ├── Cards/
│   │   ├── FocalCardView.swift        # Визуальная карточка заметки
│   │   └── CardActionBarView.swift    # Панель действий (лайк, закладка, экспорт)
│   ├── Backgrounds/
│   │   └── BackgroundViewManager.swift# Менеджер фонов (Full Bleed, Structured, Floating)
│   └── ToDo/
│       ├── ToDoListView.swift         # Интерактивный список задач
│       └── ProgressRingView.swift     # Кольцевой индикатор выполнения
├── Services/
│   ├── NotificationManager.swift      # Локальные уведомления UNUserNotificationCenter
│   └── ExportManager.swift            # Экспорт карточки 9:16 Story (ImageRenderer)
└── Widget/
    └── FocalWidget.swift              # Код виджета WidgetKit
```

---

## 🚀 Требования к сборке

- **Swift**: 6.0+ (Strict Concurrency Enabled)
- **iOS**: 17.0+
- **macOS**: 14.0+
- **Xcode**: 15.0+ / 16.0+
