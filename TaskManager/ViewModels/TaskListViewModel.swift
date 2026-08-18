import Foundation
import UserNotifications

protocol TaskStoring {
    func loadTasks() -> [TaskItem]
    func saveTasks(_ tasks: [TaskItem])
}

struct UserDefaultsTaskStore: TaskStoring {
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storageKey: String = "task_items") {
        self.storageKey = storageKey
    }

    func loadTasks() -> [TaskItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try decoder.decode([TaskItem].self, from: data)
        } catch {
            return []
        }
    }

    func saveTasks(_ tasks: [TaskItem]) {
        do {
            let data = try encoder.encode(tasks)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to encode tasks: \(error)")
        }
    }
}

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = [] {
        didSet {
            store.saveTasks(tasks)
            Task {
                await syncNotifications()
            }
        }
    }

    @Published var newTaskTitle = ""
    @Published var newTaskPriority: TaskPriority = .medium
    @Published var includeDueDate = false
    @Published var includeDueTime = false
    @Published var newTaskDueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @Published var selectedFilter: TaskFilter = .all
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let store: TaskStoring
    private let notificationScheduler: TaskNotificationScheduling

    init(
        store: TaskStoring = UserDefaultsTaskStore(),
        notificationScheduler: TaskNotificationScheduling = LocalTaskNotificationScheduler()
    ) {
        self.store = store
        self.notificationScheduler = notificationScheduler
        loadTasks()

        Task {
            await refreshNotificationStatus()
            await syncNotifications()
        }
    }

    var pendingTasks: [TaskItem] {
        switch selectedFilter {
        case .all, .active:
            return sortedPendingTasks(from: tasks.filter { !$0.isCompleted })
        case .completed:
            return []
        }
    }

    var completedTasks: [TaskItem] {
        switch selectedFilter {
        case .all, .completed:
            return sortedCompletedTasks(from: tasks.filter { $0.isCompleted })
        case .active:
            return []
        }
    }

    var hasVisibleTasks: Bool {
        !pendingTasks.isEmpty || !completedTasks.isEmpty
    }

    var canAddTask: Bool {
        !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var notificationsEnabled: Bool {
        notificationStatus == .authorized || notificationStatus == .provisional
    }

    var notificationsDenied: Bool {
        notificationStatus == .denied
    }

    var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "Reminders are enabled"
        case .provisional:
            return "Reminders are provisionally enabled"
        case .denied:
            return "Reminders are blocked in system settings"
        case .notDetermined:
            return "Reminder permission not requested yet"
        case .ephemeral:
            return "Reminders are temporarily enabled"
        @unknown default:
            return "Reminder status unknown"
        }
    }

    func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        let normalizedDueDate = normalizedDueDateForNewTask()

        tasks.insert(
            TaskItem(
                title: trimmedTitle,
                priority: newTaskPriority,
                dueDate: normalizedDueDate
            ),
            at: 0
        )

        if normalizedDueDate != nil && notificationStatus == .notDetermined {
            requestNotificationPermission()
        }

        newTaskTitle = ""
        newTaskPriority = .medium
        includeDueDate = false
        includeDueTime = false
        newTaskDueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    func toggleCompletion(for task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        tasks[index].isCompleted.toggle()
    }

    func deleteTasks(at offsets: IndexSet, in items: [TaskItem]) {
        let idsToDelete = Set(offsets.compactMap { index in
            items.indices.contains(index) ? items[index].id : nil
        })

        tasks.removeAll { idsToDelete.contains($0.id) }
    }

    func clearCompleted() {
        tasks.removeAll { $0.isCompleted }
    }

    func requestNotificationPermission() {
        Task {
            _ = await notificationScheduler.requestAuthorization()
            await refreshNotificationStatus()
            await syncNotifications()
        }
    }

    func refreshNotificationStatus() async {
        notificationStatus = await notificationScheduler.authorizationStatus()
    }

    #if DEBUG
    func replaceTasksForTesting(_ items: [TaskItem]) {
        tasks = items
    }
    #endif

    private func loadTasks() {
        let savedTasks = store.loadTasks()
        guard !savedTasks.isEmpty else {
            tasks = [
                TaskItem(title: "Create your first task", priority: .high),
                TaskItem(title: "Plan this week's priorities", priority: .medium),
                TaskItem(title: "Swipe left to delete", isCompleted: true, priority: .low)
            ]
            return
        }

        tasks = savedTasks
    }

    private func sortedPendingTasks(from items: [TaskItem]) -> [TaskItem] {
        items.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (left?, right?):
                if left != right {
                    return left < right
                }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }

            if lhs.priority.sortRank != rhs.priority.sortRank {
                return lhs.priority.sortRank > rhs.priority.sortRank
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    private func sortedCompletedTasks(from items: [TaskItem]) -> [TaskItem] {
        items.sorted { $0.createdAt > $1.createdAt }
    }

    private func normalizedDueDateForNewTask() -> Date? {
        guard includeDueDate else {
            return nil
        }

        if includeDueTime {
            return newTaskDueDate
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: newTaskDueDate)
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components)
    }

    private func syncNotifications() async {
        guard notificationsEnabled else {
            return
        }

        await notificationScheduler.syncNotifications(for: tasks)
    }

    func filterTitle() -> String {
        switch selectedFilter {
        case .all:
            return "all tasks"
        case .active:
            return "active tasks"
        case .completed:
            return "completed tasks"
        }
    }
}
