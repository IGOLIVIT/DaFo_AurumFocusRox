//
//  AchievementsView.swift
//  AurumFocus
//

import SwiftUI

struct MemoryAchievementsView: View {
    let achievements: [MemoryGameAchievement]
    @Environment(\.dismiss) private var dismiss
    
    private var unlockedAchievements: [MemoryGameAchievement] {
        achievements.filter { $0.isUnlocked }.sorted { 
            ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast)
        }
    }
    
    private var lockedAchievements: [MemoryGameAchievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AurumTheme.padding) {
                        // Progress Summary
                        progressSummarySection
                        
                        // Unlocked Achievements
                        if !unlockedAchievements.isEmpty {
                            achievementSection(
                                title: "Unlocked",
                                achievements: unlockedAchievements,
                                isUnlocked: true
                            )
                        }
                        
                        // Locked Achievements
                        if !lockedAchievements.isEmpty {
                            achievementSection(
                                title: "Locked",
                                achievements: lockedAchievements,
                                isUnlocked: false
                            )
                        }
                    }
                    .padding(AurumTheme.padding)
                }
            }
            .navigationTitle("Achievements")
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
    
    private var progressSummarySection: some View {
        VStack(spacing: AurumTheme.padding) {
            HStack {
                Text("Progress")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                Spacer()
            }
            
            VStack(spacing: AurumTheme.smallPadding) {
                HStack {
                    Text("Achievements Unlocked")
                        .font(.aurumBody)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Spacer()
                    
                    Text("\(unlockedAchievements.count) / \(achievements.count)")
                        .font(.aurumBody.monospacedDigit())
                        .foregroundColor(AurumTheme.goldAccent)
                }
                
                // Progress Bar
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
                            .frame(
                                width: geometry.size.width * (Double(unlockedAchievements.count) / Double(achievements.count)),
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int((Double(unlockedAchievements.count) / Double(achievements.count)) * 100))% Complete")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                    
                    Spacer()
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private func achievementSection(title: String, achievements: [MemoryGameAchievement], isUnlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: AurumTheme.padding) {
            HStack {
                Text(title)
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                
                Spacer()
                
                Text("\(achievements.count)")
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
            }
            
            LazyVStack(spacing: AurumTheme.smallPadding) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementRowView(achievement: achievement, isUnlocked: isUnlocked)
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
}

struct AchievementRowView: View {
    let achievement: MemoryGameAchievement
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: AurumTheme.padding) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? AurumTheme.goldAccent.opacity(0.2) : AurumTheme.dividers)
                    .frame(width: 48, height: 48)
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? AurumTheme.goldAccent : AurumTheme.secondaryText)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.aurumBody)
                    .foregroundColor(isUnlocked ? AurumTheme.primaryText : AurumTheme.secondaryText)
                
                Text(achievement.description)
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.secondaryText)
                    .lineLimit(2)
                
                if isUnlocked, let date = achievement.unlockedDate {
                    Text("Unlocked \(date, style: .date)")
                        .font(.system(size: 11))
                        .foregroundColor(AurumTheme.goldAccent)
                }
            }
            
            Spacer()
            
            // Status
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(AurumTheme.success)
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.title3)
                    .foregroundColor(AurumTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    MemoryAchievementsView(achievements: MemoryGameState.createAchievements())
}
