//
//  AppState.swift
//  160CalmQuest2
//

import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    private static let defaultsKeyPrefix = "calmquest_"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var tasks: [TaskItem]
    @Published private(set) var habits: [HabitItem]

    @Published private(set) var tasksCreatedTotal: Int
    @Published private(set) var tasksCompleted: Int
    @Published private(set) var taskCount: Int

    @Published private(set) var totalSessionsCompleted: Int
    @Published private(set) var focusSessionsCompleted: Int
    @Published private(set) var totalMinutesUsed: Int
    @Published private(set) var focusDurationSec: Int
    @Published private(set) var breakDurationSec: Int
    @Published private(set) var completedFocusSessionTimestamps: [Date]

    @Published private(set) var habitCheckIns: Int
    @Published private(set) var streakDaysCurrent: Int
    @Published private(set) var longestStreak: Int
    private var lastActivityDayStart: Date?

    @Published private(set) var achievementsUnlocked: [String: Date]

    var onAchievementUnlocked: (([String]) -> Void)?

    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults

        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970

        hasSeenOnboarding = userDefaults.bool(forKey: Self.key("has_seen_onboarding"))

        tasks = Self.decodeJSONArray([TaskItem].self, from: userDefaults.data(forKey: Self.key("tasks"))) ?? []
        habits = Self.decodeJSONArray([HabitItem].self, from: userDefaults.data(forKey: Self.key("habits"))) ?? []

        tasksCreatedTotal = userDefaults.integer(forKey: Self.key("tasks_created_total"))
        tasksCompleted = userDefaults.integer(forKey: Self.key("tasks_completed"))
        taskCount = userDefaults.integer(forKey: Self.key("task_count"))

        totalSessionsCompleted = userDefaults.integer(forKey: Self.key("total_sessions_completed"))
        focusSessionsCompleted = userDefaults.integer(forKey: Self.key("focus_sessions_completed"))
        totalMinutesUsed = userDefaults.integer(forKey: Self.key("total_minutes_used"))
        focusDurationSec = Self.clampDuration(userDefaults.integer(forKey: Self.key("focus_duration_sec")), default: 1500)
        breakDurationSec = Self.clampDuration(userDefaults.integer(forKey: Self.key("break_duration_sec")), default: 300)
        completedFocusSessionTimestamps = Self.decodeDatesArray(from: userDefaults.data(forKey: Self.key("completed_focus_sessions")))

        habitCheckIns = userDefaults.integer(forKey: Self.key("habit_check_ins"))
        streakDaysCurrent = userDefaults.integer(forKey: Self.key("streak_days_current"))
        longestStreak = userDefaults.integer(forKey: Self.key("longest_streak"))
        if let lastTs = userDefaults.object(forKey: Self.key("last_activity_day_ts")) as? Double {
            lastActivityDayStart = Date(timeIntervalSince1970: lastTs)
        } else if let legacy = userDefaults.object(forKey: Self.key("last_activity_day_ts")) as? TimeInterval {
            lastActivityDayStart = Date(timeIntervalSince1970: legacy)
        } else {
            lastActivityDayStart = nil
        }

        achievementsUnlocked =
            Self.decodeAchievements(from: userDefaults.data(forKey: Self.key("achievements_unlocked")))
            ?? [:]

        TaskReminderScheduler.rescheduleAll(tasks: tasks)
    }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Self.key("has_seen_onboarding"))
    }

    func applyDataReloadFromDefaults() {
        Self.bootstrapAssignInto(self)
        objectWillChange.send()
    }

    func resetAllData() {
        TaskReminderScheduler.cancelAll()
        for storageKey in Self.knownPersistedKeys() {
            defaults.removeObject(forKey: storageKey)
        }
        NotificationCenter.default.post(name: .dataReset, object: nil)
        Self.bootstrapAssignInto(self)
        objectWillChange.send()
    }

    func upsertTask(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        } else {
            tasks.append(task)
            tasksCreatedTotal += 1
            taskCount = tasksCreatedTotal
            defaults.set(tasksCreatedTotal, forKey: Self.key("tasks_created_total"))
            defaults.set(taskCount, forKey: Self.key("task_count"))
            recordDailyActivityAndSave()
            AppFeedback.meaningfulSuccessPing()
        }
        saveTasksOnly()
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            TaskReminderScheduler.sync(task: tasks[idx])
        }
        reconcileAchievements()
    }

    func deleteTask(id: UUID) {
        TaskReminderScheduler.cancel(taskId: id)
        tasks.removeAll { $0.id == id }
        saveTasksOnly()
    }

    func setTaskStatus(id: UUID, status: TaskStatus) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        var t = tasks[idx]
        guard t.status != status else { return }

        let wasCompleted = t.status == .completed
        let becomesCompleted = status == .completed

        if !wasCompleted, becomesCompleted {
            t.status = .completed
            tasks[idx] = t
            tasksCompleted += 1
            defaults.set(tasksCompleted, forKey: Self.key("tasks_completed"))
            AppFeedback.taskCompletedLightAndSound1104()
            AppFeedback.meaningfulSuccessPing()
            recordDailyActivityAndSave()
        } else if wasCompleted, !becomesCompleted {
            t.status = status
            tasks[idx] = t
            tasksCompleted = max(0, tasksCompleted - 1)
            defaults.set(tasksCompleted, forKey: Self.key("tasks_completed"))
        } else {
            t.status = status
            tasks[idx] = t
            if status == .inProgress {
                recordDailyActivityAndSave()
            }
        }

        saveTasksOnly()
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            TaskReminderScheduler.sync(task: tasks[idx])
        }
        reconcileAchievements()
    }

    func markTaskCheckbox(id: UUID, complete: Bool) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        var t = tasks[idx]

        if complete {
            guard t.status != .completed else { return }
            t.status = .completed
            tasks[idx] = t
            tasksCompleted += 1
            defaults.set(tasksCompleted, forKey: Self.key("tasks_completed"))
            AppFeedback.taskCompletedLightAndSound1104()
            AppFeedback.meaningfulSuccessPing()
            recordDailyActivityAndSave()
        } else {
            guard t.status == .completed else { return }
            t.status = .todo
            tasks[idx] = t
            tasksCompleted = max(0, tasksCompleted - 1)
            defaults.set(tasksCompleted, forKey: Self.key("tasks_completed"))
        }

        saveTasksOnly()
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            TaskReminderScheduler.sync(task: tasks[idx])
        }
        reconcileAchievements()
    }

    func updateTaskPriority(id: UUID, priority: TaskPriority) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].priority = priority
        saveTasksOnly()
    }

    func updateFocusDurations(focus: Int, breakDuration: Int) {
        focusDurationSec = Self.clampDuration(focus, default: 1500)
        breakDurationSec = Self.clampDuration(breakDuration, default: 300)
        defaults.set(focusDurationSec, forKey: Self.key("focus_duration_sec"))
        defaults.set(breakDurationSec, forKey: Self.key("break_duration_sec"))
    }

    func registerFocusWorkSessionCompleted(at date: Date = Date()) {
        focusSessionsCompleted += 1
        totalSessionsCompleted += 1
        defaults.set(focusSessionsCompleted, forKey: Self.key("focus_sessions_completed"))
        defaults.set(totalSessionsCompleted, forKey: Self.key("total_sessions_completed"))

        let minutesAdded = max(1, focusDurationSec / 60)
        totalMinutesUsed += minutesAdded
        defaults.set(totalMinutesUsed, forKey: Self.key("total_minutes_used"))

        var sessions = completedFocusSessionTimestamps
        sessions.insert(date, at: 0)
        if sessions.count > 240 {
            sessions = Array(sessions.prefix(240))
        }
        completedFocusSessionTimestamps = sessions
        persistCompletedSessionsTimestamps()

        AppFeedback.focusSessionCompleteMediumAndSound1103()
        AppFeedback.meaningfulSuccessPing()
        recordDailyActivityAndSave()
        reconcileAchievements()
    }

    func upsertHabit(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        AppFeedback.meaningfulSuccessPing()
        recordDailyActivityAndSave()

        habits.insert(HabitItem(name: trimmed), at: 0)
        saveHabitsOnly()
        reconcileAchievements()
    }

    func deleteHabit(id: UUID) {
        habits.removeAll { $0.id == id }
        saveHabitsOnly()
    }

    func toggleHabitToday(id: UUID, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return false }

        var h = habits[idx]
        let todayStart = calendar.startOfDay(for: now)
        let key = HabitItem.dayKey(for: todayStart)
        let willComplete = !h.isCompleted(on: key)

        if willComplete {
            habitCheckIns += 1
            defaults.set(habitCheckIns, forKey: Self.key("habit_check_ins"))
            AppFeedback.habitMarkedLightAndSound1104()
            AppFeedback.meaningfulSuccessPing()
            recordDailyActivityAndSave()
        }

        h.setCompletedToday(willComplete, calendar: calendar, now: now)
        habits[idx] = h

        saveHabitsOnly()
        reconcileAchievements()
        return willComplete
    }

    func achievementSnapshot() -> AchievementStateSnapshot {
        AchievementStateSnapshot(
            tasksCompleted: tasksCompleted,
            focusSessionsCompleted: focusSessionsCompleted,
            habitCheckIns: habitCheckIns,
            longestStreak: longestStreak
        )
    }

    private func persistCompletedSessionsTimestamps() {
        let intervals = completedFocusSessionTimestamps.map { $0.timeIntervalSinceReferenceDate }
        guard let data = try? encoder.encode(intervals) else { return }
        defaults.set(data, forKey: Self.key("completed_focus_sessions"))
    }

    private func reconcileAchievements() {
        let snapshot = achievementSnapshot()
        var copy = achievementsUnlocked
        var newlyTitles: [String] = []

        for def in AchievementDefinition.catalog {
            guard def.isUnlocked(by: snapshot) else { continue }
            guard copy[def.id] == nil else { continue }
            copy[def.id] = Date()
            newlyTitles.append(def.title)
        }

        guard copy != achievementsUnlocked else { return }

        achievementsUnlocked = copy
        if let data = try? encoder.encode(copy) {
            defaults.set(data, forKey: Self.key("achievements_unlocked"))
        }

        if !newlyTitles.isEmpty {
            for _ in newlyTitles {
                AppFeedback.achievementUnlocked()
            }
            onAchievementUnlocked?(newlyTitles)
        }
    }

    private func recordDailyActivityAndSave() {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        if let last = lastActivityDayStart, calendar.isDate(last, inSameDayAs: todayStart) {
            return
        }

        if let last = lastActivityDayStart, let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) {
            if calendar.isDate(last, inSameDayAs: yesterday) {
                streakDaysCurrent += 1
            } else {
                streakDaysCurrent = 1
            }
        } else {
            streakDaysCurrent = 1
        }

        lastActivityDayStart = todayStart
        longestStreak = max(longestStreak, streakDaysCurrent)

        defaults.set(streakDaysCurrent, forKey: Self.key("streak_days_current"))
        defaults.set(longestStreak, forKey: Self.key("longest_streak"))
        defaults.set(todayStart.timeIntervalSince1970, forKey: Self.key("last_activity_day_ts"))

        reconcileAchievements()
    }

    private func saveTasksOnly() {
        guard let data = try? encoder.encode(tasks) else { return }
        defaults.set(data, forKey: Self.key("tasks"))
    }

    private func saveHabitsOnly() {
        guard let data = try? encoder.encode(habits) else { return }
        defaults.set(data, forKey: Self.key("habits"))
    }

    private static func bootstrapAssignInto(_ state: AppState) {
        let d = state.defaults

        state.hasSeenOnboarding = d.bool(forKey: key("has_seen_onboarding"))
        state.tasks = decodeJSONArray([TaskItem].self, from: d.data(forKey: key("tasks"))) ?? []
        state.habits = decodeJSONArray([HabitItem].self, from: d.data(forKey: key("habits"))) ?? []

        state.tasksCreatedTotal = d.integer(forKey: key("tasks_created_total"))
        state.tasksCompleted = d.integer(forKey: key("tasks_completed"))
        state.taskCount = d.integer(forKey: key("task_count"))

        state.totalSessionsCompleted = d.integer(forKey: key("total_sessions_completed"))
        state.focusSessionsCompleted = d.integer(forKey: key("focus_sessions_completed"))
        state.totalMinutesUsed = d.integer(forKey: key("total_minutes_used"))
        state.focusDurationSec = clampDuration(d.integer(forKey: key("focus_duration_sec")), default: 1500)
        state.breakDurationSec = clampDuration(d.integer(forKey: key("break_duration_sec")), default: 300)
        state.completedFocusSessionTimestamps = decodeDatesArray(from: d.data(forKey: key("completed_focus_sessions")))

        state.habitCheckIns = d.integer(forKey: key("habit_check_ins"))
        state.streakDaysCurrent = d.integer(forKey: key("streak_days_current"))
        state.longestStreak = d.integer(forKey: key("longest_streak"))

        if let lastTs = d.object(forKey: key("last_activity_day_ts")) as? Double {
            state.lastActivityDayStart = Date(timeIntervalSince1970: lastTs)
        } else if let legacy = d.object(forKey: key("last_activity_day_ts")) as? TimeInterval {
            state.lastActivityDayStart = Date(timeIntervalSince1970: legacy)
        } else {
            state.lastActivityDayStart = nil
        }

        state.achievementsUnlocked = decodeAchievements(from: d.data(forKey: key("achievements_unlocked"))) ?? [:]

        TaskReminderScheduler.rescheduleAll(tasks: state.tasks)
    }

    private static func key(_ suffix: String) -> String {
        defaultsKeyPrefix + suffix
    }

    private static func knownPersistedKeys() -> [String] {
        [
            key("has_seen_onboarding"),
            key("tasks"),
            key("habits"),
            key("tasks_created_total"),
            key("tasks_completed"),
            key("task_count"),
            key("total_sessions_completed"),
            key("focus_sessions_completed"),
            key("total_minutes_used"),
            key("focus_duration_sec"),
            key("break_duration_sec"),
            key("completed_focus_sessions"),
            key("habit_check_ins"),
            key("streak_days_current"),
            key("longest_streak"),
            key("last_activity_day_ts"),
            key("achievements_unlocked"),
        ]
    }

    private static func clampDuration(_ value: Int, default def: Int) -> Int {
        if value <= 0 { return def }
        return min(max(value, 60), 7200)
    }

    private static func decodeJSONArray<T: Decodable>(_ type: [T].Type, from data: Data?) -> [T]? {
        guard let data else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .secondsSince1970
        return try? dec.decode(type, from: data)
    }

    private static func decodeDatesArray(from data: Data?) -> [Date] {
        guard let data else { return [] }
        let dec = JSONDecoder()
        if let intervals = try? dec.decode([TimeInterval].self, from: data) {
            return intervals.map { Date(timeIntervalSinceReferenceDate: $0) }
        }
        return []
    }

    private static func decodeAchievements(from data: Data?) -> [String: Date]? {
        guard let data else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .secondsSince1970
        return try? dec.decode([String: Date].self, from: data)
    }
}
