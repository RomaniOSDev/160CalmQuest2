//
//  TaskModels.swift
//  160CalmQuest2
//

import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo
    case inProgress
    case completed

    var id: String { rawValue }

    var sectionTitle: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

struct SubtaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct TaskItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var category: String
    var priority: TaskPriority
    var status: TaskStatus
    var subtasks: [SubtaskItem]
    var dueDate: Date?
    var reminderDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        priority: TaskPriority,
        status: TaskStatus = .todo,
        subtasks: [SubtaskItem] = [],
        dueDate: Date? = nil,
        reminderDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
        self.status = status
        self.subtasks = subtasks
        self.dueDate = dueDate
        self.reminderDate = reminderDate
    }

    var completedSubtaskCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    func subtasksProgressLabel() -> String? {
        guard !subtasks.isEmpty else { return nil }
        return "\(completedSubtaskCount)/\(subtasks.count)"
    }
}

extension TaskItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case priority
        case status
        case subtasks
        case dueDate
        case reminderDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(String.self, forKey: .category)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        status = try c.decode(TaskStatus.self, forKey: .status)
        subtasks = try c.decodeIfPresent([SubtaskItem].self, forKey: .subtasks) ?? []
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        reminderDate = try c.decodeIfPresent(Date.self, forKey: .reminderDate)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(category, forKey: .category)
        try c.encode(priority, forKey: .priority)
        try c.encode(status, forKey: .status)
        try c.encode(subtasks, forKey: .subtasks)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encodeIfPresent(reminderDate, forKey: .reminderDate)
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case todo
    case inProgress
    case completed
    case dueToday
    case dueThisWeek
    case overdue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .dueToday: return "Today"
        case .dueThisWeek: return "Week"
        case .overdue: return "Overdue"
        }
    }

    func includes(_ task: TaskItem, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        switch self {
        case .all:
            return true
        case .todo:
            return task.status == .todo
        case .inProgress:
            return task.status == .inProgress
        case .completed:
            return task.status == .completed
        case .dueToday:
            guard task.status != .completed, let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: now)
        case .dueThisWeek:
            guard task.status != .completed, let due = task.dueDate else { return false }
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
            return weekInterval.contains(due)
        case .overdue:
            guard task.status != .completed, let due = task.dueDate else { return false }
            let startOfToday = calendar.startOfDay(for: now)
            return due < startOfToday
        }
    }
}

struct QuickTaskTemplate: Identifiable {
    let title: String
    let category: String

    var id: String { "\(title)|\(category)" }

    static let builtIn: [QuickTaskTemplate] = [
        QuickTaskTemplate(title: "Email", category: "Work"),
        QuickTaskTemplate(title: "Call", category: "Work"),
        QuickTaskTemplate(title: "Meeting", category: "Work"),
        QuickTaskTemplate(title: "Follow up", category: "General"),
    ]
}
