//
//  MainShellView.swift
//  160CalmQuest2
//

import SwiftUI

struct MainShellView: View {
    enum Tab: Int, CaseIterable, Identifiable {
        case home = 0
        case tasks = 1
        case focus = 2
        case progress = 3
        case settings = 4

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .tasks: return "Tasks"
            case .focus: return "Focus"
            case .progress: return "Progress"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .tasks: return "checkmark.circle"
            case .focus: return "timer"
            case .progress: return "chart.bar.fill"
            case .settings: return "gearshape"
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @State private var selection: Tab = .home

    var body: some View {
        Group {
            switch selection {
            case .home:
                HomeView()
            case .tasks:
                TasksView()
            case .focus:
                FocusHabitsContainerView()
            case .progress:
                AchievementsView()
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(appState)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBarChrome {
                MainTabDock(selection: $selection)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchMainTab)) { note in
            guard let raw = note.userInfo?["tab"] as? Int,
                  let tab = Tab(rawValue: raw) else { return }
            selection = tab
        }
        .ignoresSafeArea(.keyboard)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }
}

/// Solid backdrop + hairline so list content never shows through under the tab bar.
private struct TabBarChrome<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.65),
                            Color.appPrimary.opacity(0.45),
                            Color.appAccent.opacity(0.35),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            content
        }
        .frame(maxWidth: .infinity)
        .background {
            Color.appBackground
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct MainTabDock: View {
    @Binding var selection: MainShellView.Tab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MainShellView.Tab.allCases) { tab in
                    Button {
                        AppFeedback.buttonTapLight()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            selection = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(selection == tab ? Color.appTextPrimary : Color.appTextSecondary)

                            Text(tab.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(selection == tab ? Color.appTextPrimary : Color.appTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        .frame(minWidth: 64)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(tabSlotBackground(selected: selection == tab))
                    }
                    .buttonStyle(TabDockButtonStyle())
                    .accessibilityLabel(tab.title)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppThemeGradients.tabDockShell)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppThemeGradients.tabDockStroke, lineWidth: 1.5)
            }
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: -6)
        )
    }

    @ViewBuilder
    private func tabSlotBackground(selected: Bool) -> some View {
        if selected {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppThemeGradients.tabItemSelected)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appTextPrimary.opacity(0.22), Color.appAccent.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppThemeGradients.tabItemUnselected)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.appTextPrimary.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

private struct TabDockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
