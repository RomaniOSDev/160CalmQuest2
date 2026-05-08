//
//  FocusTimerViewModel.swift
//  160CalmQuest2
//

import Combine
import Foundation

@MainActor
final class FocusTimerViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case workRunning(end: Date)
        case workPaused(remaining: TimeInterval)
        case breakRunning(end: Date)
        case breakPaused(remaining: TimeInterval)
    }

    @Published private(set) var phase: Phase = .idle

    func displayContext(at now: Date, app: AppState, sceneActive: Bool) -> (remaining: TimeInterval, total: TimeInterval, isBreak: Bool) {
        guard sceneActive else {
            return pausedSnapshot(app: app)
        }

        switch phase {
        case .idle:
            return (TimeInterval(app.focusDurationSec), TimeInterval(app.focusDurationSec), false)

        case .workRunning(let end):
            return (max(0, end.timeIntervalSince(now)), TimeInterval(app.focusDurationSec), false)

        case .workPaused(let remaining):
            return (remaining, TimeInterval(app.focusDurationSec), false)

        case .breakRunning(let end):
            return (max(0, end.timeIntervalSince(now)), TimeInterval(app.breakDurationSec), true)

        case .breakPaused(let remaining):
            return (remaining, TimeInterval(app.breakDurationSec), true)
        }
    }

    func headlineSessionCount(app: AppState) -> Int {
        app.focusSessionsCompleted
    }

    func startCycle(app: AppState) {
        AppFeedback.actionMedium()
        AppFeedback.tickSound()
        let end = Date().addingTimeInterval(TimeInterval(app.focusDurationSec))
        phase = .workRunning(end: end)
    }

    func pause(now: Date = Date()) {
        switch phase {
        case .workRunning(let end):
            phase = .workPaused(remaining: max(0, end.timeIntervalSince(now)))
        case .breakRunning(let end):
            phase = .breakPaused(remaining: max(0, end.timeIntervalSince(now)))
        default:
            break
        }
    }

    func resume(app: AppState, now: Date = Date()) {
        switch phase {
        case .workPaused(let remaining):
            phase = .workRunning(end: now.addingTimeInterval(remaining))
        case .breakPaused(let remaining):
            phase = .breakRunning(end: now.addingTimeInterval(remaining))
        default:
            break
        }
    }

    func reset(app: AppState) {
        AppFeedback.actionMedium()
        phase = .idle
    }

    func handleSceneInactive(now: Date = Date()) {
        pause(now: now)
    }

    func handleTick(now: Date, app: AppState) {
        switch phase {
        case .workRunning(let end):
            guard now >= end else { return }
            app.registerFocusWorkSessionCompleted(at: now)
            let breakEnd = now.addingTimeInterval(TimeInterval(app.breakDurationSec))
            phase = .breakRunning(end: breakEnd)

        case .breakRunning(let end):
            guard now >= end else { return }
            let workEnd = now.addingTimeInterval(TimeInterval(app.focusDurationSec))
            phase = .workRunning(end: workEnd)

        default:
            break
        }
    }

    var isRunning: Bool {
        switch phase {
        case .workRunning, .breakRunning:
            return true
        default:
            return false
        }
    }

    var isIdle: Bool {
        if case .idle = phase { return true }
        return false
    }

    private func pausedSnapshot(app: AppState) -> (TimeInterval, TimeInterval, Bool) {
        switch phase {
        case .idle:
            return (TimeInterval(app.focusDurationSec), TimeInterval(app.focusDurationSec), false)
        case .workPaused(let remaining):
            return (remaining, TimeInterval(app.focusDurationSec), false)
        case .breakPaused(let remaining):
            return (remaining, TimeInterval(app.breakDurationSec), true)
        case .workRunning(let end):
            let remaining = max(0, end.timeIntervalSince(Date()))
            return (remaining, TimeInterval(app.focusDurationSec), false)
        case .breakRunning(let end):
            let remaining = max(0, end.timeIntervalSince(Date()))
            return (remaining, TimeInterval(app.breakDurationSec), true)
        }
    }
}
