//
//  AppCellDesign.swift
//  160CalmQuest2
//

import SwiftUI

// MARK: - Card chrome (shared “custom cell” look)

struct AppCardBackgroundShape: View {
    var cornerRadius: CGFloat = 18
    /// Slightly stronger border / shadow for primary interactive rows
    var emphasized: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(emphasized ? 1.0 : 0.98),
                            Color.appSurface.opacity(0.78),
                            Color.appSurface.opacity(0.52),
                            Color.appBackground.opacity(emphasized ? 0.62 : 0.5),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.appBackground.opacity(emphasized ? 0.52 : 0.38),
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appTextPrimary.opacity(emphasized ? 0.07 : 0.045),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.42)
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(emphasized ? 0.62 : 0.42),
                            Color.appPrimary.opacity(emphasized ? 0.48 : 0.32),
                            Color.appAccent.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: emphasized ? 1.5 : 1
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.appTextPrimary.opacity(0.07), lineWidth: 1)
                .padding(1)
        }
        // Single shadow: stacked shadows on every list row devastate GPU compositing.
        .shadow(color: Color.black.opacity(emphasized ? 0.32 : 0.22), radius: emphasized ? 12 : 10, x: 0, y: emphasized ? 7 : 5)
    }
}

struct AppCardContainer<Content: View>: View {
    var cornerRadius: CGFloat = 18
    var emphasized: Bool = false
    let content: Content

    init(cornerRadius: CGFloat = 18, emphasized: Bool = false, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.emphasized = emphasized
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                AppCardBackgroundShape(cornerRadius: cornerRadius, emphasized: emphasized)
            )
    }
}

extension View {
    func appCardCell(cornerRadius: CGFloat = 18, emphasized: Bool = false) -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppCardBackgroundShape(cornerRadius: cornerRadius, emphasized: emphasized))
    }
}

// MARK: - List row (Settings / Form)

struct AppListRowCardBackground: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        AppCardBackgroundShape(cornerRadius: cornerRadius, emphasized: false)
            .padding(.vertical, 5)
            .padding(.horizontal, 14)
    }
}

// MARK: - Section headers

struct AppSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 4, height: 16)

            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.6)

            Spacer(minLength: 0)
        }
        .padding(.leading, 2)
        .padding(.bottom, 6)
    }
}

// MARK: - Settings row content

struct SettingsIconOrb: View {
    let systemName: String
    var accent: Color = Color.appAccent

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.58), Color.appPrimary.opacity(0.38), accent.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appTextPrimary.opacity(0.18), Color.appAccent.opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .frame(width: 42, height: 42)

            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
        }
    }
}

struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var showChevron: Bool = false
    var orbAccent: Color = Color.appAccent

    var body: some View {
        HStack(spacing: 14) {
            SettingsIconOrb(systemName: icon, accent: orbAccent)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            Spacer(minLength: 8)

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.85))
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Filter / template chips

struct AppFilterChipStyle {
    let isSelected: Bool

    @ViewBuilder
    func chipBackground() -> some View {
        if isSelected {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.appAccent.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 4)
        } else {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.94), Color.appSurface.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.38), Color.appPrimary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Inner metric slab (stats / summary grids)

struct AppInnerMetricSlab<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appBackground.opacity(0.58),
                                    Color.appSurface.opacity(0.32),
                                    Color.appBackground.opacity(0.48),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.28), Color.appPrimary.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
            )
    }
}
