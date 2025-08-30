//
//  PlannerView.swift
//  AurumFocus
//

import SwiftUI

struct PlannerView: View {
    @ObservedObject var dataManagers: DataManagers
    @State private var showingAddTask = false
    @State private var taskToEdit: TaskItem?
    @State private var taskToDelete: TaskItem?
    @State private var showingDeleteAlert = false
    
    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        
        return dataManagers.appState.tasks
            .filter { !$0.isDone }
            .filter { task in
                guard let due = task.due else { return false }
                return calendar.isDate(due, inSameDayAs: today)
            }
            .sorted(by: taskSortComparator)
    }
    
    private var upcomingTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        
        return dataManagers.appState.tasks
            .filter { !$0.isDone }
            .filter { task in
                guard let due = task.due else { return true } // Tasks without due date go to upcoming
                return due > calendar.startOfDay(for: today.addingTimeInterval(86400)) // Tomorrow and beyond
            }
            .sorted(by: taskSortComparator)
    }
    
    private var doneTasks: [TaskItem] {
        return dataManagers.appState.tasks
            .filter { $0.isDone }
            .sorted(by: taskSortComparator)
    }
    
    private func taskSortComparator(_ task1: TaskItem, _ task2: TaskItem) -> Bool {
        // First sort by due date
        switch (task1.due, task2.due) {
        case (let date1?, let date2?):
            if date1 != date2 {
                return date1 < date2
            }
        case (nil, _?):
            return false // Tasks without due date go last
        case (_?, nil):
            return true // Tasks with due date go first
        case (nil, nil):
            break // Both nil, continue to priority
        }
        
        // Then by priority (High -> Normal -> Low)
        let priority1Value = priorityValue(task1.priority)
        let priority2Value = priorityValue(task2.priority)
        if priority1Value != priority2Value {
            return priority1Value > priority2Value
        }
        
        // Finally by title
        return task1.title < task2.title
    }
    
    private func priorityValue(_ priority: Priority) -> Int {
        switch priority {
        case .high: return 3
        case .normal: return 2
        case .low: return 1
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AurumTheme.largePadding) {
                        // Today section
                        TaskSectionView(
                            title: "Today",
                            tasks: todayTasks,
                            dataManagers: dataManagers,
                            onEdit: { task in taskToEdit = task },
                            onDelete: { task in
                                taskToDelete = task
                                showingDeleteAlert = true
                            }
                        )
                        
                        // Upcoming section
                        TaskSectionView(
                            title: "Upcoming",
                            tasks: upcomingTasks,
                            dataManagers: dataManagers,
                            onEdit: { task in taskToEdit = task },
                            onDelete: { task in
                                taskToDelete = task
                                showingDeleteAlert = true
                            }
                        )
                        
                        // Done section
                        TaskSectionView(
                            title: "Done",
                            tasks: doneTasks,
                            dataManagers: dataManagers,
                            onEdit: { task in taskToEdit = task },
                            onDelete: { task in
                                taskToDelete = task
                                showingDeleteAlert = true
                            }
                        )
                    }
                    .padding(.horizontal, AurumTheme.padding)
                    .padding(.bottom, 100)
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(AurumTheme.backgroundPrimary)
                        }
                        .frame(width: 56, height: 56)
                        .background(AurumTheme.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: AurumTheme.cardShadow, radius: 8, x: 0, y: 4)
                        .padding(.trailing, AurumTheme.padding)
                        .padding(.bottom, 20)
                        .accessibleButton(AccessibilityLabels.addTask, hint: AccessibilityHints.addTask)
                        .accessibilityIdentifier(AccessibilityIdentifiers.addTaskButton)
                    }
                }
            }
            .navigationTitle("Planner")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(dataManagers: dataManagers)
        }
        .sheet(item: $taskToEdit) { task in
            EditTaskView(dataManagers: dataManagers, task: task)
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    dataManagers.deleteTask(task)
                    taskToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
}

struct TaskSectionView: View {
    let title: String
    let tasks: [TaskItem]
    @ObservedObject var dataManagers: DataManagers
    let onEdit: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            HStack {
                Text(title)
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
                    .padding(.horizontal, AurumTheme.smallPadding)
                    .padding(.vertical, 4)
                    .background(AurumTheme.dividers)
                    .cornerRadius(AurumTheme.smallRadius)
            }
            
            if tasks.isEmpty {
                Text(emptyMessage)
                    .font(.aurumBody)
                    .foregroundColor(AurumTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AurumTheme.largePadding)
            } else {
                VStack(spacing: AurumTheme.smallPadding) {
                    ForEach(tasks, id: \.id) { task in
                        TaskItemView(
                            task: task,
                            dataManagers: dataManagers,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) }
                        )
                    }
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var emptyMessage: String {
        switch title {
        case "Today": return "No tasks for today"
        case "Upcoming": return "No upcoming tasks"
        case "Done": return "No completed tasks"
        default: return "No tasks"
        }
    }
}

struct TaskItemView: View {
    let task: TaskItem
    @ObservedObject var dataManagers: DataManagers
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AurumTheme.padding) {
            // Complete button
            Button(action: {
                var updatedTask = task
                updatedTask.isDone.toggle()
                dataManagers.updateTask(updatedTask)
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isDone ? AurumTheme.success : AurumTheme.goldAccent)
                    .font(.title3)
            }
            .accessibleButton(task.isDone ? "Mark as incomplete" : AccessibilityLabels.completeTask, 
                            hint: task.isDone ? "Mark this task as not completed" : AccessibilityHints.completeTask)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.aurumBody)
                    .foregroundColor(task.isDone ? AurumTheme.secondaryText : AurumTheme.primaryText)
                    .strikethrough(task.isDone)
                
                HStack(spacing: AurumTheme.smallPadding) {
                    // Due date
                    if let due = task.due {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(due, style: .date)
                                .font(.aurumCaption)
                        }
                        .foregroundColor(dueDateColor(due))
                    }
                    
                    // Priority
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 6, height: 6)
                        Text(task.priority.displayName)
                            .font(.aurumCaption)
                            .foregroundColor(AurumTheme.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AurumTheme.smallPadding)
        .contentShape(Rectangle())
        .accessibilityHint(AccessibilityHints.swipeActions)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            .accessibilityLabel(AccessibilityLabels.deleteTask)
            .accessibilityHint(AccessibilityHints.deleteTask)
            
            Button("Edit") {
                onEdit()
            }
            .tint(AurumTheme.goldAccent)
            .accessibilityLabel(AccessibilityLabels.editTask)
            .accessibilityHint(AccessibilityHints.editTask)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(task.isDone ? "Undo" : "Complete") {
                var updatedTask = task
                updatedTask.isDone.toggle()
                dataManagers.updateTask(updatedTask)
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            .tint(task.isDone ? AurumTheme.warning : AurumTheme.success)
            .accessibilityLabel(task.isDone ? "Mark as incomplete" : AccessibilityLabels.completeTask)
            .accessibilityHint(task.isDone ? "Mark this task as not completed" : AccessibilityHints.completeTask)
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDate(date, inSameDayAs: today) {
            return AurumTheme.warning
        } else if date < today {
            return AurumTheme.danger
        } else {
            return AurumTheme.secondaryText
        }
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return AurumTheme.secondaryText
        case .normal: return AurumTheme.goldAccent
        case .high: return AurumTheme.danger
        }
    }
}

#Preview {
    PlannerView(dataManagers: DataManagers())
}
