import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }

    var sortRank: Int {
        switch self {
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var priority: TaskPriority
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.priority = priority
        self.dueDate = dueDate
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else {
            return false
        }

        return dueDate < .now
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case createdAt
        case priority
        case dueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
    }
}
