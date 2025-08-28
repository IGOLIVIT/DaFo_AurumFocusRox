//
//  GameManager.swift
//  AurumFocus
//

import Foundation
import Combine
import UIKit

class MemoryGameManager: ObservableObject {
    @Published var gameState: MemoryGameState
    private var flipBackTimer: Timer?
    private let saveKey = "AurumFocusMemoryGameState"
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: saveKey),
           let decodedState = try? JSONDecoder().decode(MemoryGameState.self, from: savedData) {
            self.gameState = decodedState
        } else {
            self.gameState = MemoryGameState()
        }
    }
    
    func startNewGame(difficulty: GameDifficulty) {
        gameState.startNewGame(difficulty: difficulty)
        saveGame()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func selectCard(at index: Int) {
        let wasSelected = gameState.selectCard(at: index)
        
        if wasSelected {
            saveGame()
            
            // Light haptic feedback for card flip
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Check if we need to flip back mismatched cards
            if gameState.selectedCards.count == 2 {
                let firstIndex = gameState.cards.firstIndex { $0.id == gameState.selectedCards[0] }
                let secondIndex = gameState.cards.firstIndex { $0.id == gameState.selectedCards[1] }
                
                if let first = firstIndex, let second = secondIndex {
                    let isMatch = gameState.cards[first].currency == gameState.cards[second].currency
                    
                    if isMatch {
                        // Success haptic for match
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        // Check if game is complete
                        if gameState.isGameComplete {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let notificationFeedback = UINotificationFeedbackGenerator()
                                notificationFeedback.notificationOccurred(.success)
                            }
                        }
                    } else {
                        // Schedule flip back after delay
                        flipBackTimer?.invalidate()
                        flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                            self.gameState.flipBackMismatchedCards()
                            self.saveGame()
                        }
                    }
                }
            }
        }
    }
    
    func resetStats() {
        gameState.stats = MemoryGameStats()
        saveGame()
    }
    
    private func saveGame() {
        if let encodedData = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(encodedData, forKey: saveKey)
        }
    }
    
    deinit {
        flipBackTimer?.invalidate()
    }
}
