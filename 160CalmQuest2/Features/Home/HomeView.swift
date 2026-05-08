//
//  HomeView.swift
//  160CalmQuest2
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    private let calendar = Calendar.current
    private var now: Date { Date() }

    private var tasksDueToday: [TaskItem] {
        let f = TaskFilter.dueToday
        return appState.tasks.filter { f.includes($0, calendar: calendar, now: now) }
            .sorted(by: sortTasksToday)
    }

    private var overdueTasks: [TaskItem] {
        appState.tasks.filter { TaskFilter.overdue.includes($0, calendar: calendar, now: now) }
            .sorted(by: sortTasksToday)
    }

    private var overdueCount: Int { overdueTasks.count }
    private var openTasksCount: Int {
        appState.tasks.filter { $0.status != .completed }.count
    }

    var body: some View {
        NavigationStack {
            LayeredBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        heroBanner

                        statWidgetsGrid

                        moodIllustrationStrip

                        quickActionsRow

                        focusPromoCard

                        sectionHeader(title: "Your day", subtitle: "Tasks & habits")

                        if !overdueTasks.isEmpty {
                            overdueBlock
                        }

                        tasksTodayBlock

                        habitsBlock
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .scrollInsetAboveMainTabBar()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .appToolbarGradientBackground()
        }
    }

    // MARK: - Hero

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.55),
                            Color.appAccent.opacity(0.32),
                            Color.appSurface.opacity(0.92),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.55), Color.appPrimary.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            heroFloatingArt

            VStack(alignment: .leading, spacing: 8) {
                Text(timeGreeting)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text(formattedLongDate)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.95))

                Text(dailyTagline)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary.opacity(0.88))
                    .padding(.top, 4)
            }
            .padding(22)
        }
        .frame(minHeight: 200)
        .appElevation(.floating)
    }

    private var heroFloatingArt: some View {
        ZStack {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.appAccent.opacity(0.85), Color.appPrimary.opacity(0.5))
                .symbolRenderingMode(.palette)
                .offset(x: 118, y: -52)

            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.appAccent.opacity(0.75))
                .offset(x: -122, y: -38)
                .rotationEffect(.degrees(-12))

            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(Color.appPrimary.opacity(0.9))
                .offset(x: 108, y: 42)

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                .offset(x: -100, y: 48)

            Image(systemName: "paperplane.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.appAccent.opacity(0.65))
                .offset(x: 36, y: -62)

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.appPrimary.opacity(0.55))
                .offset(x: -48, y: 58)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var timeGreeting: String {
        let h = calendar.component(.hour, from: now)
        switch h {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Good night"
        }
    }

    private var formattedLongDate: String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.timeZone = TimeZone.current
        df.dateFormat = "EEEE, MMMM d"
        return df.string(from: now)
    }

    private var dailyTagline: String {
        let lines = [
            "Small steps today build calmer tomorrows.",
            "Your pace is enough — progress counts.",
            "Breathe, focus, then begin.",
            "Balance beats burnout.",
        ]
        let idx = abs(calendar.ordinality(of: .day, in: .year, for: now) ?? 0) % lines.count
        return lines[idx]
    }

    // MARK: - Stat widgets

    private var statWidgetsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "AT A GLANCE")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                HomeStatTile(
                    icon: "calendar.badge.clock",
                    iconGradient: true,
                    title: "Due today",
                    value: "\(tasksDueToday.count)",
                    caption: "scheduled"
                )
                .contentShape(Rectangle())
                .onTapGesture { switchToTab(.tasks) }

                HomeStatTile(
                    icon: overdueCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                    iconGradient: false,
                    title: "Overdue",
                    value: "\(overdueCount)",
                    caption: overdueCount > 0 ? "needs attention" : "all clear"
                )
                .contentShape(Rectangle())
                .onTapGesture { switchToTab(.tasks) }

                HomeStatTile(
                    icon: "flame.fill",
                    iconGradient: true,
                    title: "Streak",
                    value: "\(appState.streakDaysCurrent)d",
                    caption: "best \(appState.longestStreak)d"
                )
                .contentShape(Rectangle())
                .onTapGesture { switchToTab(.progress) }

                HomeStatTile(
                    icon: "timer",
                    iconGradient: false,
                    title: "Focus",
                    value: "\(appState.focusSessionsCompleted)",
                    caption: "\(appState.totalMinutesUsed)m total"
                )
                .contentShape(Rectangle())
                .onTapGesture { switchToTab(.focus) }
            }
        }
    }

    // MARK: - Illustration strip (“more images”)

    private var moodIllustrationStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "CALM SCENES")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    HomeSceneCard(
                        symbolName: "figure.walk",
                        title: "Center",
                        subtitle: "Ground your attention",
                        tint: Color.appAccent
                    )
                    HomeSceneCard(
                        symbolName: "drop.fill",
                        title: "Flow",
                        subtitle: "Let thoughts pass",
                        tint: Color.appPrimary
                    )
                    HomeSceneCard(
                        symbolName: "sunrise.fill",
                        title: "Dawn",
                        subtitle: "Fresh start energy",
                        tint: Color.appAccent
                    )
                    HomeSceneCard(
                        symbolName: "leaf.fill",
                        title: "Notice",
                        subtitle: "Tiny wins matter",
                        tint: Color.appPrimary
                    )
                    HomeSceneCard(
                        symbolName: "books.vertical.fill",
                        title: "Learn",
                        subtitle: "One page counts",
                        tint: Color.appAccent
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "QUICK ACTIONS")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    HomeQuickActionChip(
                        symbol: "checkmark.circle.fill",
                        label: "Tasks",
                        tab: .tasks
                    )
                    HomeQuickActionChip(
                        symbol: "timer",
                        label: "Focus",
                        tab: .focus
                    )
                    HomeQuickActionChip(
                        symbol: "chart.bar.fill",
                        label: "Progress",
                        tab: .progress
                    )
                    HomeQuickActionChip(
                        symbol: "gearshape.fill",
                        label: "Settings",
                        tab: .settings
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text(subtitle)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Focus promo

    private var focusPromoCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.55), Color.appAccent.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.appTextPrimary.opacity(0.12), lineWidth: 1))

                Image(systemName: "timer")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Deep work")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("\(openTasksCount) open tasks • \(appState.habits.count) habits tracked")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Button {
                    AppFeedback.actionMedium()
                    NotificationCenter.default.post(
                        name: .switchMainTab,
                        object: nil,
                        userInfo: ["tab": MainShellView.Tab.focus.rawValue]
                    )
                } label: {
                    Label("Open Focus timer", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppPrimaryProminentBackground(useCapsule: true))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppCardBackgroundShape(cornerRadius: 22, emphasized: true))
    }

    // MARK: - Today sections

    private var overdueBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundStyle(Color.appPrimary)
                Text("Overdue")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
            }

            ForEach(overdueTasks) { task in
                HomeTaskRow(task: task)
            }
        }
    }

    private var tasksTodayBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks due today")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            if tasksDueToday.isEmpty {
                Text("No tasks due today. Add dates in Tasks.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(tasksDueToday) { task in
                    HomeTaskRow(task: task)
                }
            }
        }
    }

    private var habitsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            if appState.habits.isEmpty {
                Text("No habits yet — add them from the Focus tab.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                ForEach(appState.habits) { habit in
                    HomeHabitRow(habit: habit, calendar: calendar, now: now)
                }
            }
        }
    }

    private func sortTasksToday(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.prioritySortingIndex != b.prioritySortingIndex {
            return a.prioritySortingIndex < b.prioritySortingIndex
        }
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?): return x < y
        case (_?, nil): return true
        case (nil, _?): return false
        default:
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private func switchToTab(_ tab: MainShellView.Tab) {
        AppFeedback.buttonTapLight()
        NotificationCenter.default.post(
            name: .switchMainTab,
            object: nil,
            userInfo: ["tab": tab.rawValue]
        )
    }
}

// MARK: - Widget tiles

private struct HomeStatTile: View {
    let icon: String
    var iconGradient: Bool
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            iconMark

            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.4)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppCardBackgroundShape(cornerRadius: 18))
    }

    @ViewBuilder
    private var iconMark: some View {
        if iconGradient {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appAccent.opacity(0.95))
        }
    }
}

private struct HomeSceneCard: View {
    let symbolName: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.42), Color.appBackground.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appAccent.opacity(0.28), lineWidth: 1)
                    )
                    .frame(height: 112)

                Image(systemName: symbolName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appTextPrimary, tint.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 156, alignment: .leading)
        .padding(12)
        .background(AppCardBackgroundShape(cornerRadius: 20))
    }
}

private struct HomeQuickActionChip: View {
    let symbol: String
    let label: String
    let tab: MainShellView.Tab

    var body: some View {
        Button {
            AppFeedback.buttonTapLight()
            NotificationCenter.default.post(
                name: .switchMainTab,
                object: nil,
                userInfo: ["tab": tab.rawValue]
            )
        } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appAccent)

                Text(label)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 92, height: 92)
            .background(AppCardBackgroundShape(cornerRadius: 18, emphasized: false))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rows (task / habit)

private extension TaskItem {
    var prioritySortingIndex: Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

private struct HomeTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.status == .completed ? Color.appAccent : Color.appTextSecondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                HStack(spacing: 8) {
                    Text(task.category.isEmpty ? "Uncategorized" : task.category)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)

                    if let prog = task.subtasksProgressLabel() {
                        Text(prog)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.appSurface.opacity(0.7)))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppCardBackgroundShape(cornerRadius: 16))
    }
}

private struct HomeHabitRow: View {
    @EnvironmentObject private var appState: AppState
    let habit: HabitItem
    let calendar: Calendar
    let now: Date

    private var dayKey: String {
        HabitItem.dayKey(for: calendar.startOfDay(for: now))
    }

    private var streak: Int {
        habit.streak(calendar: calendar, today: now)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                AppFeedback.buttonTapLight()
                _ = appState.toggleHabitToday(id: habit.id, calendar: calendar, now: now)
            } label: {
                Image(systemName: habit.isCompleted(on: dayKey) ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(habit.isCompleted(on: dayKey) ? Color.appAccent : Color.appTextSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Streak \(streak)d")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppCardBackgroundShape(cornerRadius: 16))
    }
}
