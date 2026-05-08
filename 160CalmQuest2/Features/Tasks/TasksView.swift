//
//  TasksView.swift
//  160CalmQuest2
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TasksViewModel()

    @State private var editorWrapper: IdentifiableTask?
    @State private var editorIsNew = false

    var body: some View {
        NavigationStack {
            LayeredBackground {
                VStack(spacing: 0) {
                    QuickTaskTemplatesBar { tpl in
                        AppFeedback.buttonTapLight()
                        editorIsNew = true
                        editorWrapper = IdentifiableTask(
                            TaskItem(title: tpl.title, category: tpl.category, priority: .medium)
                        )
                    }
                    TasksListContent(
                        viewModel: viewModel,
                        onEdit: { task in
                            AppFeedback.buttonTapLight()
                            editorIsNew = false
                            editorWrapper = IdentifiableTask(task)
                        },
                        onAdd: {
                            AppFeedback.actionMedium()
                            editorIsNew = true
                            editorWrapper = IdentifiableTask(
                                TaskItem(
                                    title: "",
                                    category: "General",
                                    priority: .medium,
                                    status: .todo
                                )
                            )
                        }
                    )
                    TasksFilterBar(filter: $viewModel.filter)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppCardBackgroundShape(cornerRadius: 20))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppFeedback.buttonTapLight()
                        editorIsNew = true
                        editorWrapper = IdentifiableTask(
                            TaskItem(
                                title: "",
                                category: "General",
                                priority: .medium,
                                status: .todo
                            )
                        )
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Add Task")
                }
            }
            .sheet(item: $editorWrapper) { wrapper in
                TaskEditorSheet(task: wrapper.task, isNew: editorIsNew)
                    .environmentObject(appState)
            }
            .preferredColorScheme(.dark)
            .appToolbarGradientBackground()
        }
    }
}

private struct QuickTaskTemplatesBar: View {
    let onPick: (QuickTaskTemplate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Text("Templates")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary)

                ForEach(QuickTaskTemplate.builtIn) { tpl in
                    Button {
                        onPick(tpl)
                    } label: {
                        Text(tpl.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(Color.appTextPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(minHeight: 44)
                            .background(AppFilterChipStyle(isSelected: false).chipBackground())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

private struct TasksListContent: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: TasksViewModel
    let onEdit: (TaskItem) -> Void
    let onAdd: () -> Void

    var body: some View {
        let filtered = viewModel.filtered(from: appState.tasks)
        let grouped = viewModel.sections(filtered: filtered)

        List {
            if appState.tasks.isEmpty {
                Section {
                    EmptyTasksCallout(onAddTap: {
                        AppFeedback.buttonTapLight()
                        onAdd()
                    })
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(grouped, id: \.0) { pair in
                    Section {
                        ForEach(pair.1) { task in
                            TaskRow(
                                task: task,
                                onToggleCompletion: {
                                    let willComplete = task.status != .completed
                                    appState.markTaskCheckbox(id: task.id, complete: willComplete)
                                    return willComplete
                                },
                                onOpenEdit: { onEdit(task) },
                                onDelete: {
                                    AppFeedback.actionMedium()
                                    appState.deleteTask(id: task.id)
                                },
                                onChangePriority: { priority in
                                    AppFeedback.buttonTapLight()
                                    appState.updateTaskPriority(id: task.id, priority: priority)
                                },
                                onMarkInProgress: {
                                    AppFeedback.buttonTapLight()
                                    appState.setTaskStatus(id: task.id, status: .inProgress)
                                },
                                completeSwipe: {
                                    AppFeedback.actionMedium()
                                    appState.setTaskStatus(id: task.id, status: .completed)
                                }
                            )
                            .environmentObject(appState)
                            .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        AppSectionHeader(title: pair.0.sectionTitle.uppercased())
                    }
                }
            }

            Section {
                Color.clear
                    .frame(height: MainTabBarLayout.scrollBottomInset)
                    .listRowBackground(Color.clear)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: filtered.map(\.id))
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.automatic)
        .padding(.top, 4)
    }
}

private struct EmptyTasksCallout: View {
    let onAddTap: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)

            Text("No tasks yet! Tap + to add your first task.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, 12)

            Button(action: {
                AppFeedback.buttonTapLight()
                onAddTap()
            }) {
                Text("Quick Add Task")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(AppPrimaryProminentBackground(useCapsule: true))
            }
            .buttonStyle(TabPressButtonStyle())
            .padding(.top, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(AppCardBackgroundShape(cornerRadius: 20, emphasized: true))
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appear = true
            }
        }
    }
}

private struct TasksFilterBar: View {
    @Binding var filter: TaskFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases) { item in
                    Button {
                        AppFeedback.buttonTapLight()
                        filter = item
                    } label: {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(filter == item ? Color.appTextPrimary : Color.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 44)
                            .background(AppFilterChipStyle(isSelected: filter == item).chipBackground())
                    }
                    .buttonStyle(TabPressButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct TabPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

private struct TaskRow: View {
    @EnvironmentObject private var appState: AppState
    let task: TaskItem
    let onToggleCompletion: () -> Bool
    let onOpenEdit: () -> Void
    let onDelete: () -> Void
    let onChangePriority: (TaskPriority) -> Void
    let onMarkInProgress: () -> Void
    let completeSwipe: () -> Void

    @State private var showCheckBadge = false
    @State private var pulseAccent = false

    var body: some View {
        HStack(spacing: 14) {
            Button {
                AppFeedback.buttonTapLight()
                let didCompleteAttempt = onToggleCompletion()
                if didCompleteAttempt {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.66)) {
                        showCheckBadge = true
                        pulseAccent = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
                        withAnimation(.easeOut(duration: 0.38)) {
                            showCheckBadge = false
                            pulseAccent = false
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        pulseAccent = false
                        showCheckBadge = false
                    }
                }
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(task.status == .completed ? Color.appAccent : Color.appTextSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: {
                AppFeedback.buttonTapLight()
                onOpenEdit()
            }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title.isEmpty ? "Untitled Task" : task.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    HStack(spacing: 8) {
                        Text(task.category.isEmpty ? "Uncategorized" : task.category)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)

                        PriorityCapsule(priority: task.priority)

                        StatusPill(status: task.status)

                        if let due = task.dueDate {
                            Text(Self.shortDueLabel(due))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.appAccent)
                        }

                        if let prog = task.subtasksProgressLabel() {
                            Text(prog)
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(Color.appTextPrimary.opacity(0.95))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.appPrimary.opacity(0.58), Color.appAccent.opacity(0.38)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.appPrimary.opacity(0.35), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("Edit", action: onOpenEdit)
                Button("Mark In Progress", action: onMarkInProgress)
                Menu("Priority") {
                    Button("Low") { onChangePriority(.low) }
                    Button("Medium") { onChangePriority(.medium) }
                    Button("High") { onChangePriority(.high) }
                }
                Divider()
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppCardBackgroundShape(cornerRadius: 16))
        .accentPulse(active: pulseAccent)
        .overlay(alignment: .trailing) {
            trailingBadge
        }
        .contextMenu {
            Button("Edit", action: onOpenEdit)
            Button("Mark In Progress", action: onMarkInProgress)
            Menu("Change Priority") {
                Button("Low") { onChangePriority(.low) }
                Button("Medium") { onChangePriority(.medium) }
                Button("High") { onChangePriority(.high) }
            }
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash.fill")
            }
            Button(action: completeSwipe) {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(Color.appAccent)
            .disabled(task.status == .completed)
        }
        .swipeActions(edge: .leading) {
            Button(action: {
                AppFeedback.actionMedium()
                onMarkInProgress()
            }) {
                Label("In Progress", systemImage: "bolt.fill")
            }
            .tint(Color.appPrimary)
        }
    }

    private static func shortDueLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return df.string(from: date)
    }

    private var trailingBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.appAccent)
            .font(.title3.weight(.bold))
            .opacity(showCheckBadge ? 1 : 0)
            .scaleEffect(showCheckBadge ? 1 : 0.35)
            .animation(.spring(response: 0.32, dampingFraction: 0.65), value: showCheckBadge)
            .padding(.trailing, 4)
    }
}

private struct PriorityCapsule: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.displayTitle.uppercased())
            .font(.caption2.weight(.heavy))
            .foregroundStyle(Color.appTextPrimary.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.58)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.appTextPrimary.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
    }

    private var color: Color {
        switch priority {
        case .high: return Color.appPrimary.opacity(0.55)
        case .medium: return Color.appAccent.opacity(0.5)
        case .low: return Color.appTextSecondary.opacity(0.35)
        }
    }
}

private struct StatusPill: View {
    let status: TaskStatus

    var body: some View {
        Text(status.shortLabel.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.appTextPrimary.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appBackground.opacity(0.55), Color.appSurface.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.38), Color.appPrimary.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 2)
    }
}

private extension TaskStatus {
    var shortLabel: String {
        switch self {
        case .todo: return "Todo"
        case .inProgress: return "Active"
        case .completed: return "Done"
        }
    }
}

struct IdentifiableTask: Identifiable, Equatable {
    let id: UUID
    var task: TaskItem

    init(_ task: TaskItem) {
        id = task.id
        self.task = task
    }
}

private struct TaskEditorSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft: TaskItem
    @State private var shakeToken = 0
    @State private var helperText = ""

    let isNew: Bool

    init(task: TaskItem, isNew: Bool) {
        _draft = State(initialValue: task)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draft.title)
                        .foregroundStyle(Color.appTextPrimary)
                        .shake(trigger: shakeToken)

                    if !helperText.isEmpty {
                        Text(helperText)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.appPrimary)
                    }

                    TextField("Category", text: $draft.category)
                        .foregroundStyle(Color.appTextPrimary)

                    Picker("Priority", selection: $draft.priority) {
                        ForEach(TaskPriority.allCases) { tier in
                            Text(tier.displayTitle).tag(tier)
                        }
                    }

                    Picker("Status", selection: $draft.status) {
                        ForEach(TaskStatus.allCases) { role in
                            Text(role.sectionTitle).tag(role)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())

                Section {
                    Toggle(
                        "Due date",
                        isOn: Binding(
                            get: { draft.dueDate != nil },
                            set: { enabled in
                                if enabled {
                                    draft.dueDate = Calendar.current.startOfDay(for: Date())
                                } else {
                                    draft.dueDate = nil
                                }
                            }
                        )
                    )
                    .foregroundStyle(Color.appTextPrimary)

                    if draft.dueDate != nil {
                        DatePicker(
                            "Due",
                            selection: Binding(
                                get: { draft.dueDate ?? Date() },
                                set: { draft.dueDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .foregroundStyle(Color.appTextPrimary)
                    }

                    Toggle(
                        "Reminder",
                        isOn: Binding(
                            get: { draft.reminderDate != nil },
                            set: { enabled in
                                if enabled {
                                    draft.reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
                                } else {
                                    draft.reminderDate = nil
                                }
                            }
                        )
                    )
                    .foregroundStyle(Color.appTextPrimary)

                    if draft.reminderDate != nil {
                        DatePicker(
                            "Remind at",
                            selection: Binding(
                                get: { draft.reminderDate ?? Date() },
                                set: { draft.reminderDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .foregroundStyle(Color.appTextPrimary)
                    }

                    Text("Allow notifications when prompted so reminders can alert you.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                } header: {
                    Text("Schedule")
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())

                Section {
                    ForEach(draft.subtasks.indices, id: \.self) { index in
                        HStack(alignment: .center, spacing: 10) {
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { draft.subtasks[index].isCompleted },
                                    set: { draft.subtasks[index].isCompleted = $0 }
                                )
                            )
                            .labelsHidden()
                            .tint(Color.appAccent)

                            TextField("Step", text: Binding(
                                get: { draft.subtasks[index].title },
                                set: { draft.subtasks[index].title = $0 }
                            ))
                            .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                    .onDelete(perform: deleteSubtasks)

                    Button {
                        AppFeedback.buttonTapLight()
                        draft.subtasks.append(SubtaskItem(title: ""))
                    } label: {
                        Label("Add step", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                } header: {
                    Text("Checklist")
                        .foregroundStyle(Color.appTextSecondary)
                } footer: {
                    Text("Break work into actionable steps.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(AppListRowCardBackground())
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.automatic)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .appToolbarGradientBackground()
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        AppFeedback.buttonTapLight()
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await persistIfValid()
                        }
                    }
                    .foregroundStyle(Color.appPrimary)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
        }
        .presentationDetents([.large])
        .modifier(FormSurfaceStyleModifier())
    }

    private func deleteSubtasks(at offsets: IndexSet) {
        draft.subtasks.remove(atOffsets: offsets)
    }

    private func persistIfValid() async {
        let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            AppFeedback.warning()
            helperText = "Please enter a title."
            shakeToken &+= 1
            return
        }
        helperText = ""
        draft.title = trimmed
        if draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.category = "General"
        }

        draft.subtasks = draft.subtasks.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if draft.reminderDate != nil {
            _ = await TaskReminderScheduler.requestAuthorization()
        }

        AppFeedback.actionMedium()
        appState.upsertTask(draft)
        dismiss()
    }
}

private struct FormSurfaceStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.opacity(0.25))
    }
}
