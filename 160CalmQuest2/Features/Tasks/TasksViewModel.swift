//
//  TasksViewModel.swift
//  160CalmQuest2
//

import Combine
import Foundation

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var filter: TaskFilter = .all
    @Published var editorTask: TaskItem?
    @Published var isAdding: Bool = false

    func filtered(from tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { filter.includes($0) }.sorted(by: sortTasks)
    }

    func sections(filtered tasks: [TaskItem]) -> [(TaskStatus, [TaskItem])] {
        let statuses = TaskStatus.allCases
        return statuses.compactMap { status in
            let rows = tasks.filter { $0.status == status }
            guard !rows.isEmpty else { return nil }
            return (status, rows.sorted(by: sortTasks))
        }
    }

    private func sortTasks(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.prioritySortingIndex != rhs.prioritySortingIndex {
            return lhs.prioritySortingIndex < rhs.prioritySortingIndex
        }
        switch (lhs.dueDate, rhs.dueDate) {
        case let (l?, r?): if l != r { return l < r }
        case (_?, nil): return true
        case (nil, _?): return false
        default: break
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

private extension TaskItem {
    var prioritySortingIndex: Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}
