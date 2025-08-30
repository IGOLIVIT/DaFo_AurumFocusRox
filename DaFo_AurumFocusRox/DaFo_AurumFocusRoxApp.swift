//
//  DaFo_AurumFocusRoxApp.swift
//  AurumFocus
//
//  Created by IGOR on 27/08/2025.
//

import SwiftUI

@main
struct AurumFocusApp: App {
    @StateObject private var dataManagers = DataManagers()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataManagers: dataManagers)
                .onAppear {
                    // Sync onboarding state with data manager
                    if dataManagers.appState.onboardingCompleted != onboardingCompleted {
                        onboardingCompleted = dataManagers.appState.onboardingCompleted
                    }
                }
                .onChange(of: dataManagers.appState.onboardingCompleted) { newValue in
                    onboardingCompleted = newValue
                }
        }
    }
}
