//
//  GameModels.swift
//  AurumFocus
//

import Foundation

// MARK: - Memory Game Models

enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    case rub = "RUB"
    case inr = "INR"
    case krw = "KRW"
    case brl = "BRL"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "C$"
        case .aud: return "A$"
        case .chf: return "CHF"
        case .cny: return "¥"
        case .rub: return "₽"
        case .inr: return "₹"
        case .krw: return "₩"
        case .brl: return "R$"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        case .rub: return "Russian Ruble"
        case .inr: return "Indian Rupee"
        case .krw: return "South Korean Won"
        case .brl: return "Brazilian Real"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .gbp: return "🇬🇧"
        case .jpy: return "🇯🇵"
        case .cad: return "🇨🇦"
        case .aud: return "🇦🇺"
        case .chf: return "🇨🇭"
        case .cny: return "🇨🇳"
        case .rub: return "🇷🇺"
        case .inr: return "🇮🇳"
        case .krw: return "🇰🇷"
        case .brl: return "🇧🇷"
        }
    }
}

struct MemoryCard: Identifiable, Codable {
    let id = UUID()
    let currency: Currency
    var isFlipped: Bool = false
    var isMatched: Bool = false
    var isTemporarilyFlipped: Bool = false
    
    init(currency: Currency) {
        self.currency = currency
    }
}

enum GameDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var gridSize: (rows: Int, columns: Int) {
        switch self {
        case .easy: return (3, 4)    // 12 cards (6 pairs)
        case .medium: return (4, 4)  // 16 cards (8 pairs)
        case .hard: return (4, 6)    // 24 cards (12 pairs)
        }
    }
    
    var pairCount: Int {
        let size = gridSize
        return (size.rows * size.columns) / 2
    }
}

struct MemoryGameStats: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalMoves: Int = 0
    var bestTime: TimeInterval = 0
    var bestMoves: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var easyGamesWon: Int = 0
    var mediumGamesWon: Int = 0
    var hardGamesWon: Int = 0
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
    
    var averageMoves: Double {
        guard gamesWon > 0 else { return 0 }
        return Double(totalMoves) / Double(gamesWon)
    }
    
    mutating func recordGame(won: Bool, moves: Int, time: TimeInterval, difficulty: GameDifficulty) {
        gamesPlayed += 1
        
        if won {
            gamesWon += 1
            totalMoves += moves
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            
            if bestTime == 0 || time < bestTime {
                bestTime = time
            }
            
            if bestMoves == 0 || moves < bestMoves {
                bestMoves = moves
            }
            
            switch difficulty {
            case .easy: easyGamesWon += 1
            case .medium: mediumGamesWon += 1
            case .hard: hardGamesWon += 1
            }
        } else {
            currentStreak = 0
        }
    }
}

struct MemoryGameAchievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let requirement: MemoryAchievementRequirement
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    mutating func unlock() {
        isUnlocked = true
        unlockedDate = Date()
    }
}

enum MemoryAchievementRequirement: Codable {
    case firstWin
    case winStreak(Int)
    case perfectGame(GameDifficulty) // Win with minimum moves
    case speedRun(TimeInterval) // Win under time limit
    case totalWins(Int)
    case winAllDifficulties
}

struct MemoryGameState: Codable {
    var cards: [MemoryCard] = []
    var difficulty: GameDifficulty = .easy
    var moves: Int = 0
    var matches: Int = 0
    var gameStartTime: Date?
    var gameEndTime: Date?
    var isGameActive: Bool = false
    var selectedCards: [UUID] = []
    var stats: MemoryGameStats = MemoryGameStats()
    var achievements: [MemoryGameAchievement] = []
    
    init() {
        self.achievements = MemoryGameState.createAchievements()
        startNewGame(difficulty: .easy)
    }
    
    var isGameComplete: Bool {
        return matches == difficulty.pairCount
    }
    
    var gameTime: TimeInterval {
        guard let startTime = gameStartTime else { return 0 }
        let endTime = gameEndTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    mutating func startNewGame(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        self.moves = 0
        self.matches = 0
        self.gameStartTime = Date()
        self.gameEndTime = nil
        self.isGameActive = true
        self.selectedCards = []
        
        // Create pairs of currencies
        let availableCurrencies = Array(Currency.allCases.prefix(difficulty.pairCount))
        var gameCards: [MemoryCard] = []
        
        // Add two cards for each currency (pair)
        for currency in availableCurrencies {
            gameCards.append(MemoryCard(currency: currency))
            gameCards.append(MemoryCard(currency: currency))
        }
        
        // Shuffle the cards
        self.cards = gameCards.shuffled()
    }
    
    mutating func selectCard(at index: Int) -> Bool {
        guard isGameActive,
              index < cards.count,
              !cards[index].isMatched,
              !cards[index].isFlipped,
              selectedCards.count < 2 else {
            return false
        }
        
        cards[index].isFlipped = true
        selectedCards.append(cards[index].id)
        
        if selectedCards.count == 2 {
            moves += 1
            checkForMatch()
        }
        
        return true
    }
    
    private mutating func checkForMatch() {
        guard selectedCards.count == 2 else { return }
        
        let firstIndex = cards.firstIndex { $0.id == selectedCards[0] }
        let secondIndex = cards.firstIndex { $0.id == selectedCards[1] }
        
        guard let first = firstIndex, let second = secondIndex else { return }
        
        if cards[first].currency == cards[second].currency {
            // Match found
            cards[first].isMatched = true
            cards[second].isMatched = true
            matches += 1
            selectedCards = []
            
            if isGameComplete {
                endGame()
            }
        } else {
            // No match - cards will be flipped back after delay
            cards[first].isTemporarilyFlipped = true
            cards[second].isTemporarilyFlipped = true
        }
    }
    
    mutating func flipBackMismatchedCards() {
        for i in 0..<cards.count {
            if cards[i].isTemporarilyFlipped {
                cards[i].isFlipped = false
                cards[i].isTemporarilyFlipped = false
            }
        }
        selectedCards = []
    }
    
    private mutating func endGame() {
        isGameActive = false
        gameEndTime = Date()
        
        let gameWon = isGameComplete
        stats.recordGame(won: gameWon, moves: moves, time: gameTime, difficulty: difficulty)
        
        checkAchievements()
    }
    
    private mutating func checkAchievements() {
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked {
                let requirement = achievements[i].requirement
                var shouldUnlock = false
                
                switch requirement {
                case .firstWin:
                    shouldUnlock = stats.gamesWon >= 1
                case .winStreak(let target):
                    shouldUnlock = stats.currentStreak >= target
                case .perfectGame(let targetDifficulty):
                    let minMoves = targetDifficulty.pairCount
                    shouldUnlock = difficulty == targetDifficulty && moves == minMoves && isGameComplete
                case .speedRun(let timeLimit):
                    shouldUnlock = gameTime <= timeLimit && isGameComplete
                case .totalWins(let target):
                    shouldUnlock = stats.gamesWon >= target
                case .winAllDifficulties:
                    shouldUnlock = stats.easyGamesWon > 0 && stats.mediumGamesWon > 0 && stats.hardGamesWon > 0
                }
                
                if shouldUnlock {
                    achievements[i].unlock()
                }
            }
        }
    }
    
    static func createAchievements() -> [MemoryGameAchievement] {
        return [
            MemoryGameAchievement(
                title: "First Victory",
                description: "Win your first memory game",
                icon: "trophy.fill",
                requirement: .firstWin
            ),
            MemoryGameAchievement(
                title: "Perfect Memory",
                description: "Win an easy game with minimum moves",
                icon: "brain.head.profile",
                requirement: .perfectGame(.easy)
            ),
            MemoryGameAchievement(
                title: "Speed Demon",
                description: "Win a game in under 30 seconds",
                icon: "bolt.fill",
                requirement: .speedRun(30)
            ),
            MemoryGameAchievement(
                title: "Win Streak",
                description: "Win 5 games in a row",
                icon: "flame.fill",
                requirement: .winStreak(5)
            ),
            MemoryGameAchievement(
                title: "Memory Master",
                description: "Win 25 games total",
                icon: "star.fill",
                requirement: .totalWins(25)
            ),
            MemoryGameAchievement(
                title: "All Difficulties",
                description: "Win at least one game on each difficulty",
                icon: "medal.fill",
                requirement: .winAllDifficulties
            )
        ]
    }
}
