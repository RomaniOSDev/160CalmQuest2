//
//  ShakeEffect.swift
//  160CalmQuest2
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 6
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 2), y: 0))
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(shakes: CGFloat(trigger)))
    }
}
