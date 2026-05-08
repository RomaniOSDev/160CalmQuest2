//
//  NotificationName+App.swift
//  160CalmQuest2
//

import Foundation

extension Notification.Name {
    static let dataReset = Notification.Name("calmquest.dataReset")
    /// userInfo: ["tab": MainShellView.Tab.RawValue] as Int
    static let switchMainTab = Notification.Name("calmquest.switchMainTab")
}
