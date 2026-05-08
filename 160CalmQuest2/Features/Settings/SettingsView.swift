//
//  SettingsView.swift
//  160CalmQuest2
//

import StoreKit
import SwiftUI
import UIKit

private struct ExportShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showResetAlert = false
    @State private var exportShareItem: ExportShareItem?

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            LayeredBackground {
                List {
                    statsSection

                    Section {
                        Button {
                            AppFeedback.buttonTapLight()
                            rateApp()
                        } label: {
                            SettingsRowLabel(icon: "star.fill", title: "Rate us", showChevron: false, orbAccent: Color.appAccent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }

                        Button {
                            AppFeedback.buttonTapLight()
                            openExternalURL(.privacyPolicy)
                        } label: {
                            SettingsRowLabel(icon: "hand.raised.fill", title: "Privacy Policy", showChevron: true)
                                .frame(minHeight: 44)
                        }

                        Button {
                            AppFeedback.buttonTapLight()
                            openExternalURL(.termsOfUse)
                        } label: {
                            SettingsRowLabel(icon: "doc.text.fill", title: "Terms of Use", showChevron: true)
                                .frame(minHeight: 44)
                        }

                        Button {
                            AppFeedback.buttonTapLight()
                            openSupportMail()
                        } label: {
                            SettingsRowLabel(icon: "envelope.circle", title: "Support", showChevron: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }
                    } header: {
                        AppSectionHeader(title: "APP")
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppListRowCardBackground())

                    Section {
                        Button {
                            AppFeedback.buttonTapLight()
                            exportTasksCSV()
                        } label: {
                            SettingsRowLabel(
                                icon: "square.and.arrow.up.on.square",
                                title: "Export tasks (CSV)",
                                showChevron: false,
                                orbAccent: Color.appPrimary
                            )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }

                        Button {
                            AppFeedback.buttonTapLight()
                            exportHabitsCSV()
                        } label: {
                            SettingsRowLabel(
                                icon: "square.and.arrow.up.on.square",
                                title: "Export habits (CSV)",
                                showChevron: false,
                                orbAccent: Color.appPrimary
                            )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }

                        Button {
                            AppFeedback.buttonTapLight()
                            exportPlainText()
                        } label: {
                            SettingsRowLabel(
                                icon: "doc.text",
                                title: "Export summary (.txt)",
                                showChevron: false,
                                orbAccent: Color.appAccent
                            )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }
                    } header: {
                        AppSectionHeader(title: "EXPORT")
                    } footer: {
                        Text("Files are generated on-device. Use Share to save to Files or send.")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppListRowCardBackground())

                    Section {
                        Button(role: .destructive) {
                            AppFeedback.actionMedium()
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 14) {
                                SettingsIconOrb(systemName: "trash.fill", accent: Color.appPrimary.opacity(0.85))
                                Text("Reset All Data")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .minimumScaleFactor(0.74)
                            .lineLimit(1)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppListRowCardBackground())

                    Section {
                        VStack(spacing: 8) {
                            Text("Version \(shortVersion)")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .background(AppCardBackgroundShape(cornerRadius: 16))
                    }

                    Section {
                        Color.clear
                            .frame(height: MainTabBarLayout.scrollBottomInset)
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollIndicators(.automatic)
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .preferredColorScheme(.dark)
                .appToolbarGradientBackground()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    AppFeedback.buttonTapLight()
                }
                Button("Erase", role: .destructive) {
                    AppFeedback.actionMedium()
                    appState.resetAllData()
                }
            } message: {
                Text("This will permanently remove all locally stored items, settings, progress, and achievements on this device.")
            }
            .preferredColorScheme(.dark)
            .sheet(item: $exportShareItem, onDismiss: {
                exportShareItem = nil
            }) { item in
                ActivityShareView(items: [item.url])
            }
        }
    }

    private func exportTasksCSV() {
        do {
            let csv = DataExportBuilder.csvTasks(appState.tasks)
            let url = try DataExportBuilder.writeTemporaryFile(content: csv, filename: "calmquest-tasks.csv")
            exportShareItem = ExportShareItem(url: url)
        } catch {
            AppFeedback.warning()
        }
    }

    private func exportHabitsCSV() {
        do {
            let csv = DataExportBuilder.csvHabits(appState.habits)
            let url = try DataExportBuilder.writeTemporaryFile(content: csv, filename: "calmquest-habits.csv")
            exportShareItem = ExportShareItem(url: url)
        } catch {
            AppFeedback.warning()
        }
    }

    private func exportPlainText() {
        do {
            let text = DataExportBuilder.plainTextExport(tasks: appState.tasks, habits: appState.habits)
            let url = try DataExportBuilder.writeTemporaryFile(content: text, filename: "calmquest-export.txt")
            exportShareItem = ExportShareItem(url: url)
        } catch {
            AppFeedback.warning()
        }
    }

    private var statsSection: some View {
        Section {
            AppCardContainer(cornerRadius: 20, emphasized: true) {
                VStack(alignment: .leading, spacing: 14) {
                    AppSectionHeader(title: "OVERVIEW")

                    VStack(spacing: 10) {
                        statRow(title: "Entries created", value: "\(appState.tasksCreatedTotal + appState.habits.count)")
                        statRow(title: "Tasks completed", value: "\(appState.tasksCompleted)")
                        statRow(title: "Focus sessions", value: "\(appState.focusSessionsCompleted)")
                        statRow(title: "Minutes focused (est.)", value: "\(appState.totalMinutesUsed)")
                        statRow(title: "Habit check-ins", value: "\(appState.habitCheckIns)")
                        statRow(title: "Current streak", value: "\(appState.streakDaysCurrent)d")
                        statRow(title: "Longest streak", value: "\(appState.longestStreak)d")
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private func statRow(title: String, value: String) -> some View {
        AppInnerMetricSlab {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 12)
                Text(value)
                    .foregroundStyle(Color.appAccent)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
            }
        }
    }

    private func openExternalURL(_ link: AppExternalURL) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func openSupportMail() {
        let address = "support@example.com"
        let subject = "Support request"
        let body = "Hello,\n\n"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(address)?subject=\(encodedSubject)&body=\(encodedBody)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
