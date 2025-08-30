//
//  AddTaskView.swift
//  AurumFocus
//

import SwiftUI

struct AddTaskView: View {
    @ObservedObject var dataManagers: DataManagers
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var priority: Priority = .normal
    @State private var showingSuccessMessage = false
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: AurumTheme.largePadding) {
                    // Title input
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Title")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        TextField("Enter task title...", text: $title)
                            .font(.aurumBody)
                            .foregroundColor(AurumTheme.primaryText)
                            .padding(AurumTheme.padding)
                            .background(AurumTheme.inputField)
                            .cornerRadius(AurumTheme.smallRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                                    .stroke(canSave ? AurumTheme.goldAccent.opacity(0.3) : AurumTheme.dividers, lineWidth: 1)
                            )
                    }
                    
                    // Due date toggle and picker
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Toggle("Set due date", isOn: $hasDueDate)
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                            .toggleStyle(SwitchToggleStyle(tint: AurumTheme.goldAccent))
                        
                        if hasDueDate {
                            DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.primaryText)
                                .colorScheme(.dark)
                        }
                    }
                    
                    // Priority picker
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Priority")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button("Save Task") {
                        saveTask()
                    }
                    .primaryButtonStyle(isEnabled: canSave)
                    .disabled(!canSave)
                }
                .padding(AurumTheme.padding)
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AurumTheme.success)
                            Text("Task saved")
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.primaryText)
                        }
                        .padding(AurumTheme.padding)
                        .background(AurumTheme.surfaceCard)
                        .cornerRadius(AurumTheme.smallRadius)
                        .shadow(color: AurumTheme.cardShadow, radius: 8, x: 0, y: 4)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AurumTheme.secondaryText)
                }
            }
        }
    }
    
    private func saveTask() {
        let task = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            due: hasDueDate ? dueDate : nil,
            priority: priority,
            isDone: false
        )
        
        dataManagers.addTask(task)
        
        // Show success message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingSuccessMessage = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

struct EditTaskView: View {
    @ObservedObject var dataManagers: DataManagers
    @Environment(\.dismiss) private var dismiss
    
    let task: TaskItem
    
    @State private var title: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: Priority
    @State private var showingSuccessMessage = false
    
    init(dataManagers: DataManagers, task: TaskItem) {
        self.dataManagers = dataManagers
        self.task = task
        self._title = State(initialValue: task.title)
        self._dueDate = State(initialValue: task.due ?? Date())
        self._hasDueDate = State(initialValue: task.due != nil)
        self._priority = State(initialValue: task.priority)
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: AurumTheme.largePadding) {
                    // Title input
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Title")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        TextField("Enter task title...", text: $title)
                            .font(.aurumBody)
                            .foregroundColor(AurumTheme.primaryText)
                            .padding(AurumTheme.padding)
                            .background(AurumTheme.inputField)
                            .cornerRadius(AurumTheme.smallRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                                    .stroke(canSave ? AurumTheme.goldAccent.opacity(0.3) : AurumTheme.dividers, lineWidth: 1)
                            )
                    }
                    
                    // Due date toggle and picker
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Toggle("Set due date", isOn: $hasDueDate)
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                            .toggleStyle(SwitchToggleStyle(tint: AurumTheme.goldAccent))
                        
                        if hasDueDate {
                            DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.primaryText)
                                .colorScheme(.dark)
                        }
                    }
                    
                    // Priority picker
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Priority")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button("Update Task") {
                        saveTask()
                    }
                    .primaryButtonStyle(isEnabled: canSave)
                    .disabled(!canSave)
                }
                .padding(AurumTheme.padding)
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AurumTheme.success)
                            Text("Task updated")
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.primaryText)
                        }
                        .padding(AurumTheme.padding)
                        .background(AurumTheme.surfaceCard)
                        .cornerRadius(AurumTheme.smallRadius)
                        .shadow(color: AurumTheme.cardShadow, radius: 8, x: 0, y: 4)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AurumTheme.secondaryText)
                }
            }
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.due = hasDueDate ? dueDate : nil
        updatedTask.priority = priority
        
        dataManagers.updateTask(updatedTask)
        
        // Show success message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingSuccessMessage = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

#Preview {
    AddTaskView(dataManagers: DataManagers())
}
