//
//  HabitModels.swift
//  160CalmQuest2
//

import Foundation

struct HabitItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    private(set) var completedDayKeysSorted: [String]

    init(id: UUID = UUID(), name: String, completedDayKeysSorted: [String] = []) {
        self.id = id
        self.name = name
        self.completedDayKeysSorted = completedDayKeysSorted
    }

    func isCompleted(on dayKey: String) -> Bool {
        completedDayKeysSorted.contains(dayKey)
    }

    func streak(calendar: Calendar, today: Date) -> Int {
        let formatter = Self.dayFormatter
        var count = 0
        var day = calendar.startOfDay(for: today)
        while completedDayKeysSorted.contains(formatter.string(from: day)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = calendar.startOfDay(for: previous)
        }
        return count
    }

    mutating func setCompletedToday(_ completed: Bool, calendar: Calendar, now: Date) {
        let key = Self.dayKey(for: calendar.startOfDay(for: now))
        var set = Set(completedDayKeysSorted)
        if completed {
            set.insert(key)
        } else {
            set.remove(key)
        }
        completedDayKeysSorted = set.sorted()
    }

    static func dayKey(for startOfDay: Date) -> String {
        dayFormatter.string(from: startOfDay)
    }

    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
