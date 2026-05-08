//
//  OnboardingView.swift
//  160CalmQuest2
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0

    private let slides: [(badge: String, title: String, subtitle: String)] = [
        (
            badge: "Welcome",
            title: "Your calm hub",
            subtitle: "Tasks, focus, and habits in one quiet flow — built for steady progress, not pressure."
        ),
        (
            badge: "Plan",
            title: "Clarity for every day",
            subtitle: "Due dates, reminders, and step-by-step checklists so priorities stay visible."
        ),
        (
            badge: "Rhythm",
            title: "Focus that fits you",
            subtitle: "Timed sessions for deep work and streaks that reward showing up — one calm step at a time."
        ),
    ]

    var body: some View {
        LayeredBackground {
            VStack(spacing: 0) {
                HStack {
                    if page > 0 {
                        Button {
                            AppFeedback.buttonTapLight()
                            withAnimation(.easeInOut(duration: 0.28)) {
                                page -= 1
                            }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                        .accessibilityLabel("Previous slide")
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("Step \(page + 1) of \(slides.count)")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.appTextSecondary)
                        .tracking(0.6)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)

                TabView(selection: $page) {
                    OnboardingSlide(
                        badge: slides[0].badge,
                        headline: slides[0].title,
                        subtitle: slides[0].subtitle,
                        illustration: { OnboardingSlideOneIllustration() }
                    )
                    .tag(0)

                    OnboardingSlide(
                        badge: slides[1].badge,
                        headline: slides[1].title,
                        subtitle: slides[1].subtitle,
                        illustration: { OnboardingSlideTwoIllustration() }
                    )
                    .tag(1)

                    OnboardingSlide(
                        badge: slides[2].badge,
                        headline: slides[2].title,
                        subtitle: slides[2].subtitle,
                        illustration: { OnboardingSlideThreeIllustration() }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.28), value: page)

                OnboardingPageIndicators(count: slides.count, current: page)
                    .padding(.top, 12)

                Button(action: advance) {
                    Text(page == slides.count - 1 ? "Get started" : "Continue")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(minHeight: 52)
                        .frame(maxWidth: .infinity)
                        .background(AppPrimaryProminentBackground(useCapsule: true))
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
    }

    private func advance() {
        AppFeedback.buttonTapLight()
        if page < slides.count - 1 {
            withAnimation(.easeInOut(duration: 0.28)) {
                page += 1
            }
            return
        }
        AppFeedback.actionMedium()
        appState.markOnboardingSeen()
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Slide container

private struct OnboardingSlide<Illustration: View>: View {
    let badge: String
    let headline: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                illustration()
                    .frame(maxWidth: .infinity)
                    .frame(height: 248)

                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 4, height: 44)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(badge.uppercased())
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.appAccent.opacity(0.95))
                            .tracking(0.8)

                        Text(headline)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)
                            .minimumScaleFactor(0.78)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtitle)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Page dots (capsule segments)

private struct OnboardingPageIndicators: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< count, id: \.self) { idx in
                Capsule(style: .continuous)
                    .fill(idx == current ? AnyShapeStyle(AppThemeGradients.primaryProminent) : AnyShapeStyle(Color.appSurface.opacity(0.55)))
                    .frame(width: idx == current ? 28 : 8, height: 8)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                idx == current ? Color.clear : Color.appAccent.opacity(0.25),
                                lineWidth: 1
                            )
                    )
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: current)
            }
        }
    }
}

// MARK: - Illustration 1 — hero + checklist (Home-inspired)

private struct OnboardingSlideOneIllustration: View {
    @State private var appear = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.5),
                            Color.appAccent.opacity(0.28),
                            Color.appSurface.opacity(0.88),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            OnboardingFloatingSymbols()

            VStack(alignment: .leading, spacing: 12) {
                ForEach(0 ..< 3, id: \.self) { row in
                    HStack(spacing: 12) {
                        Image(systemName: row == 0 ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(row == 0 ? Color.appAccent : Color.appTextSecondary.opacity(0.75))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appTextSecondary.opacity(row == 0 ? 0.5 : 0.35),
                                        Color.appTextSecondary.opacity(0.18),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: row == 0 ? 11 : 9)
                    }
                    .opacity(row == 0 ? 1 : 0.78)
                }
            }
            .padding(20)
            .background(AppCardBackgroundShape(cornerRadius: 18, emphasized: true))
            .padding(16)
        }
        .scaleEffect(appear ? 1 : 0.92)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
                appear = true
            }
        }
    }
}

private struct OnboardingFloatingSymbols: View {
    var body: some View {
        ZStack {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appAccent.opacity(0.75), Color.appPrimary.opacity(0.45))
                .symbolRenderingMode(.palette)
                .offset(x: 92, y: -36)

            Image(systemName: "leaf.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.appAccent.opacity(0.65))
                .offset(x: -88, y: -28)
                .rotationEffect(.degrees(-10))

            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(Color.appPrimary.opacity(0.85))
                .offset(x: 72, y: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

// MARK: - Illustration 2 — task card + chips (Tasks-inspired)

private struct OnboardingSlideTwoIllustration: View {
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AppSectionHeader(title: "MY TASKS")
                Spacer(minLength: 0)
                Capsule()
                    .fill(AppThemeGradients.primaryProminent)
                    .frame(width: 36, height: 8)
                    .opacity(0.88)
            }

            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.78), Color.appAccent.opacity(0.48)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 132, height: 13)

                HStack(spacing: 8) {
                    Text("HIGH")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Color.appTextPrimary.opacity(0.95))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appPrimary.opacity(0.62), Color.appPrimary.opacity(0.38)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    Text("TODAY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                                .background(Capsule().fill(Color.appBackground.opacity(0.35)))
                        )
                }

                Path { path in
                    path.move(to: CGPoint(x: 8, y: 8))
                    path.addQuadCurve(to: CGPoint(x: 110, y: 36), control: CGPoint(x: 72, y: -4))
                    path.addQuadCurve(to: CGPoint(x: 188, y: 10), control: CGPoint(x: 158, y: 62))
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.65), Color.appAccent.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .frame(height: 48)
            }
            .padding(22)
            .background(AppCardBackgroundShape(cornerRadius: 22, emphasized: true))
        }
        .scaleEffect(appear ? 1 : 0.9)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.74)) {
                appear = true
            }
        }
    }
}

// MARK: - Illustration 3 — focus ring + streak (no blur, perf-safe)

private struct OnboardingSlideThreeIllustration: View {
    @State private var appear = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appSurface.opacity(0.55), lineWidth: 14)
                .frame(width: 118, height: 118)

            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 118, height: 118)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appAccent)

                Text("25:00")
                    .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.appTextPrimary)
            }

            ForEach(0 ..< 5, id: \.self) { index in
                let angle = Double(index) / 5 * Double.pi * 2 - .pi / 2
                Circle()
                    .fill(Color.appAccent.opacity(index % 2 == 0 ? 0.85 : 0.55))
                    .frame(width: 12, height: 12)
                    .offset(x: cos(angle) * 96, y: sin(angle) * 96)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppCardBackgroundShape(cornerRadius: 24, emphasized: false))
        .scaleEffect(appear ? 1 : 0.88)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.74)) {
                appear = true
            }
        }
    }
}
