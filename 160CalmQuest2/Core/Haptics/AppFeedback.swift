//
//  AppFeedback.swift
//  160CalmQuest2
//

import AudioToolbox
import UIKit

enum AppFeedback {
    static func buttonTapLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func actionMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func taskCompletedLightAndSound1104() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    static func focusSessionCompleteMediumAndSound1103() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1103)
    }

    static func habitMarkedLightAndSound1104() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    static func meaningfulSuccessPing() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }

    static func tickSound() {
        AudioServicesPlaySystemSound(1003)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func achievementUnlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
