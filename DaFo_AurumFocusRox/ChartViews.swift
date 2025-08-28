//
//  ChartViews.swift
//  AurumFocus
//

import SwiftUI

// MARK: - Budget Ring View

struct BudgetRingView: View {
    let progress: Double
    let spent: Double
    let total: Double
    let color: Color
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(AurumTheme.dividers, lineWidth: 8)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: animatedProgress)
            
            // Center content
            VStack(spacing: 4) {
                Text(spent.currencyString)
                    .font(.aurumMoney)
                    .foregroundColor(AurumTheme.primaryText)
                
                Text("of \(total.currencyString)")
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
            }
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AurumTheme.dividers, lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Income vs Expense Chart

struct IncomeExpenseChartView: View {
    let transactions: [Transaction]
    
    @State private var animationProgress: Double = 0
    
    private var chartData: [(Date, Double, Double)] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -29, to: endDate)!
        
        var dailyData: [Date: (income: Double, expense: Double)] = [:]
        
        // Initialize all days with zero values
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dailyData[calendar.startOfDay(for: date)] = (0, 0)
            }
        }
        
        // Populate with actual transaction data
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            if day >= startDate && day <= endDate {
                var current = dailyData[day] ?? (0, 0)
                if transaction.isIncome {
                    current.income += transaction.amount
                } else {
                    current.expense += abs(transaction.amount)
                }
                dailyData[day] = current
            }
        }
        
        return dailyData.sorted { $0.key < $1.key }.map { (key, value) in
            (key, value.income, value.expense)
        }
    }
    
    private var maxValue: Double {
        let maxIncome = chartData.map { $0.1 }.max() ?? 0
        let maxExpense = chartData.map { $0.2 }.max() ?? 0
        return max(maxIncome, maxExpense)
    }
    
    var body: some View {
        VStack {
            if chartData.isEmpty || maxValue == 0 {
                VStack(spacing: AurumTheme.smallPadding) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Text("No data available")
                        .font(.aurumBody)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(chartData.count - 1)
                    
                    ZStack {
                        // Grid lines
                        ForEach(0..<5) { i in
                            let y = height * CGFloat(i) / 4
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: width, y: y))
                            }
                            .stroke(AurumTheme.dividers.opacity(0.3), lineWidth: 1)
                        }
                        
                        // Income line
                        Path { path in
                            for (index, data) in chartData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(data.1) / CGFloat(maxValue)) * height
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .trim(from: 0, to: animationProgress)
                        .stroke(AurumTheme.positiveChart, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        
                        // Expense line
                        Path { path in
                            for (index, data) in chartData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(data.2) / CGFloat(maxValue)) * height
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .trim(from: 0, to: animationProgress)
                        .stroke(AurumTheme.negativeChart, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
                
                // Legend
                HStack(spacing: AurumTheme.padding) {
                    HStack(spacing: AurumTheme.smallPadding) {
                        Circle()
                            .fill(AurumTheme.positiveChart)
                            .frame(width: 8, height: 8)
                        Text("Income")
                            .font(.aurumCaption)
                            .foregroundColor(AurumTheme.secondaryText)
                    }
                    
                    HStack(spacing: AurumTheme.smallPadding) {
                        Circle()
                            .fill(AurumTheme.negativeChart)
                            .frame(width: 8, height: 8)
                        Text("Expenses")
                            .font(.aurumCaption)
                            .foregroundColor(AurumTheme.secondaryText)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Category Expense Chart

struct CategoryExpenseChartView: View {
    let transactions: [Transaction]
    
    @State private var animationProgress: Double = 0
    
    private var categoryData: [(Category, Double)] {
        var categoryTotals: [Category: Double] = [:]
        
        for transaction in transactions {
            if !transaction.isIncome {
                let amount = abs(transaction.amount)
                categoryTotals[transaction.category, default: 0] += amount
            }
        }
        
        return categoryTotals.sorted { $0.value > $1.value }
    }
    
    private var maxValue: Double {
        categoryData.map { $0.1 }.max() ?? 0
    }
    
    var body: some View {
        VStack {
            if categoryData.isEmpty || maxValue == 0 {
                VStack(spacing: AurumTheme.smallPadding) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Text("No expenses this month")
                        .font(.aurumBody)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: AurumTheme.smallPadding) {
                    ForEach(Array(categoryData.enumerated()), id: \.offset) { index, data in
                        HStack {
                            // Category info
                            HStack(spacing: AurumTheme.smallPadding) {
                                Image(systemName: data.0.icon)
                                    .foregroundColor(AurumTheme.goldAccent)
                                    .frame(width: 20)
                                
                                Text(data.0.displayName)
                                    .font(.aurumCaption)
                                    .foregroundColor(AurumTheme.primaryText)
                                
                                Spacer()
                                
                                Text(data.1.currencyString)
                                    .font(.aurumCaption.monospacedDigit())
                                    .foregroundColor(AurumTheme.secondaryText)
                            }
                            .frame(width: 120, alignment: .leading)
                            
                            // Bar
                            GeometryReader { geometry in
                                HStack {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [AurumTheme.goldAccent, AurumTheme.secondaryGold],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(data.1 / maxValue) * animationProgress)
                                        .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animationProgress)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .onAppear {
            animationProgress = 1.0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BudgetRingView(progress: 0.65, spent: 780, total: 1200, color: AurumTheme.warning)
            .frame(height: 120)
        
        IncomeExpenseChartView(transactions: [])
            .frame(height: 200)
        
        CategoryExpenseChartView(transactions: [])
            .frame(height: 200)
    }
    .padding()
    .background(AurumTheme.backgroundPrimary)
}
