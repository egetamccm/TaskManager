//
//  ContentView.swift
//  TaskManager
//
//  Created by bansikah on 18/08/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TaskListViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: $viewModel.selectedFilter) {
                        ForEach(TaskFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !viewModel.pendingTasks.isEmpty {
                    Section("To Do") {
                        ForEach(viewModel.pendingTasks) { task in
                            TaskRowView(task: task) {
                                withAnimation {
                                    viewModel.toggleCompletion(for: task)
                                }
                            }
                        }
                        .onDelete { offsets in
                            withAnimation {
                                viewModel.deleteTasks(at: offsets, in: viewModel.pendingTasks)
                            }
                        }
                    }
                }

                if !viewModel.completedTasks.isEmpty {
                    Section("Completed") {
                        ForEach(viewModel.completedTasks) { task in
                            TaskRowView(task: task) {
                                withAnimation {
                                    viewModel.toggleCompletion(for: task)
                                }
                            }
                        }
                        .onDelete { offsets in
                            withAnimation {
                                viewModel.deleteTasks(at: offsets, in: viewModel.completedTasks)
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks Yet",
                        systemImage: "checklist",
                        description: Text("Add your first task below to get started.")
                    )
                } else if !viewModel.hasVisibleTasks {
                    ContentUnavailableView(
                        "Nothing Here",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try another filter. You're currently viewing \(viewModel.filterTitle()).")
                    )
                }
            }
            .navigationTitle("Task Manager")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.requestNotificationPermission()
                    } label: {
                        Label(
                            viewModel.notificationsEnabled ? "Reminders On" : "Enable Reminders",
                            systemImage: viewModel.notificationsEnabled ? "bell.fill" : "bell.badge"
                        )
                    }
                }

                if !viewModel.completedTasks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear Completed", role: .destructive) {
                            withAnimation {
                                viewModel.clearCompleted()
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addTaskBar
            }
            .task {
                await viewModel.refreshNotificationStatus()
            }
        }
    }

    private var addTaskBar: some View {
        VStack(spacing: 10) {
            TextField("Add a new task", text: $viewModel.newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    withAnimation {
                        viewModel.addTask()
                    }
                }

            HStack(spacing: 10) {
                Picker("Priority", selection: $viewModel.newTaskPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    viewModel.includeDueDate.toggle()
                } label: {
                    Label("Due", systemImage: viewModel.includeDueDate ? "calendar.badge.checkmark" : "calendar.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            if viewModel.includeDueDate {
                VStack(alignment: .leading, spacing: 6) {
                    DatePicker(
                        "Due",
                        selection: $viewModel.newTaskDueDate,
                        in: .now...,
                        displayedComponents: viewModel.includeDueTime ? [.date, .hourAndMinute] : .date
                    )
                    .datePickerStyle(.compact)

                    Toggle("Include time", isOn: $viewModel.includeDueTime)
                        .font(.caption)
                }
            }

            Button("Add") {
                withAnimation {
                    viewModel.addTask()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.canAddTask)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
