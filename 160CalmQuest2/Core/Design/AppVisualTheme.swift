//
//  AppVisualTheme.swift
//  160CalmQuest2
//

import SwiftUI

// MARK: - Gradients (shared)

enum AppThemeGradients {
    /// Navigation bar fade — depth without flat tint.
    static var navigationBar: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.92),
                Color.appSurface.opacity(0.42),
                Color.appBackground.opacity(0.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Primary filled controls (capsules / CTAs).
    static var primaryProminent: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary,
                Color.appPrimary.opacity(0.82),
                Color.appAccent.opacity(0.62),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryProminentStroke: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.75), Color.appPrimary.opacity(0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Soft lift under tab bar & dock.
    static var tabDockShell: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.98),
                Color.appSurface.opacity(0.72),
                Color.appBackground.opacity(0.55),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var tabDockStroke: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.28), Color.appAccent.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Selected tab chip inside dock.
    static var tabItemSelected: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary.opacity(0.95), Color.appPrimary.opacity(0.65), Color.appAccent.opacity(0.42)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var tabItemUnselected: LinearGradient {
        LinearGradient(
            colors: [Color.appSurface.opacity(0.95), Color.appBackground.opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Layered shadows (volume)

enum AppElevation {
    case card
    case prominent
    case floating
    case subtle
}

extension View {
    /// Prefer a single soft shadow — doubles were expensive on scroll-heavy screens.
    @ViewBuilder
    func appElevation(_ level: AppElevation) -> some View {
        switch level {
        case .card:
            self.shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
        case .prominent:
            self.shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 8)
        case .floating:
            self.shadow(color: Color.black.opacity(0.26), radius: 14, x: 0, y: 8)
        case .subtle:
            self.shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
        }
    }

    func appToolbarGradientBackground() -> some View {
        toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppThemeGradients.navigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Primary button chrome (gradient + specular + shadow)

struct AppPrimaryProminentBackground: View {
    var useCapsule: Bool = true
    var cornerRadius: CGFloat = 14

    var body: some View {
        Group {
            if useCapsule {
                Capsule(style: .continuous)
                    .fill(AppThemeGradients.primaryProminent)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppThemeGradients.primaryProminentStroke, lineWidth: 1)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appTextPrimary.opacity(0.18), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .blendMode(.overlay)
                            .padding(2)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppThemeGradients.primaryProminent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppThemeGradients.primaryProminentStroke, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appTextPrimary.opacity(0.16), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .blendMode(.overlay)
                            .padding(2)
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
    }
}
