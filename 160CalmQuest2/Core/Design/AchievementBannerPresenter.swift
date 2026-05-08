//
//  AchievementBannerPresenter.swift
//  160CalmQuest2
//

import Combine
import SwiftUI

@MainActor
final class AchievementBannerPresenter: ObservableObject {
    @Published private(set) var currentTitle: String?
    private var queue: [String] = []

    func enqueue(titles: [String]) {
        for title in titles where !title.isEmpty {
            queue.append(title)
        }
        presentNextIfIdle()
    }

    func acknowledgeDismissal() {
        currentTitle = nil
        presentNextIfIdle()
    }

    private func presentNextIfIdle() {
        guard currentTitle == nil, !queue.isEmpty else { return }
        currentTitle = queue.removeFirst()
    }
}

struct AchievementTopBanner: View {
    @ObservedObject var presenter: AchievementBannerPresenter
    @State private var offset: CGFloat = -120

    var body: some View {
        GeometryReader { geo in
            Group {
                if let title = presenter.currentTitle {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.appAccent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Achievement unlocked")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(Color.appTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 14)
                    .offset(y: offset)
                    .onAppear {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = -140
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                                presenter.acknowledgeDismissal()
                                offset = -120
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, geo.safeAreaInsets.top + 8)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: [.top])
        .accessibilityHidden(true)
    }
}
