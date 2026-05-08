//
//  SuccessFlashOverlay.swift
//  160CalmQuest2
//

import SwiftUI

struct SuccessCheckmarkFlash: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                if isVisible {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .padding(.trailing, 10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }
}

extension View {
    func successCheckmarkFlash(isVisible: Bool) -> some View {
        modifier(SuccessCheckmarkFlash(isVisible: isVisible))
    }
}

struct AccentPulseModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appAccent.opacity(active ? 0.55 : 0.0), lineWidth: active ? 2 : 0)
                .animation(.easeInOut(duration: 0.4), value: active)
                .allowsHitTesting(false)
        }
    }
}

extension View {
    func accentPulse(active: Bool) -> some View {
        modifier(AccentPulseModifier(active: active))
    }
}
