//
//  FocusHabitsContainerView.swift
//  160CalmQuest2
//

import SwiftUI

struct FocusHabitsContainerView: View {
    enum Subpage: String, CaseIterable, Identifiable {
        case focus = "Focus"
        case habits = "Habits"

        var id: String { rawValue }
    }

    @State private var subpage: Subpage = .focus

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $subpage) {
                ForEach(Subpage.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(10)
            .background(AppCardBackgroundShape(cornerRadius: 18, emphasized: false))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Group {
                switch subpage {
                case .focus:
                    FocusTimerView()
                case .habits:
                    HabitsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onChange(of: subpage, perform: { _ in
            AppFeedback.buttonTapLight()
        })
    }
}
