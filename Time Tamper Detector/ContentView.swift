//
//  ContentView.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimeTamperViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimeTamperMainView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "shield.checkered")
                    Text("Scanner")
                }
                .tag(0)
            
            ScanHistoryView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    Text("History")
                }
                .tag(1)
            
            SystemInfoView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("System")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
