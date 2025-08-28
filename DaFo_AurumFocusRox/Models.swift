//
//  Models.swift
//  AurumFocus
//

import Foundation

// MARK: - Enums

enum Category: String, CaseIterable, Codable {
    case income
    case groceries
    case transport
    case entertainment
    case health
    case utilities
    case other
    
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .groceries: return "Groceries"
        case .transport: return "Transport"
        case .entertainment: return "Entertainment"
        case .health: return "Health"
        case .utilities: return "Utilities"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .income: return "plus.circle"
        case .groceries: return "cart"
        case .transport: return "car"
        case .entertainment: return "tv"
        case .health: return "heart"
        case .utilities: return "bolt"
        case .other: return "questionmark.circle"
        }
    }
}

enum Priority: String, CaseIterable, Codable {
    case low
    case normal
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "secondary"
        case .normal: return "primary"
        case .high: return "danger"
        }
    }
}

// MARK: - Data Models

struct Transaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let category: Category
    let note: String
    
    init(date: Date, amount: Double, category: Category, note: String) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.category = category
        self.note = note
    }
    
    var isIncome: Bool {
        amount > 0
    }
}

struct CategoryLimit: Identifiable, Codable {
    let id: UUID
    let category: Category
    let limit: Double
    
    init(category: Category, limit: Double) {
        self.id = UUID()
        self.category = category
        self.limit = limit
    }
}

struct Budget: Identifiable, Codable {
    let id: UUID
    let month: Int
    let year: Int
    let limit: Double
    let categories: [CategoryLimit]
    
    init(month: Int, year: Int, limit: Double, categories: [CategoryLimit]) {
        self.id = UUID()
        self.month = month
        self.year = year
        self.limit = limit
        self.categories = categories
    }
}

struct HabitLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    
    init(date: Date) {
        self.id = UUID()
        self.date = date
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    let title: String
    let targetPerWeek: Int
    var logs: [HabitLog]
    
    init(title: String, targetPerWeek: Int, logs: [HabitLog] = []) {
        self.id = UUID()
        self.title = title
        self.targetPerWeek = targetPerWeek
        self.logs = logs
    }
    
    func logsForWeek(_ date: Date) -> [HabitLog] {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        guard let start = weekInterval?.start, let end = weekInterval?.end else { return [] }
        
        return logs.filter { log in
            log.date >= start && log.date < end
        }
    }
    
    func hasLogForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return logs.contains { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }
    }
    
    mutating func toggleLogForDate(_ date: Date) {
        let calendar = Calendar.current
        if let existingIndex = logs.firstIndex(where: { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }) {
            logs.remove(at: existingIndex)
        } else {
            logs.append(HabitLog(date: date))
        }
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var due: Date?
    var priority: Priority
    var isDone: Bool
    
    init(title: String, due: Date? = nil, priority: Priority, isDone: Bool) {
        self.id = UUID()
        self.title = title
        self.due = due
        self.priority = priority
        self.isDone = isDone
    }
}

// MARK: - App State

struct AppState: Codable {
    var transactions: [Transaction]
    var budgets: [Budget]
    var habits: [Habit]
    var tasks: [TaskItem]
    var onboardingCompleted: Bool
    
    init() {
        self.transactions = []
        self.budgets = []
        self.habits = []
        self.tasks = []
        self.onboardingCompleted = false
    }
}
