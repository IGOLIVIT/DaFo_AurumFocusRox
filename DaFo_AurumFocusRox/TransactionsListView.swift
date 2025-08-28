//
//  TransactionsListView.swift
//  AurumFocus
//

import SwiftUI

struct TransactionsListView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expenses = "Expenses"
        case thisMonth = "This Month"
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        var transactions = dataManager.appState.transactions
        
        switch selectedFilter {
        case .all:
            break
        case .income:
            transactions = transactions.filter { $0.isIncome }
        case .expenses:
            transactions = transactions.filter { !$0.isIncome }
        case .thisMonth:
            transactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        abs(filteredTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AurumTheme.smallPadding) {
                            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, AurumTheme.padding)
                    }
                    .padding(.vertical, AurumTheme.smallPadding)
                    
                    // Summary Cards
                    if !filteredTransactions.isEmpty {
                        HStack(spacing: AurumTheme.padding) {
                            SummaryCard(
                                title: "Income",
                                amount: totalIncome,
                                color: AurumTheme.success,
                                icon: "arrow.up.circle"
                            )
                            
                            SummaryCard(
                                title: "Expenses",
                                amount: totalExpenses,
                                color: AurumTheme.danger,
                                icon: "arrow.down.circle"
                            )
                        }
                        .padding(.horizontal, AurumTheme.padding)
                        .padding(.bottom, AurumTheme.smallPadding)
                    }
                    
                    // Transactions List
                    if filteredTransactions.isEmpty {
                        Spacer()
                        
                        VStack(spacing: AurumTheme.padding) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 60))
                                .foregroundColor(AurumTheme.secondaryText)
                            
                            Text("No transactions found")
                                .font(.aurumHeadline)
                                .foregroundColor(AurumTheme.primaryText)
                            
                            Text("Transactions matching your filter will appear here")
                                .font(.aurumBody)
                                .foregroundColor(AurumTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    } else {
                        List {
                            ForEach(groupedTransactions, id: \.key) { group in
                                Section(header: SectionHeader(title: group.key)) {
                                    ForEach(group.value, id: \.id) { transaction in
                                        TransactionRow(transaction: transaction) {
                                            transactionToDelete = transaction
                                            showingDeleteAlert = true
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AurumTheme.goldAccent)
                }
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    deleteTransaction(transaction)
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
    }
    
    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            formatter.string(from: transaction.date)
        }
        
        return grouped.sorted { first, second in
            let firstDate = formatter.date(from: first.key) ?? Date.distantPast
            let secondDate = formatter.date(from: second.key) ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        dataManager.appState.transactions.removeAll { $0.id == transaction.id }
        dataManager.saveState()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.aurumCaption)
                .foregroundColor(isSelected ? AurumTheme.backgroundPrimary : AurumTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AurumTheme.goldAccent : AurumTheme.surfaceCard
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : AurumTheme.goldAccent.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: AurumTheme.smallPadding) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
                Spacer()
            }
            
            HStack {
                Text(amount.currencyString)
                    .font(.aurumHeadline.monospacedDigit())
                    .foregroundColor(AurumTheme.primaryText)
                Spacer()
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.aurumSubheadline)
            .foregroundColor(AurumTheme.goldAccent)
            .padding(.vertical, 4)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    private var categoryIcon: String {
        switch transaction.category {
        case .income:
            return "dollarsign.circle"
        case .groceries:
            return "cart"
        case .transport:
            return "car"
        case .entertainment:
            return "tv"
        case .health:
            return "heart"
        case .utilities:
            return "bolt"
        case .other:
            return "ellipsis.circle"
        }
    }
    
    private var categoryName: String {
        switch transaction.category {
        case .income:
            return "Income"
        case .groceries:
            return "Groceries"
        case .transport:
            return "Transport"
        case .entertainment:
            return "Entertainment"
        case .health:
            return "Health"
        case .utilities:
            return "Utilities"
        case .other:
            return "Other"
        }
    }
    
    var body: some View {
        HStack(spacing: AurumTheme.padding) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(transaction.isIncome ? AurumTheme.success : AurumTheme.goldAccent)
                .frame(width: 32, height: 32)
                .background(
                    (transaction.isIncome ? AurumTheme.success : AurumTheme.goldAccent)
                        .opacity(0.1)
                )
                .cornerRadius(8)
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(categoryName)
                        .font(.aurumBody)
                        .foregroundColor(AurumTheme.primaryText)
                    
                    Spacer()
                    
                    Text(abs(transaction.amount).currencyString)
                        .font(.aurumBody.monospacedDigit())
                        .foregroundColor(transaction.isIncome ? AurumTheme.success : AurumTheme.primaryText)
                }
                
                HStack {
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.aurumCaption)
                            .foregroundColor(AurumTheme.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(transaction.date, style: .date)
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
            }
        }
        .padding(AurumTheme.padding)
        .background(AurumTheme.surfaceCard)
        .cornerRadius(AurumTheme.smallRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                .stroke(AurumTheme.goldAccent.opacity(0.1), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    TransactionsListView(dataManager: DataManager())
}
