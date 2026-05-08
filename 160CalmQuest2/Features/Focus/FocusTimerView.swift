//
//  FocusTimerView.swift
//  160CalmQuest2
//

import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FocusTimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingConfig = false
    @State private var previousSessionLoggedCount = 0

    var body: some View {
        NavigationStack {
            LayeredBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if showsFirstLaunchBanner {
                            firstLaunchBanner
                        }

                        // Only timer-dependent views tick — avoids rebuilding the whole scroll surface every ~0.5s.
                        TimelineView(.periodic(from: .now, by: scenePhase == .active ? 0.55 : 1.15)) { timeline in
                            let now = timeline.date

                            TickConsumer(isActive: scenePhase == .active, vm: viewModel, app: appState, now: now)

                            statusHeader(for: now)

                            CircularFocusGauge(
                                snapshot: viewModel.displayContext(
                                    at: now,
                                    app: appState,
                                    sceneActive: scenePhase == .active
                                )
                            )
                            .frame(maxWidth: 320)
                            .frame(maxWidth: .infinity)
                        }

                        controlButtons

                        startPrimaryCapsuleButton

                        sessionLogSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .scrollInsetAboveMainTabBar()
                    .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
                    .animation(.easeInOut(duration: 0.35), value: appState.completedFocusSessionTimestamps.count)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Sessions complete")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)

                        Text("\(viewModel.headlineSessionCount(app: appState))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.appTextPrimary)
                            .minimumScaleFactor(0.74)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppFeedback.buttonTapLight()
                        showingConfig = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Interval settings")
                }
            }
            .sheet(isPresented: $showingConfig, onDismiss: {
                showingConfig = false
            }) {
                FocusIntervalsSheet(onClose: {
                    showingConfig = false
                })
                .environmentObject(appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
            }
            .onAppear {
                previousSessionLoggedCount = appState.completedFocusSessionTimestamps.count
            }
            .onChange(of: scenePhase, perform: { phase in
                if phase != .active {
                    viewModel.handleSceneInactive()
                }
            })
            .onChange(of: appState.completedFocusSessionTimestamps.count, perform: { newCount in
                if newCount > previousSessionLoggedCount {
                    AppFeedback.tickSound()
                }
                previousSessionLoggedCount = newCount
            })
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                viewModel.reset(app: appState)
                previousSessionLoggedCount = appState.completedFocusSessionTimestamps.count
            }
            .preferredColorScheme(.dark)
            .appToolbarGradientBackground()
        }
    }

    private var showsFirstLaunchBanner: Bool {
        appState.focusSessionsCompleted == 0 && appState.completedFocusSessionTimestamps.isEmpty
    }

    private var firstLaunchBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Color.appAccent)

            Text("Get started by setting your focus intervals.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppCardBackgroundShape(cornerRadius: 18, emphasized: true))
    }

    private func statusHeader(for now: Date) -> some View {
        let snapshot = viewModel.displayContext(at: now, app: appState, sceneActive: scenePhase == .active)

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.isBreak ? "Break" : "Focus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                Text(Self.format(seconds: snapshot.remaining))
                    .font(.title.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if scenePhase != .active, !viewModel.isIdle {
                Text("Paused in background")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppCardBackgroundShape(cornerRadius: 16))
        .opacity(viewModel.isIdle && showsFirstLaunchBanner ? 0.55 : 1)
        .allowsHitTesting(false)
    }

    private var controlButtons: some View {
        HStack(spacing: 14) {
            Button {
                AppFeedback.buttonTapLight()
                showingConfig = true
            } label: {
                Text("Intervals")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(AppCardBackgroundShape(cornerRadius: 14))
            }

            Button {
                AppFeedback.actionMedium()
                if viewModel.isRunning {
                    viewModel.pause()
                } else if viewModel.isIdle {
                    viewModel.startCycle(app: appState)
                } else {
                    viewModel.resume(app: appState)
                }
            } label: {
                Text(midControlTitle)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity)
                    .background(AppPrimaryProminentBackground(useCapsule: false, cornerRadius: 14))
            }

            Button {
                AppFeedback.actionMedium()
                viewModel.reset(app: appState)
            } label: {
                Text("Reset")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(AppCardBackgroundShape(cornerRadius: 14))
            }
        }
    }

    private var midControlTitle: String {
        if viewModel.isRunning {
            return "Pause"
        }
        if viewModel.isIdle {
            return "Start"
        }
        return "Resume"
    }

    private var startPrimaryCapsuleButton: some View {
        Button {
            AppFeedback.actionMedium()
            if viewModel.isIdle {
                viewModel.startCycle(app: appState)
            } else if viewModel.isRunning {
                viewModel.pause()
            } else {
                viewModel.resume(app: appState)
            }
        } label: {
            Text(viewModel.isIdle ? "Start session" : (viewModel.isRunning ? "Pause session" : "Resume session"))
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 52)
                .frame(maxWidth: .infinity)
                .background(AppPrimaryProminentBackground(useCapsule: true))
        }
        .buttonStyle(DarkPressCapsuleStyle())
    }

    private var sessionLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past sessions")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            if appState.completedFocusSessionTimestamps.isEmpty {
                Text("Complete a focus interval to begin logging timestamps.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(appState.completedFocusSessionTimestamps.prefix(48).enumerated()), id: \.offset) { _, date in
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 22)

                            Text(Self.format(timestamp: date))
                                .foregroundStyle(Color.appTextPrimary)
                                .font(.subheadline.monospacedDigit())

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppCardBackgroundShape(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private static func format(seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(ceil(seconds), 0))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private static func format(timestamp date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}

private struct TickConsumer: View {
    let isActive: Bool
    let vm: FocusTimerViewModel
    let app: AppState
    let now: Date

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: now.timeIntervalSince1970, perform: { _ in
                guard isActive else { return }
                vm.handleTick(now: now, app: app)
            })
    }
}

private struct CircularFocusGauge: View {
    let snapshot: (remaining: TimeInterval, total: TimeInterval, isBreak: Bool)

    private var accent: Color {
        snapshot.isBreak ? Color.appAccent : Color.appPrimary
    }

    var body: some View {
        let safeTotal = max(snapshot.total, 0.001)
        let fraction = CGFloat(max(min((safeTotal - max(snapshot.remaining, 0)) / safeTotal, 1), 0))

        ZStack {
            Circle()
                .stroke(Color.appSurface.opacity(0.55), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: fraction)

            VStack(spacing: 6) {
                Text(snapshot.isBreak ? "Break timer" : "Focus timer")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                Text(Self.clockText(for: snapshot.remaining))
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.appTextPrimary)
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .aspectRatio(1, contentMode: .fit)
    }

    private static func clockText(for seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(ceil(seconds), 0))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct DarkPressCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct FocusIntervalsSheet: View {
    @EnvironmentObject private var appState: AppState
    let onClose: () -> Void

    @State private var focusMinutes = 25
    @State private var breakMinutes = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("\(focusMinutes) minutes focus", value: $focusMinutes, in: 1 ... 120)
                    Text("Customize how deep each focus block lasts.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                } header: {
                    Text("Work")
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())

                Section {
                    Stepper("\(breakMinutes) minutes break", value: $breakMinutes, in: 1 ... 60)
                    Text("Short breaks preserve attention between blocks.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                } header: {
                    Text("Break")
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())
            }
            .navigationTitle("Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        AppFeedback.buttonTapLight()
                        persist()
                        onClose()
                    }
                    .foregroundStyle(Color.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        AppFeedback.actionMedium()
                        persist()
                        onClose()
                    }
                    .foregroundStyle(Color.appPrimary)
                }
            }
            .preferredColorScheme(.dark)
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.automatic)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.opacity(0.25))
            .appToolbarGradientBackground()
            .onAppear {
                AppFeedback.tickSound()
                focusMinutes = max(1, appState.focusDurationSec / 60)
                breakMinutes = max(1, appState.breakDurationSec / 60)
            }
        }
    }

    private func persist() {
        let focusClamp = min(max(focusMinutes, 1), 120)
        let breakClamp = min(max(breakMinutes, 1), 60)
        focusMinutes = focusClamp
        breakMinutes = breakClamp
        appState.updateFocusDurations(
            focus: focusClamp * 60,
            breakDuration: breakClamp * 60
        )
    }
}
