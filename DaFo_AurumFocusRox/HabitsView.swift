//
//  HabitsView.swift
//  AurumFocus
//

import SwiftUI

struct HabitsView: View {
    @ObservedObject var dataManagers: DataManagers
    @State private var showingAddHabit = false
    @State private var habitToDelete: Habit?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AurumTheme.padding) {
                        ForEach(dataManagers.appState.habits, id: \.id) { habit in
                            HabitCardView(
                                habit: habit,
                                dataManagers: dataManagers,
                                onDelete: {
                                    habitToDelete = habit
                                    showingDeleteAlert = true
                                }
                            )
                        }
                        
                        if dataManagers.appState.habits.isEmpty {
                            EmptyHabitsView()
                        }
                    }
                    .padding(.horizontal, AurumTheme.padding)
                    .padding(.bottom, 100)
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddHabit = true }) {
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
                        .accessibleButton(AccessibilityLabels.addHabit, hint: AccessibilityHints.addHabit)
                        .accessibilityIdentifier(AccessibilityIdentifiers.addHabitButton)
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(dataManagers: dataManagers)
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let habit = habitToDelete {
                    dataManagers.deleteHabit(habit)
                    habitToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this habit? All progress will be lost.")
        }
    }
}

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var dataManagers: DataManagers
    let onDelete: () -> Void
    
    private var weeklyProgress: (completed: Int, target: Int) {
        let today = Date()
        let weekLogs = habit.logsForWeek(today)
        return (weekLogs.count, habit.targetPerWeek)
    }
    
    private var weeklyProgressPercentage: Double {
        let progress = weeklyProgress
        guard progress.target > 0 else { return 0 }
        return min(Double(progress.completed) / Double(progress.target), 1.0)
    }
    
    private var hasLoggedToday: Bool {
        habit.hasLogForDate(Date())
    }
    
    var body: some View {
        VStack(spacing: AurumTheme.padding) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.aurumHeadline)
                        .foregroundColor(AurumTheme.primaryText)
                    
                    Text("\(weeklyProgress.completed) of \(weeklyProgress.target) this week")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AurumTheme.danger)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Weekly progress bar
            VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                HStack {
                    Text("Weekly Progress")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(weeklyProgressPercentage * 100))%")
                        .font(.aurumCaption.monospacedDigit())
                        .foregroundColor(AurumTheme.goldAccent)
                }
                
                WeeklyProgressBar(progress: weeklyProgressPercentage)
            }
            
            // Today's toggle
            HStack {
                Text("Today")
                    .font(.aurumSubheadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                Spacer()
                
                Button(action: toggleTodaysLog) {
                    Image(systemName: hasLoggedToday ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(hasLoggedToday ? AurumTheme.success : AurumTheme.goldAccent)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibleButton(AccessibilityLabels.toggleHabit, hint: AccessibilityHints.toggleHabit)
                .accessibilityValue(hasLoggedToday ? "Completed today" : "Not completed today")
            }
            
            // 4-week heatmap
            VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                Text("Last 4 Weeks")
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
                
                HabitHeatmapView(habit: habit)
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private func toggleTodaysLog() {
        var updatedHabit = habit
        updatedHabit.toggleLogForDate(Date())
        dataManagers.updateHabit(updatedHabit)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct WeeklyProgressBar: View {
    let progress: Double
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AurumTheme.dividers)
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AurumTheme.goldAccent, AurumTheme.secondaryGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress, height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.6), value: animatedProgress)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}

struct HabitHeatmapView: View {
    let habit: Habit
    
    private var heatmapData: [[Bool]] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the last 4 weeks (28 days)
        var weeks: [[Bool]] = []
        
        for weekOffset in (0..<4).reversed() {
            var week: [Bool] = []
            
            // Get the start of the week for this offset
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                continue
            }
            
            // Get each day of the week
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) {
                    let hasLog = habit.hasLogForDate(day)
                    week.append(hasLog)
                }
            }
            
            weeks.append(week)
        }
        
        return weeks
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(heatmapData.enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 4) {
                    ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, hasLog in
                        Rectangle()
                            .fill(hasLog ? AurumTheme.goldAccent : AurumTheme.dividers)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                            .scaleEffect(hasLog ? 1.0 : 0.8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(Double(weekIndex * 7 + dayIndex) * 0.02), value: hasLog)
                    }
                }
            }
        }
    }
}

struct EmptyHabitsView: View {
    var body: some View {
        VStack(spacing: AurumTheme.padding) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(AurumTheme.secondaryText)
            
            VStack(spacing: AurumTheme.smallPadding) {
                Text("No habits yet")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                Text("Start building positive habits by tapping the + button")
                    .font(.aurumBody)
                    .foregroundColor(AurumTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AurumTheme.largePadding)
        .cardStyle()
    }
}

struct AddHabitView: View {
    @ObservedObject var dataManagers: DataManagers
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var targetPerWeek: Int = 3
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
                        Text("Habit Title")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        TextField("Enter habit title...", text: $title)
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
                    
                    // Target per week
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Target per week")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        Stepper(value: $targetPerWeek, in: 1...7) {
                            Text("\(targetPerWeek) times per week")
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.primaryText)
                        }
                        .accentColor(AurumTheme.goldAccent)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button("Save Habit") {
                        saveHabit()
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
                            Text("Habit saved")
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
            .navigationTitle("Add Habit")
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
    
    private func saveHabit() {
        let habit = Habit(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            targetPerWeek: targetPerWeek,
            logs: []
        )
        
        dataManagers.addHabit(habit)
        
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
    HabitsView(dataManagers: DataManagers())
}
