//
//  ContentView.swift
//  AurumFocus
//
//  Created by IGOR on 27/08/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager: DataManager
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var body: some View {
        Group {
            if dataManager.appState.onboardingCompleted || onboardingCompleted {
                MainTabView(dataManager: dataManager)
            } else {
                OnboardingView(dataManager: dataManager)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView(dataManager: DataManager())
}
