//
//  BudgetSetupView.swift
//  AurumFocus
//

import SwiftUI

struct BudgetSetupView: View {
    @ObservedObject var dataManagers: DataManagers
    @Environment(\.dismiss) private var dismiss
    
    @State private var totalLimit: String = ""
    @State private var groceriesLimit: String = ""
    @State private var transportLimit: String = ""
    @State private var entertainmentLimit: String = ""
    @State private var healthLimit: String = ""
    @State private var utilitiesLimit: String = ""
    @State private var otherLimit: String = ""
    
    @State private var showingSuccessMessage = false
    
    private var currentBudget: Budget? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        return dataManagers.appState.budgets.first { budget in
            budget.month == month && budget.year == year
        }
    }
    
    private var isValidInput: Bool {
        guard let total = Double(totalLimit), total > 0 else {
            return false
        }
        
        guard let groceries = Double(groceriesLimit), groceries >= 0,
              let transport = Double(transportLimit), transport >= 0,
              let entertainment = Double(entertainmentLimit), entertainment >= 0 else {
            return false
        }
        
        guard let health = Double(healthLimit), health >= 0,
              let utilities = Double(utilitiesLimit), utilities >= 0,
              let other = Double(otherLimit), other >= 0 else {
            return false
        }
        
        let categoryTotal = groceries + transport + entertainment + health + utilities + other
        return categoryTotal <= total
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AurumTheme.padding) {
                        // Header
                        VStack(spacing: AurumTheme.smallPadding) {
                            Text("Monthly Budget")
                                .font(.aurumTitle)
                                .foregroundColor(AurumTheme.primaryText)
                            
                            Text("Set your spending limits for this month")
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AurumTheme.padding)
                        
                        // Total Budget
                        VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                            Text("Total Monthly Budget")
                                .font(.aurumHeadline)
                                .foregroundColor(AurumTheme.primaryText)
                            
                            TextField("Enter total budget", text: $totalLimit)
                                .keyboardType(.decimalPad)
                                .font(.aurumBody.monospacedDigit())
                                .foregroundColor(AurumTheme.primaryText)
                                .padding(AurumTheme.padding)
                                .background(AurumTheme.inputBackground)
                                .cornerRadius(AurumTheme.smallRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                                        .stroke(AurumTheme.goldAccent.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(AurumTheme.padding)
                        .cardStyle()
                        
                        // Category Limits
                        VStack(alignment: .leading, spacing: AurumTheme.padding) {
                            Text("Category Limits")
                                .font(.aurumHeadline)
                                .foregroundColor(AurumTheme.primaryText)
                            
                            VStack(spacing: AurumTheme.padding) {
                                CategoryLimitRow(title: "Groceries", amount: $groceriesLimit, icon: "cart")
                                CategoryLimitRow(title: "Transport", amount: $transportLimit, icon: "car")
                                CategoryLimitRow(title: "Entertainment", amount: $entertainmentLimit, icon: "tv")
                                CategoryLimitRow(title: "Health", amount: $healthLimit, icon: "heart")
                                CategoryLimitRow(title: "Utilities", amount: $utilitiesLimit, icon: "bolt")
                                CategoryLimitRow(title: "Other", amount: $otherLimit, icon: "ellipsis.circle")
                            }
                        }
                        .padding(AurumTheme.padding)
                        .cardStyle()
                        
                        // Validation Info
                        if !totalLimit.isEmpty && !isValidInput {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AurumTheme.warning)
                                
                                Text("Category limits cannot exceed total budget")
                                    .font(.aurumCaption)
                                    .foregroundColor(AurumTheme.warning)
                            }
                            .padding(AurumTheme.padding)
                            .background(AurumTheme.warning.opacity(0.1))
                            .cornerRadius(AurumTheme.smallRadius)
                        }
                        
                        // Save Button
                        Button(action: saveBudget) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Save Budget")
                            }
                            .font(.aurumBody)
                            .foregroundColor(AurumTheme.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(AurumTheme.padding)
                            .background(
                                LinearGradient(
                                    colors: [AurumTheme.goldAccent, AurumTheme.secondaryGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(AurumTheme.buttonRadius)
                            .shadow(color: AurumTheme.cardShadow, radius: 4, x: 0, y: 2)
                        }
                        .disabled(!isValidInput)
                        .opacity(isValidInput ? 1.0 : 0.6)
                        .padding(.horizontal, AurumTheme.padding)
                        .padding(.bottom, AurumTheme.padding)
                    }
                }
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AurumTheme.success)
                            Text("Budget saved successfully")
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
            .navigationTitle("Budget Setup")
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
        .onAppear {
            loadCurrentBudget()
        }
    }
    
    private func loadCurrentBudget() {
        if let budget = currentBudget {
            totalLimit = String(format: "%.0f", budget.limit)
            
            for categoryLimit in budget.categories {
                switch categoryLimit.category {
                case .groceries:
                    groceriesLimit = String(format: "%.0f", categoryLimit.limit)
                case .transport:
                    transportLimit = String(format: "%.0f", categoryLimit.limit)
                case .entertainment:
                    entertainmentLimit = String(format: "%.0f", categoryLimit.limit)
                case .health:
                    healthLimit = String(format: "%.0f", categoryLimit.limit)
                case .utilities:
                    utilitiesLimit = String(format: "%.0f", categoryLimit.limit)
                case .other:
                    otherLimit = String(format: "%.0f", categoryLimit.limit)
                case .income:
                    break // Skip income category
                }
            }
        } else {
            // Set default values
            totalLimit = "1250"
            groceriesLimit = "400"
            transportLimit = "150"
            entertainmentLimit = "200"
            healthLimit = "150"
            utilitiesLimit = "200"
            otherLimit = "150"
        }
    }
    
    private func saveBudget() {
        guard let total = Double(totalLimit),
              let groceries = Double(groceriesLimit),
              let transport = Double(transportLimit),
              let entertainment = Double(entertainmentLimit),
              let health = Double(healthLimit),
              let utilities = Double(utilitiesLimit),
              let other = Double(otherLimit) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        let categoryLimits = [
            CategoryLimit(category: .groceries, limit: groceries),
            CategoryLimit(category: .transport, limit: transport),
            CategoryLimit(category: .entertainment, limit: entertainment),
            CategoryLimit(category: .health, limit: health),
            CategoryLimit(category: .utilities, limit: utilities),
            CategoryLimit(category: .other, limit: other)
        ]
        
        let budget = Budget(
            month: month,
            year: year,
            limit: total,
            categories: categoryLimits
        )
        
        dataManagers.addBudget(budget)
        
        // Show success message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingSuccessMessage = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

struct CategoryLimitRow: View {
    let title: String
    @Binding var amount: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AurumTheme.goldAccent)
                .frame(width: 24)
            
            Text(title)
                .font(.aurumBody)
                .foregroundColor(AurumTheme.primaryText)
            
            Spacer()
            
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .font(.aurumBody.monospacedDigit())
                .foregroundColor(AurumTheme.primaryText)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(AurumTheme.inputBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AurumTheme.goldAccent.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    BudgetSetupView(dataManagers: DataManagers())
}
