//
//  PrivacyPolicyView.swift
//  160CalmQuest2
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let markdown: String

    init(markdown: String = PrivacyPolicyText.loadMarkdown()) {
        self.markdown = markdown
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let attributed = try? AttributedString(markdown: markdown) {
                        Text(attributed)
                            .foregroundStyle(Color.appTextPrimary)
                            .tint(Color.appPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(markdown)
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground.opacity(0.35))
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        AppFeedback.buttonTapLight()
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .preferredColorScheme(.dark)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppThemeGradients.navigationBar, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
