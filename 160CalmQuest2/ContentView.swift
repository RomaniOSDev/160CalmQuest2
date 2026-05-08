//
//  ContentView.swift
//  160CalmQuest2
//
//  Created by Roman on 5/8/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var achievementBanner = AchievementBannerPresenter()

    var body: some View {
        ZStack {
            Group {
                if appState.hasSeenOnboarding == false {
                    OnboardingView()
                        .environmentObject(appState)
                        .transition(
                            AnyTransition.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                } else {
                    MainShellView()
                        .environmentObject(appState)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }

            AchievementTopBanner(presenter: achievementBanner)
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasSeenOnboarding)
        .onAppear {
            appState.onAchievementUnlocked = { titles in
                achievementBanner.enqueue(titles: titles)
            }
        }
    }
}

#Preview {
    ContentView()
}
