//
//  DataManager.swift
//  AurumFocus
//

import Foundation
import Combine

class DataManager: ObservableObject {
    @Published var appState = AppState()
    
    private let fileName = "appstate.json"
    private var saveWorkItem: DispatchWorkItem?
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }
    
    init() {
        loadState()
        
        // Check if we have old test data and reset if needed
        if hasOldTestData() {
            print("Detected old test data, resetting to clean state...")
            resetAllData()
        }
    }
    
    // MARK: - Persistence
    
    private func loadState() {
        do {
            let data = try Data(contentsOf: fileURL)
            appState = try JSONDecoder().decode(AppState.self, from: data)
        } catch {
            // File doesn't exist or is corrupted, use seeded data
            createSeededData()
        }
    }
    
    func saveState() {
        // Cancel previous save work item
        saveWorkItem?.cancel()
        
        // Create new debounced save
        saveWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try JSONEncoder().encode(self.appState)
                try data.write(to: self.fileURL)
            } catch {
                print("Failed to save app state: \(error)")
            }
        }
        
        // Execute after 0.5 second delay
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5, execute: saveWorkItem!)
    }
    
    // MARK: - Seeded Data
    
    private func createSeededData() {
        // Create empty state for first launch - no pre-filled data
        appState = AppState()
        appState.transactions = []
        appState.budgets = []
        appState.habits = []
        appState.tasks = []
        appState.onboardingCompleted = false
        
        saveState()
    }
    
    // MARK: - Data Operations
    
    func addTransaction(_ transaction: Transaction) {
        appState.transactions.append(transaction)
        saveState()
    }
    
    func addTask(_ task: TaskItem) {
        appState.tasks.append(task)
        saveState()
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = appState.tasks.firstIndex(where: { $0.id == task.id }) {
            appState.tasks[index] = task
            saveState()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        appState.tasks.removeAll { $0.id == task.id }
        saveState()
    }
    
    func addHabit(_ habit: Habit) {
        appState.habits.append(habit)
        saveState()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = appState.habits.firstIndex(where: { $0.id == habit.id }) {
            appState.habits[index] = habit
            saveState()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        appState.habits.removeAll { $0.id == habit.id }
        saveState()
    }
    
    func addBudget(_ budget: Budget) {
        // Remove existing budget for the same month/year if exists
        appState.budgets.removeAll { $0.month == budget.month && $0.year == budget.year }
        appState.budgets.append(budget)
        saveState()
    }
    
    func completeOnboarding() {
        appState.onboardingCompleted = true
        saveState()
    }
    
    private func createDefaultBudgetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        // Check if budget already exists for current month
        let existingBudget = appState.budgets.first { budget in
            budget.month == month && budget.year == year
        }
        
        if existingBudget == nil {
            // Create default budget with reasonable limits
            let categoryLimits = [
                CategoryLimit(category: .groceries, limit: 400.00),
                CategoryLimit(category: .transport, limit: 150.00),
                CategoryLimit(category: .entertainment, limit: 200.00),
                CategoryLimit(category: .health, limit: 150.00),
                CategoryLimit(category: .utilities, limit: 200.00),
                CategoryLimit(category: .other, limit: 150.00)
            ]
            
            let defaultBudget = Budget(
                month: month,
                year: year,
                limit: 1250.00, // Total of category limits
                categories: categoryLimits
            )
            
            appState.budgets.append(defaultBudget)
            print("Created default budget for \(month)/\(year) with limit \(defaultBudget.limit)")
        }
    }
    
    // MARK: - Debug/Reset Functions
    
    private func hasOldTestData() -> Bool {
        // Check for specific test data patterns that indicate old seeded data
        let hasTestTransactions = appState.transactions.contains { transaction in
            transaction.note.contains("Monthly salary") || 
            transaction.note.contains("Freelance design") ||
            transaction.note.contains("Supermarket weekly run")
        }
        
        let hasTestHabits = appState.habits.contains { habit in
            habit.title == "No sugar" || 
            habit.title == "10k steps" || 
            habit.title == "Focused work 25m"
        }
        
        let hasTestTasks = appState.tasks.contains { task in
            task.title == "Grocery restock" || 
            task.title == "Pay electricity bill" ||
            task.title == "Refill metro card"
        }
        
        return hasTestTransactions || hasTestHabits || hasTestTasks
    }
    
    func resetAllData() {
        // Delete existing file
        try? FileManager.default.removeItem(at: fileURL)
        
        // Reset onboarding flag to show onboarding again
        UserDefaults.standard.set(false, forKey: "onboardingCompleted")
        
        // Reset memory game data
        UserDefaults.standard.removeObject(forKey: "AurumFocusMemoryGameState")
        
        // Create fresh empty state
        createSeededData()
        
        print("All data has been reset to initial state")
    }
}
