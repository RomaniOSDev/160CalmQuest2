//
//  MainTabBarLayout.swift
//  160CalmQuest2
//

import SwiftUI

/// Spacing for screens shown inside `MainShellView` so scroll/list content clears the custom tab dock.
enum MainTabBarLayout {
    /// Bottom inset inside `ScrollView` / `List` content (above the tab bar area).
    static let scrollBottomInset: CGFloat = 88

    /// Habits screen: extra space for the floating action above the dock.
    static let habitsFloatingActionClearance: CGFloat = 76
}

extension View {
    /// Pads scrollable content so it does not sit under the main tab bar.
    func scrollInsetAboveMainTabBar(_ extra: CGFloat = 0) -> some View {
        padding(.bottom, MainTabBarLayout.scrollBottomInset + extra)
    }
}
