//
//  MainTabView.swift
//  AurumFocus
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(dataManager: dataManager, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Dashboard")
                }
                .tag(0)
            
            PlannerView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Planner")
                }
                .tag(1)
            
            HabitsView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Habits")
                }
                .tag(2)
            
            GameView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
                .tag(3)
        }
        .accentColor(AurumTheme.goldAccent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView(dataManager: DataManager())
}
