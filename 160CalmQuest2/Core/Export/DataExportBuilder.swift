//
//  DataExportBuilder.swift
//  160CalmQuest2
//

import Foundation

enum DataExportBuilder {
    private static func escapeCsvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func csvTasks(_ tasks: [TaskItem]) -> String {
        var lines: [String] = [
            "id,title,category,priority,status,due_date_iso,reminder_date_iso,subtasks_done,subtasks_total",
        ]
        let df = isoFormatter
        for t in tasks {
            let due = t.dueDate.map { df.string(from: $0) } ?? ""
            let rem = t.reminderDate.map { df.string(from: $0) } ?? ""
            let done = t.completedSubtaskCount
            let total = t.subtasks.count
            let row = [
                t.id.uuidString,
                escapeCsvField(t.title),
                escapeCsvField(t.category),
                t.priority.rawValue,
                t.status.rawValue,
                due,
                rem,
                "\(done)",
                "\(total)",
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    static func csvHabits(_ habits: [HabitItem]) -> String {
        var lines: [String] = ["id,name,completed_days"]
        for h in habits {
            let days = h.completedDayKeysSorted.joined(separator: ";")
            let row = [
                h.id.uuidString,
                escapeCsvField(h.name),
                escapeCsvField(days),
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    static func plainTextExport(tasks: [TaskItem], habits: [HabitItem]) -> String {
        var parts: [String] = []
        parts.append("Tasks")
        parts.append(String(repeating: "-", count: 40))
        if tasks.isEmpty {
            parts.append("(none)")
        } else {
            for t in tasks {
                var line = "• [\(t.status.rawValue)] \(t.title) — \(t.category)"
                if let due = t.dueDate {
                    line += " — due \(Self.shortDate(due))"
                }
                parts.append(line)
                if !t.subtasks.isEmpty {
                    for s in t.subtasks {
                        let mark = s.isCompleted ? "x" : " "
                        parts.append("    [\(mark)] \(s.title)")
                    }
                }
            }
        }
        parts.append("")
        parts.append("Habits")
        parts.append(String(repeating: "-", count: 40))
        if habits.isEmpty {
            parts.append("(none)")
        } else {
            for h in habits {
                parts.append("• \(h.name) — days logged: \(h.completedDayKeysSorted.count)")
            }
        }
        return parts.joined(separator: "\n")
    }

    private static func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    static func writeTemporaryFile(content: String, filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let data = content.data(using: .utf8) else {
            throw NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
        }
        try data.write(to: url, options: [.atomic])
        return url
    }
}
