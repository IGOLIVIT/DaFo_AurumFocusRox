//
//  DashboardView.swift
//  AurumFocus
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var dataManager: DataManager
    @Binding var selectedTab: Int
    @State private var showingAddTransaction = false
    @State private var showingBudgetSetup = false
    @State private var showingTransactionsList = false
    @State private var showingResetAlert = false
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return dataManager.appState.transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }
    }
    
    private var currentMonthNet: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var currentMonthIncome: Double {
        currentMonthTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    private var currentMonthExpenses: Double {
        abs(currentMonthTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount })
    }
    
    private var currentBudget: Budget? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        return dataManager.appState.budgets.first { budget in
            budget.month == month && budget.year == year
        }
    }
    
    private var budgetProgress: Double {
        guard let budget = currentBudget else { return 0 }
        let spent = currentMonthExpenses
        return spent / budget.limit
    }
    
    private var budgetRemainingPercentage: Double {
        guard let budget = currentBudget else { return 0 }
        let remaining = budget.limit - currentMonthExpenses
        return remaining / budget.limit
    }
    
    private var budgetColor: Color {
        let remaining = budgetRemainingPercentage
        if remaining > 0.4 {
            return AurumTheme.success
        } else if remaining > 0.15 {
            return AurumTheme.warning
        } else {
            return AurumTheme.danger
        }
    }
    
    private var todaysTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        return dataManager.appState.tasks
            .filter { !$0.isDone }
            .filter { task in
                guard let due = task.due else { return false }
                return calendar.isDate(due, inSameDayAs: today) || due < today
            }
            .sorted { task1, task2 in
                if let due1 = task1.due, let due2 = task2.due {
                    return due1 < due2
                } else if task1.due != nil {
                    return true
                } else {
                    return false
                }
            }
            .prefix(3)
            .map { $0 }
    }
    
    private var weeklyHabitsProgress: Double {
        let today = Date()
        
        let totalTargets = dataManager.appState.habits.reduce(0) { $0 + $1.targetPerWeek }
        guard totalTargets > 0 else { return 0 }
        
        let totalCompleted = dataManager.appState.habits.reduce(0) { sum, habit in
            let weekLogs = habit.logsForWeek(today)
            return sum + min(weekLogs.count, habit.targetPerWeek)
        }
        
        return Double(totalCompleted) / Double(totalTargets)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AurumTheme.padding) {
                        // Header
                        headerSection
                        
                        // Financial overview
                        financialOverviewSection
                        
                        // Budget progress
                        budgetProgressSection
                        
                        // Today's plan
                        todaysPlanSection
                        
                        // Habits progress
                        habitsProgressSection
                        
                        // Analytics charts
                        analyticsSection
                    }
                    .padding(.horizontal, AurumTheme.padding)
                    .padding(.bottom, 100) // Space for floating button
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddTransaction = true }) {
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
                        .accessibleButton(AccessibilityLabels.addTransaction, hint: AccessibilityHints.addTransaction)
                        .accessibilityIdentifier(AccessibilityIdentifiers.addTransactionButton)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "trash.circle")
                            .foregroundColor(AurumTheme.danger)
                    }
                    .accessibilityLabel("Reset all data")
                    .accessibilityHint("Resets all app data to initial state")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingBudgetSetup) {
            BudgetSetupView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingTransactionsList) {
            TransactionsListView(dataManager: dataManager)
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                dataManager.resetAllData()
            }
        } message: {
            Text("This will permanently delete all your transactions, budgets, tasks, habits, and game progress. The app will return to its initial state and show the onboarding screen again.\n\nThis action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
            Text("Current Month")
                .font(.aurumCaption)
                .foregroundColor(AurumTheme.secondaryText)
            
            Text(currentMonthNet.currencyString)
                .font(.aurumLargeMoney)
                .foregroundColor(currentMonthNet >= 0 ? AurumTheme.positiveChart : AurumTheme.negativeChart)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AurumTheme.padding)
        .cardStyle()
        .accessibilityLabel(AccessibilityLabels.netIncomeCard)
        .accessibleCurrency(currentMonthNet)
        .accessibilityHint("Your net income for the current month")
    }
    
    private var financialOverviewSection: some View {
        VStack(spacing: AurumTheme.smallPadding) {
            HStack {
                Text("This Month")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                Spacer()
                
                Button(action: {
                    showingTransactionsList = true
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.aurumCaption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(AurumTheme.goldAccent)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: AurumTheme.padding) {
            // Income card
            VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(AurumTheme.positiveChart)
                    Text("Income")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                
                Text(currentMonthIncome.currencyString)
                    .font(.aurumMoney)
                    .foregroundColor(AurumTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AurumTheme.padding)
            .cardStyle()
            .accessibilityLabel(AccessibilityLabels.incomeCard)
            .accessibleCurrency(currentMonthIncome)
            .accessibilityHint("Total income received this month")
            
            // Expenses card
            VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(AurumTheme.negativeChart)
                    Text("Expenses")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                
                Text(currentMonthExpenses.currencyString)
                    .font(.aurumMoney)
                    .foregroundColor(AurumTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AurumTheme.padding)
            .cardStyle()
            .accessibilityLabel(AccessibilityLabels.expenseCard)
            .accessibleCurrency(currentMonthExpenses)
            .accessibilityHint("Total expenses spent this month")
            }
        }
    }
    
    private var budgetProgressSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            HStack {
                Text("Budget Progress")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                Spacer()
                
                Button(action: {
                    showingBudgetSetup = true
                }) {
                    Image(systemName: currentBudget == nil ? "plus.circle" : "pencil.circle")
                        .font(.title3)
                        .foregroundColor(AurumTheme.goldAccent)
                }
                .buttonStyle(PlainButtonStyle())
                
                if currentBudget != nil {
                    Text("\(Int(budgetRemainingPercentage * 100))% left")
                        .font(.aurumCaption)
                        .foregroundColor(budgetColor)
                }
            }
            
            if let budget = currentBudget {
                BudgetRingView(
                    progress: budgetProgress,
                    spent: currentMonthExpenses,
                    total: budget.limit,
                    color: budgetColor
                )
                .frame(height: 120)
                .accessibilityLabel(AccessibilityLabels.budgetProgress)
                .accessibilityValue("Spent \(currentMonthExpenses.currencyString) of \(budget.limit.currencyString) budget")
                .accessibilityHint(AccessibilityHints.budgetProgress)
                .accessibilityIdentifier(AccessibilityIdentifiers.budgetProgressRing)
            } else {
                VStack(spacing: AurumTheme.padding) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Text("No budget set")
                        .font(.aurumBody)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Text("Add transactions to start tracking your spending")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var todaysPlanSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            Text("Today's Plan")
                .font(.aurumHeadline)
                .foregroundColor(AurumTheme.primaryText)
            
            if todaysTasks.isEmpty {
                Text("No tasks for today")
                    .font(.aurumBody)
                    .foregroundColor(AurumTheme.secondaryText)
            } else {
                VStack(spacing: AurumTheme.smallPadding) {
                    ForEach(todaysTasks, id: \.id) { task in
                        TaskRowView(task: task, dataManager: dataManager)
                    }
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var habitsProgressSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                Text("Habits this week")
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
                
                if dataManager.appState.habits.isEmpty {
                    Text("No habits yet")
                        .font(.aurumSubheadline)
                        .foregroundColor(AurumTheme.secondaryText)
                } else {
                    Text("\(Int(weeklyHabitsProgress * 100))% of target met")
                        .font(.aurumSubheadline)
                        .foregroundColor(AurumTheme.primaryText)
                }
            }
            
            Spacer()
            
            if dataManager.appState.habits.isEmpty {
                Button(action: {
                    // Navigate to Habits tab
                    selectedTab = 2
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(AurumTheme.goldAccent)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                CircularProgressView(progress: weeklyHabitsProgress, color: AurumTheme.goldAccent)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var analyticsSection: some View {
        VStack(spacing: AurumTheme.padding) {
            // Income vs Expense chart
            VStack(alignment: .leading, spacing: AurumTheme.padding) {
                Text("30-Day Income vs Expenses")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                IncomeExpenseChartView(transactions: dataManager.appState.transactions)
                    .frame(height: 200)
            }
            .padding(AurumTheme.padding)
            .cardStyle()
            
            // Category expenses chart
            VStack(alignment: .leading, spacing: AurumTheme.padding) {
                Text("Category Expenses (This Month)")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                CategoryExpenseChartView(transactions: currentMonthTransactions)
                    .frame(height: 200)
            }
            .padding(AurumTheme.padding)
            .cardStyle()
        }
    }
}

#Preview {
    DashboardView(dataManager: DataManager(), selectedTab: .constant(0))
}
