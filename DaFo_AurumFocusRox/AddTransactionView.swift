//
//  AddTransactionView.swift
//  AurumFocus
//

import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var isIncome: Bool = false
    @State private var selectedCategory: Category = .other
    @State private var note: String = ""
    @State private var showingSuccessMessage = false
    
    private var isValidAmount: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }
    
    private var canSave: Bool {
        isValidAmount && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var availableCategories: [Category] {
        if isIncome {
            return [.income]
        } else {
            return Category.allCases.filter { $0 != .income }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: AurumTheme.largePadding) {
                    // Amount input
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Amount")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        HStack {
                            Text(Locale.current.currencySymbol ?? "$")
                                .font(.aurumLargeMoney)
                                .foregroundColor(AurumTheme.goldAccent)
                            
                            TextField("0.00", text: $amount)
                                .font(.aurumLargeMoney)
                                .foregroundColor(AurumTheme.primaryText)
                                .keyboardType(.decimalPad)
                        }
                        .padding(AurumTheme.padding)
                        .background(AurumTheme.inputField)
                        .cornerRadius(AurumTheme.smallRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                                .stroke(isValidAmount ? AurumTheme.goldAccent.opacity(0.3) : AurumTheme.dividers, lineWidth: 1)
                        )
                    }
                    
                    // Income/Expense toggle
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Type")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        Picker("Type", selection: $isIncome) {
                            Text("Expense").tag(false)
                            Text("Income").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                        .onChange(of: isIncome) { newValue in
                            if newValue {
                                selectedCategory = .income
                            } else {
                                selectedCategory = .other
                            }
                        }
                    }
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Category")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AurumTheme.smallPadding) {
                                ForEach(availableCategories, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal, AurumTheme.padding)
                        }
                    }
                    
                    // Note input
                    VStack(alignment: .leading, spacing: AurumTheme.smallPadding) {
                        Text("Note")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.primaryText)
                        
                        TextField("Enter description...", text: $note)
                            .font(.aurumBody)
                            .foregroundColor(AurumTheme.primaryText)
                            .lineLimit(3)
                            .padding(AurumTheme.padding)
                            .background(AurumTheme.inputField)
                            .cornerRadius(AurumTheme.smallRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                                    .stroke(AurumTheme.dividers, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button("Save Transaction") {
                        saveTransaction()
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
                            Text("Transaction saved")
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
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let finalAmount = isIncome ? amountValue : -amountValue
        let transaction = Transaction(
            date: Date(),
            amount: finalAmount,
            category: selectedCategory,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        dataManager.addTransaction(transaction)
        
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

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AurumTheme.smallPadding) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.aurumCaption)
            }
            .padding(.horizontal, AurumTheme.padding)
            .padding(.vertical, AurumTheme.smallPadding)
            .background(isSelected ? AurumTheme.goldAccent : AurumTheme.secondaryButton)
            .foregroundColor(isSelected ? AurumTheme.backgroundPrimary : AurumTheme.primaryText)
            .cornerRadius(AurumTheme.buttonRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: AurumTheme.smallPadding) {
            Button(action: {
                var updatedTask = task
                updatedTask.isDone = true
                dataManager.updateTask(updatedTask)
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: "circle")
                    .foregroundColor(AurumTheme.goldAccent)
            }
            .accessibleButton(AccessibilityLabels.completeTask, hint: AccessibilityHints.completeTask)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.aurumBody)
                    .foregroundColor(AurumTheme.primaryText)
                    .lineLimit(1)
                
                if let due = task.due {
                    Text(due, style: .date)
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
            }
            
            Spacer()
            
            // Priority indicator
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, AurumTheme.smallPadding)
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
    AddTransactionView(dataManager: DataManager())
}
