import Foundation
import UserNotifications

protocol TaskNotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func syncNotifications(for tasks: [TaskItem]) async
}

struct LocalTaskNotificationScheduler: TaskNotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    private let idPrefix = "task-reminder-"

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func syncNotifications(for tasks: [TaskItem]) async {
        let requests = await center.pendingNotificationRequests()
        let existingTaskIds = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(idPrefix) }

        if !existingTaskIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: existingTaskIds)
        }

        let calendar = Calendar.current
        let now = Date()

        for task in tasks where !task.isCompleted {
            guard let dueDate = task.dueDate, dueDate > now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Task Reminder"
            content.body = task.title
            content.sound = .default

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: idPrefix + task.id.uuidString,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                continue
            }
        }
    }
}
