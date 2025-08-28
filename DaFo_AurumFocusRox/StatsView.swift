//
//  StatsView.swift
//  AurumFocus
//

import SwiftUI

struct MemoryStatsView: View {
    let stats: MemoryGameStats
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AurumTheme.padding) {
                        // Game Stats
                        gameStatsSection
                        
                        // Performance Stats
                        performanceStatsSection
                        
                        // Difficulty Breakdown
                        difficultyBreakdownSection
                    }
                    .padding(AurumTheme.padding)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AurumTheme.goldAccent)
                }
            }
        }
    }
    
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            Text("Game Overview")
                .font(.aurumHeadline)
                .foregroundColor(AurumTheme.primaryText)
            
            VStack(spacing: AurumTheme.smallPadding) {
                StatRowView(
                    title: "Games Played",
                    value: "\(stats.gamesPlayed)",
                    icon: "gamecontroller.fill",
                    color: AurumTheme.goldAccent
                )
                
                StatRowView(
                    title: "Games Won",
                    value: "\(stats.gamesWon)",
                    icon: "trophy.fill",
                    color: AurumTheme.success
                )
                
                StatRowView(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", stats.winRate),
                    icon: "percent",
                    color: stats.winRate >= 50 ? AurumTheme.success : AurumTheme.danger
                )
                
                StatRowView(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    icon: "flame.fill",
                    color: stats.currentStreak > 0 ? AurumTheme.success : AurumTheme.secondaryText
                )
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var difficultyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            Text("Difficulty Breakdown")
                .font(.aurumHeadline)
                .foregroundColor(AurumTheme.primaryText)
            
            VStack(spacing: AurumTheme.smallPadding) {
                StatRowView(
                    title: "Easy Games Won",
                    value: "\(stats.easyGamesWon)",
                    icon: "1.circle.fill",
                    color: AurumTheme.success
                )
                
                StatRowView(
                    title: "Medium Games Won",
                    value: "\(stats.mediumGamesWon)",
                    icon: "2.circle.fill",
                    color: AurumTheme.warning
                )
                
                StatRowView(
                    title: "Hard Games Won",
                    value: "\(stats.hardGamesWon)",
                    icon: "3.circle.fill",
                    color: AurumTheme.danger
                )
                
                StatRowView(
                    title: "Longest Streak",
                    value: "\(stats.longestStreak)",
                    icon: "star.fill",
                    color: AurumTheme.goldAccent
                )
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var performanceStatsSection: some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            Text("Performance Records")
                .font(.aurumHeadline)
                .foregroundColor(AurumTheme.primaryText)
            
            VStack(spacing: AurumTheme.smallPadding) {
                StatRowView(
                    title: "Best Time",
                    value: stats.bestTime > 0 ? "\(Int(stats.bestTime))s" : "N/A",
                    icon: "stopwatch.fill",
                    color: AurumTheme.success
                )
                
                StatRowView(
                    title: "Best Moves",
                    value: stats.bestMoves > 0 ? "\(stats.bestMoves)" : "N/A",
                    icon: "target",
                    color: AurumTheme.success
                )
                
                StatRowView(
                    title: "Average Moves",
                    value: stats.averageMoves > 0 ? String(format: "%.1f", stats.averageMoves) : "N/A",
                    icon: "chart.bar.fill",
                    color: AurumTheme.goldAccent
                )
                
                StatRowView(
                    title: "Total Moves",
                    value: "\(stats.totalMoves)",
                    icon: "hand.tap.fill",
                    color: AurumTheme.goldAccent
                )
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    

}

struct StatRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.aurumBody)
                .foregroundColor(AurumTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.aurumBody.monospacedDigit())
                .foregroundColor(AurumTheme.primaryText)
        }
        .padding(.vertical, 4)
    }
}



#Preview {
    MemoryStatsView(stats: MemoryGameStats())
}
