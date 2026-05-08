//
//  AchievementDefinitions.swift
//  160CalmQuest2
//

import Foundation

struct AchievementDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String

    func isUnlocked(by stateSnapshot: AchievementStateSnapshot) -> Bool {
        switch id {
        case AchievementDefinition.firstTask:
            return stateSnapshot.tasksCompleted >= 1
        case AchievementDefinition.focusStarter:
            return stateSnapshot.focusSessionsCompleted >= 5
        case AchievementDefinition.habitBuilder:
            return stateSnapshot.habitCheckIns >= 3
        case AchievementDefinition.plusTenTasks:
            return stateSnapshot.tasksCompleted >= 10
        case AchievementDefinition.gettingGoing:
            return stateSnapshot.tasksCompleted >= 10
        case AchievementDefinition.powerUser:
            return stateSnapshot.tasksCompleted >= 50
        case AchievementDefinition.threeDayStreak:
            return stateSnapshot.longestStreak >= 3
        case AchievementDefinition.weekLongHabit:
            return stateSnapshot.longestStreak >= 7
        default:
            return false
        }
    }

    static let firstTask = "achievement_first_task"
    static let focusStarter = "achievement_focus_starter"
    static let habitBuilder = "achievement_habit_builder"
    static let plusTenTasks = "achievement_plus_ten_tasks"
    static let gettingGoing = "achievement_getting_going"
    static let powerUser = "achievement_power_user"
    static let threeDayStreak = "achievement_three_day_streak"
    static let weekLongHabit = "achievement_week_long_habit"

    static let catalog: [AchievementDefinition] = [
        AchievementDefinition(
            id: firstTask,
            title: "First Task",
            description: "Completed your first task."
        ),
        AchievementDefinition(
            id: focusStarter,
            title: "Focus Starter",
            description: "Completed five focus sessions."
        ),
        AchievementDefinition(
            id: habitBuilder,
            title: "Habit Builder",
            description: "Checked in with a habit three times."
        ),
        AchievementDefinition(
            id: plusTenTasks,
            title: "+10 Tasks Done",
            description: "+10 tasks completed."
        ),
        AchievementDefinition(
            id: gettingGoing,
            title: "Getting Going",
            description: "Reached 10 items."
        ),
        AchievementDefinition(
            id: powerUser,
            title: "Power User",
            description: "Reached 50 items."
        ),
        AchievementDefinition(
            id: threeDayStreak,
            title: "Three-Day Streak",
            description: "Used the app 3 days in a row."
        ),
        AchievementDefinition(
            id: weekLongHabit,
            title: "Week-Long Habit",
            description: "Used the app 7 days in a row."
        ),
    ]
}

struct AchievementStateSnapshot {
    let tasksCompleted: Int
    let focusSessionsCompleted: Int
    let habitCheckIns: Int
    let longestStreak: Int
}
