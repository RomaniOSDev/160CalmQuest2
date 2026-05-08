//
//  HabitsViewModel.swift
//  160CalmQuest2
//

import Combine
import Foundation

@MainActor
final class HabitsViewModel: ObservableObject {
    @Published var isPresentingAddSheet = false
    @Published var draftName = ""

    func beginAdd() {
        AppFeedback.buttonTapLight()
        draftName = ""
        isPresentingAddSheet = true
    }
}
