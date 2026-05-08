//
//  LayeredBackground.swift
//  160CalmQuest2
//

import SwiftUI

/// Root backdrop for most screens. Kept lightweight: avoid Canvas dot grids and heavy blur — they
/// caused GPU/compositor overload when combined with many shadowed cards.
struct LayeredBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.appBackground,
                        Color.appSurface.opacity(0.42),
                        Color.appPrimary.opacity(0.12),
                        Color.appBackground,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.22), Color.clear],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 280
                        )
                    )
                    .offset(x: -80, y: -120)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent.opacity(0.16), Color.clear],
                            center: .bottomTrailing,
                            startRadius: 10,
                            endRadius: 240
                        )
                    )
                    .offset(x: 100, y: 160)
            }
            .ignoresSafeArea()

            content
        }
    }
}
