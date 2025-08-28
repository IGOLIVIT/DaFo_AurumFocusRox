//
//  DaFo_AurumFocusRoxApp.swift
//  AurumFocus
//
//  Created by IGOR on 27/08/2025.
//

import SwiftUI

@main
struct AurumFocusApp: App {
    @StateObject private var dataManager = DataManager()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataManager: dataManager)
                .onAppear {
                    // Sync onboarding state with data manager
                    if dataManager.appState.onboardingCompleted != onboardingCompleted {
                        onboardingCompleted = dataManager.appState.onboardingCompleted
                    }
                }
                .onChange(of: dataManager.appState.onboardingCompleted) { newValue in
                    onboardingCompleted = newValue
                }
        }
    }
}
