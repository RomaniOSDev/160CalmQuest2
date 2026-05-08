//
//  HabitsView.swift
//  160CalmQuest2
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HabitsViewModel()

    @State private var pulseStreaks: [UUID: Bool] = [:]

    var body: some View {
        NavigationStack {
            LayeredBackground {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 16) {
                            if appState.habits.isEmpty {
                                HabitsEmptyState(onAddTap: {
                                    AppFeedback.actionMedium()
                                    viewModel.beginAdd()
                                })
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(appState.habits) { habit in
                                        HabitRowCard(
                                            habit: habit,
                                            calendar: Calendar.current,
                                            date: Date(),
                                            bump: pulseStreaks[habit.id, default: false],
                                            onToggle: {
                                                toggleHabitPulse(habit: habit)
                                            }
                                        )
                                    }
                                    .transition(.opacity.combined(with: .slide))
                                    Color.clear.frame(height: 16)
                                }
                                .animation(.easeInOut(duration: 0.35), value: appState.habits.map(\.id))
                                .scrollDismissesKeyboard(.interactively)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .scrollInsetAboveMainTabBar(MainTabBarLayout.habitsFloatingActionClearance)
                    }

                    FloatingAddBar(onTap: {
                        AppFeedback.buttonTapLight()
                        viewModel.beginAdd()
                    })
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.isPresentingAddSheet) {
                AddHabitSheet(
                    titleText: $viewModel.draftName,
                    onCancel: {
                        AppFeedback.buttonTapLight()
                        viewModel.isPresentingAddSheet = false
                    },
                    onSave: {
                        let name = viewModel.draftName
                        appState.upsertHabit(name: name)
                        viewModel.isPresentingAddSheet = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                pulseStreaks.removeAll()
            }
            .preferredColorScheme(.dark)
            .appToolbarGradientBackground()
        }
    }

    private func toggleHabitPulse(habit: HabitItem) {
        let didMarkComplete = appState.toggleHabitToday(id: habit.id)
        guard didMarkComplete else { return }
        pulseStreaks[habit.id] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            pulseStreaks[habit.id] = false
        }
    }
}

private struct HabitsEmptyState: View {
    let onAddTap: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .scaleEffect(appear ? 1 : 0.78)
                .opacity(appear ? 1 : 0)

            Text("No Habits Yet! Start by adding your first habit.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextPrimary)

            Button {
                AppFeedback.buttonTapLight()
                onAddTap()
            } label: {
                Text("Add Habit")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(AppPrimaryProminentBackground(useCapsule: true))
            }
            .buttonStyle(DarkPressCapsuleStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(AppCardBackgroundShape(cornerRadius: 20, emphasized: true))
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appear = true
            }
        }
    }
}

private struct HabitRowCard: View {
    @EnvironmentObject private var appState: AppState

    let habit: HabitItem
    let calendar: Calendar
    let date: Date
    let bump: Bool
    let onToggle: () -> Void

    private var dayKey: String {
        HabitItem.dayKey(for: calendar.startOfDay(for: date))
    }

    private var streak: Int {
        habit.streak(calendar: calendar, today: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                AppFeedback.buttonTapLight()
                onToggle()
            } label: {
                Image(systemName: habit.isCompleted(on: dayKey) ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(habit.isCompleted(on: dayKey) ? Color.appAccent : Color.appTextSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                HStack(spacing: 8) {
                    Text("Streak")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)

                    Text("\(streak)")
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .scaleEffect(bump ? 1.14 : 1)
                        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: bump)
                        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: streak)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppCardBackgroundShape(cornerRadius: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                AppFeedback.actionMedium()
                appState.deleteHabit(id: habit.id)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

private struct FloatingAddBar: View {
    let onTap: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Button(action: onTap) {
                Text("Add Habit")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(minHeight: 48)
                    .frame(maxWidth: 320)
                    .background(
                        AppPrimaryProminentBackground(useCapsule: true)
                    )
            }
            .buttonStyle(DarkPressCapsuleStyle())
            .padding(.bottom, 18)
        }
    }
}

private struct AddHabitSheet: View {
    @Binding var titleText: String
    let onCancel: () -> Void
    let onSave: () -> Void

    @State private var shakeToken = 0
    @State private var helper = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit name", text: $titleText)
                        .foregroundStyle(Color.appTextPrimary)
                        .shake(trigger: shakeToken)

                    if !helper.isEmpty {
                        Text(helper)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.appPrimary)
                    }
                } header: {
                    Text("New habit")
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Color.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIfValid()
                    }
                    .foregroundStyle(Color.appPrimary)
                    .fontWeight(.semibold)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.opacity(0.25))
            .appToolbarGradientBackground()
            .preferredColorScheme(.dark)
        }
    }

    private func saveIfValid() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            AppFeedback.warning()
            helper = "Please enter a habit name."
            shakeToken &+= 1
            return
        }
        helper = ""
        titleText = trimmed
        onSave()
    }
}

private struct DarkPressCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
