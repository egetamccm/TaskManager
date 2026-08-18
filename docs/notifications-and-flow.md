# Notifications And App Flow

This document explains the reminder fix, the runtime flow, and the architecture flow.

## What Was Fixed

If a due time passed while the app was open, iOS could suppress notification UI unless foreground presentation was explicitly enabled.

To fix that, we added:

- A notification center delegate that allows banner, sound, and list while app is active.
- App-level delegate wiring so the notification delegate is registered at launch.
- A view-model improvement to request permission when adding a dated task and authorization has not been decided yet.

## Reminder Delivery Flow

```mermaid
flowchart TD
    A[User adds task] --> B{Task has due date/time?}
    B -- No --> C[Save task only]
    B -- Yes --> D[Save task]
    D --> E{Notification permission status}
    E -- Not determined --> F[Request authorization]
    E -- Authorized/Provisional --> G[Sync reminders]
    F --> H{User allows?}
    H -- Yes --> G
    H -- No --> I[No reminder scheduled]
    G --> J[Create UNCalendarNotificationTrigger]
    J --> K[System delivers at due time]
```

## Foreground Notification Flow

```mermaid
flowchart LR
    N1[Local notification fires] --> N2{App state}
    N2 -- Background --> N3[System shows notification]
    N2 -- Foreground --> N4[UNUserNotificationCenterDelegate willPresent]
    N4 --> N5[Return banner + sound + list]
    N5 --> N6[Notification visible while app is open]
```

## Architecture Flow

```mermaid
flowchart TD
    V[Views: ContentView + TaskRowView] --> VM[TaskListViewModel]
    VM --> S1[TaskStoring]
    VM --> S2[TaskNotificationScheduling]
    S1 --> UD[UserDefaultsTaskStore]
    S2 --> NS[LocalTaskNotificationScheduler]
    VM --> M[TaskItem Model]
```

## Code You Can Type Manually

This is the delegate used to make reminders visible while the app is open:

```swift
import Foundation
import UserNotifications

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
```

This is the app launch wiring that activates that behavior:

```swift
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = NotificationCenterDelegate()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}
```
