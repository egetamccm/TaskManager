import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .strikethrough(task.isCompleted, color: .secondary)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .animation(.default, value: task.isCompleted)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                priorityBadge

                if let dueDate = task.dueDate {
                    Label {
                        Text(Self.dueDateFormatter.string(from: dueDate))
                    } icon: {
                        Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                    }
                    .font(.caption2)
                    .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
    }

    private var priorityBadge: some View {
        Text(task.priority.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priorityColor.opacity(0.18), in: Capsule())
            .foregroundStyle(priorityColor)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    List {
        TaskRowView(task: TaskItem(title: "Read SwiftUI docs", priority: .high, dueDate: .now), onToggle: {})
        TaskRowView(task: TaskItem(title: "Ship first version", isCompleted: true, priority: .low), onToggle: {})
    }
}
