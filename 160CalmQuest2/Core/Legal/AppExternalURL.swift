//
//  AppExternalURL.swift
//  160CalmQuest2
//

import Foundation

/// External pages opened via Safari / browser. Replace hosts with your production URLs.
enum AppExternalURL: CaseIterable {
    case privacyPolicy
    case termsOfUse

    /// Resolved URL for each case.
    var url: URL? {
        switch self {
        case .privacyPolicy:
            return URL(string: "https://calm160quest.site/privacy/155")
        case .termsOfUse:
            return URL(string: "https://calm160quest.site/terms/155")
        }
    }
}
