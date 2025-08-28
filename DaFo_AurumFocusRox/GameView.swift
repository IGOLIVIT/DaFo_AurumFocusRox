//
//  GameView.swift
//  AurumFocus
//

import SwiftUI

struct GameView: View {
    @StateObject private var gameManager = MemoryGameManager()
    @State private var showingAchievements = false
    @State private var showingStats = false
    @State private var showingGameComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AurumTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AurumTheme.padding) {
                        // Game Header
                        gameHeaderSection
                        
                        // Game Controls
                        gameControlsSection
                        
                        // Memory Cards Grid
                        memoryCardsSection
                        
                        // Quick Stats
                        quickStatsSection
                    }
                    .padding(AurumTheme.padding)
                }
            }
            .navigationTitle("Memory Game")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingStats = true }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(AurumTheme.goldAccent)
                        }
                        
                        Button(action: { showingAchievements = true }) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(AurumTheme.goldAccent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAchievements) {
            MemoryAchievementsView(achievements: gameManager.gameState.achievements)
        }
        .sheet(isPresented: $showingStats) {
            MemoryStatsView(stats: gameManager.gameState.stats)
        }
        .alert("Congratulations!", isPresented: $showingGameComplete) {
            Button("New Game") {
                gameManager.startNewGame(difficulty: gameManager.gameState.difficulty)
            }
            Button("OK") { }
        } message: {
            Text("You completed the game in \(gameManager.gameState.moves) moves and \(Int(gameManager.gameState.gameTime)) seconds!")
        }
        .onChange(of: gameManager.gameState.isGameComplete) { isComplete in
            if isComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingGameComplete = true
                }
            }
        }
    }
    
    private var gameHeaderSection: some View {
        VStack(spacing: AurumTheme.padding) {
            HStack {
                Text("Currency Memory")
                    .font(.aurumHeadline)
                    .foregroundColor(AurumTheme.primaryText)
                Spacer()
                Text(gameManager.gameState.difficulty.rawValue)
                    .font(.aurumCaption)
                    .foregroundColor(AurumTheme.goldAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AurumTheme.goldAccent.opacity(0.1))
                    .cornerRadius(12)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Moves")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                    Text("\(gameManager.gameState.moves)")
                        .font(.aurumTitle.monospacedDigit())
                        .foregroundColor(AurumTheme.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Matches")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                    Text("\(gameManager.gameState.matches)/\(gameManager.gameState.difficulty.pairCount)")
                        .font(.aurumTitle.monospacedDigit())
                        .foregroundColor(AurumTheme.goldAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Time")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                    Text("\(Int(gameManager.gameState.gameTime))s")
                        .font(.aurumTitle.monospacedDigit())
                        .foregroundColor(AurumTheme.primaryText)
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var gameControlsSection: some View {
        HStack(spacing: AurumTheme.padding) {
            // Difficulty Selector
            Menu {
                ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                    Button(difficulty.rawValue) {
                        gameManager.startNewGame(difficulty: difficulty)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Difficulty")
                }
                .font(.aurumBody)
                .foregroundColor(AurumTheme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(AurumTheme.smallPadding)
                .background(AurumTheme.surfaceCard)
                .cornerRadius(AurumTheme.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                        .stroke(AurumTheme.goldAccent.opacity(0.3), lineWidth: 1)
                )
            }
            
            // New Game Button
            Button(action: {
                gameManager.startNewGame(difficulty: gameManager.gameState.difficulty)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("New Game")
                }
                .font(.aurumBody)
                .foregroundColor(AurumTheme.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(AurumTheme.smallPadding)
                .background(
                    LinearGradient(
                        colors: [AurumTheme.goldAccent, AurumTheme.secondaryGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AurumTheme.smallRadius)
            }
        }
    }
    
    private var memoryCardsSection: some View {
        let gridSize = gameManager.gameState.difficulty.gridSize
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize.columns)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(gameManager.gameState.cards.enumerated()), id: \.element.id) { index, card in
                MemoryCardView(card: card) {
                    gameManager.selectCard(at: index)
                }
            }
        }
        .padding(AurumTheme.padding)
        .cardStyle()
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: AurumTheme.padding) {
            Button(action: { showingAchievements = true }) {
                VStack(spacing: AurumTheme.smallPadding) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(AurumTheme.goldAccent)
                    
                    Text("Achievements")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.primaryText)
                    
                    let unlockedCount = gameManager.gameState.achievements.filter { $0.isUnlocked }.count
                    Text("\(unlockedCount)/\(gameManager.gameState.achievements.count)")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(AurumTheme.padding)
                .background(AurumTheme.surfaceCard)
                .cornerRadius(AurumTheme.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                        .stroke(AurumTheme.goldAccent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingStats = true }) {
                VStack(spacing: AurumTheme.smallPadding) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(AurumTheme.goldAccent)
                    
                    Text("Statistics")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.primaryText)
                    
                    Text("\(gameManager.gameState.stats.gamesWon) wins")
                        .font(.aurumCaption)
                        .foregroundColor(AurumTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(AurumTheme.padding)
                .background(AurumTheme.surfaceCard)
                .cornerRadius(AurumTheme.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AurumTheme.smallRadius)
                        .stroke(AurumTheme.goldAccent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.isMatched ? AurumTheme.success.opacity(0.3) : AurumTheme.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                card.isMatched ? AurumTheme.success : 
                                card.isFlipped ? AurumTheme.goldAccent : AurumTheme.dividers,
                                lineWidth: card.isFlipped || card.isMatched ? 2 : 1
                            )
                    )
                
                if card.isFlipped || card.isMatched {
                    VStack(spacing: 4) {
                        Text(card.currency.flagEmoji)
                            .font(.system(size: 24))
                        
                        Text(card.currency.symbol)
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.goldAccent)
                        
                        Text(card.currency.rawValue)
                            .font(.aurumCaption)
                            .foregroundColor(AurumTheme.secondaryText)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "questionmark")
                            .font(.title2)
                            .foregroundColor(AurumTheme.secondaryText)
                        
                        Text("?")
                            .font(.aurumSubheadline)
                            .foregroundColor(AurumTheme.secondaryText)
                    }
                }
            }
            .aspectRatio(0.8, contentMode: .fit)
            .scaleEffect(card.isFlipped || card.isMatched ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: card.isFlipped)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: card.isMatched)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(card.isFlipped || card.isMatched)
    }
}

#Preview {
    GameView()
}
