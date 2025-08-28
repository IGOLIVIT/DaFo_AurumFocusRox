//
//  AccessibilityHelpers.swift
//  AurumFocus
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleValue(_ value: String) -> some View {
        self
            .accessibilityValue(value)
    }
    
    func accessibleCurrency(_ amount: Double) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        
        return self.accessibilityValue(formattedAmount)
    }
}

// MARK: - Accessibility Constants

struct AccessibilityIdentifiers {
    static let addTransactionButton = "add_transaction_button"
    static let addTaskButton = "add_task_button"
    static let addHabitButton = "add_habit_button"
    static let budgetProgressRing = "budget_progress_ring"
    static let incomeExpenseChart = "income_expense_chart"
    static let categoryExpenseChart = "category_expense_chart"
    static let habitHeatmap = "habit_heatmap"
    static let weeklyProgressBar = "weekly_progress_bar"
}

struct AccessibilityLabels {
    static let dashboard = "Dashboard"
    static let planner = "Planner"
    static let habits = "Habits"
    static let addTransaction = "Add new transaction"
    static let addTask = "Add new task"
    static let addHabit = "Add new habit"
    static let completeTask = "Mark task as complete"
    static let editTask = "Edit task"
    static let deleteTask = "Delete task"
    static let toggleHabit = "Toggle habit completion for today"
    static let budgetProgress = "Budget progress indicator"
    static let incomeCard = "Monthly income summary"
    static let expenseCard = "Monthly expenses summary"
    static let netIncomeCard = "Monthly net income"
}

struct AccessibilityHints {
    static let addTransaction = "Opens form to add a new income or expense transaction"
    static let addTask = "Opens form to create a new task with optional due date and priority"
    static let addHabit = "Opens form to create a new habit with weekly target"
    static let completeTask = "Marks this task as completed and moves it to done section"
    static let editTask = "Opens form to edit task details"
    static let deleteTask = "Permanently removes this task"
    static let toggleHabit = "Adds or removes a completion log for today"
    static let budgetProgress = "Shows how much of monthly budget has been spent"
    static let swipeActions = "Swipe left for more actions, swipe right to complete"
}
