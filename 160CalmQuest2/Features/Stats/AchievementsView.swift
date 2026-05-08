//
//  AchievementsView.swift
//  160CalmQuest2
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            LayeredBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard

                        Text("Achievements")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(AchievementDefinition.catalog) { badge in
                                AchievementTile(
                                    definition: badge,
                                    unlockedDate: appState.achievementsUnlocked[badge.id],
                                    isUnlocked: badge.isUnlocked(by: appState.achievementSnapshot())
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .scrollInsetAboveMainTabBar()
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .appToolbarGradientBackground()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            HStack {
                metricBlock(title: "Tasks done", value: "\(appState.tasksCompleted)")
                Spacer(minLength: 12)
                metricBlock(title: "Focus sessions", value: "\(appState.focusSessionsCompleted)")
                Spacer(minLength: 12)
                metricBlock(title: "Streak record", value: "\(appState.longestStreak)d")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppCardBackgroundShape(cornerRadius: 20, emphasized: true))
    }

    private func metricBlock(title: String, value: String) -> some View {
        AppInnerMetricSlab {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }
}

private struct AchievementTile: View {
    let definition: AchievementDefinition
    let unlockedDate: Date?
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            AppInnerMetricSlab {
                ZStack {
                    Image(systemName: iconName)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(fillColor)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(8)
                            .background(Color.appBackground.opacity(0.45), in: Circle())
                            .offset(x: 34, y: -28)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(definition.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(definition.description)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                if let unlockedDate {
                    Text(formatted(date: unlockedDate))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(AppCardBackgroundShape(cornerRadius: 18))
    }

    private var iconName: String {
        isUnlocked ? "star.fill" : "star"
    }

    private var fillColor: Color {
        isUnlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.55)
    }

    private func formatted(date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateStyle = .medium
        df.timeStyle = .short
        return "Unlocked \(df.string(from: date))"
    }
}
