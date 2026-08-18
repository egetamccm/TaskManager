import XCTest
@testable import TaskManager

@MainActor
final class TaskListViewModelTests: XCTestCase {
    func testAddTaskTrimsInputAndStoresMetadata() {
        let store = InMemoryTaskStore(seed: [TaskItem(title: "seed")])
        let viewModel = TaskListViewModel(store: store)

        viewModel.replaceTasksForTesting([])
        viewModel.newTaskTitle = "  Buy groceries  "
        viewModel.newTaskPriority = .high
        viewModel.includeDueDate = true
        viewModel.newTaskDueDate = Date(timeIntervalSince1970: 1_800_000_000)

        viewModel.addTask()

        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks[0].title, "Buy groceries")
        XCTAssertEqual(viewModel.tasks[0].priority, .high)
        XCTAssertNotNil(viewModel.tasks[0].dueDate)
    }

    func testFilterReturnsExpectedSections() {
        let store = InMemoryTaskStore(seed: [TaskItem(title: "seed")])
        let viewModel = TaskListViewModel(store: store)

        viewModel.replaceTasksForTesting([
            TaskItem(title: "A", isCompleted: false, priority: .low),
            TaskItem(title: "B", isCompleted: true, priority: .high)
        ])

        viewModel.selectedFilter = .active
        XCTAssertEqual(viewModel.pendingTasks.count, 1)
        XCTAssertEqual(viewModel.completedTasks.count, 0)

        viewModel.selectedFilter = .completed
        XCTAssertEqual(viewModel.pendingTasks.count, 0)
        XCTAssertEqual(viewModel.completedTasks.count, 1)

        viewModel.selectedFilter = .all
        XCTAssertEqual(viewModel.pendingTasks.count, 1)
        XCTAssertEqual(viewModel.completedTasks.count, 1)
    }

    func testClearCompletedRemovesOnlyCompletedTasks() {
        let store = InMemoryTaskStore(seed: [TaskItem(title: "seed")])
        let viewModel = TaskListViewModel(store: store)

        viewModel.replaceTasksForTesting([
            TaskItem(title: "A", isCompleted: false),
            TaskItem(title: "B", isCompleted: true),
            TaskItem(title: "C", isCompleted: true)
        ])

        viewModel.clearCompleted()

        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks[0].title, "A")
    }
}

private final class InMemoryTaskStore: TaskStoring {
    private var stored: [TaskItem]

    init(seed: [TaskItem] = []) {
        self.stored = seed
    }

    func loadTasks() -> [TaskItem] {
        stored
    }

    func saveTasks(_ tasks: [TaskItem]) {
        stored = tasks
    }
}
