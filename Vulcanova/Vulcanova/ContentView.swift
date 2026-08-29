//
//  ContentView.swift
//  Katla
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var dataService = EduVulcanDataService.shared
    
    private var unreadCount: Int {
        dataService.receivedMessages.filter { !$0.isRead }.count
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(langManager.string(for: "tab_dashboard"), systemImage: "house.fill")
                }
                .tag(0)
            
            TimetableView()
                .tabItem {
                    Label(langManager.string(for: "tab_timetable"), systemImage: "calendar")
                }
                .tag(1)
            
            GradesView()
                .tabItem {
                    Label(langManager.string(for: "tab_grades"), systemImage: "chart.bar.doc.horizontal.fill")
                }
                .tag(2)
            
            MessagesView()
                .tabItem {
                    Label(langManager.string(for: "tab_messages"), systemImage: "envelope.fill")
                }
                .badge(unreadCount)
                .tag(3)
            
            MoreMenuView()
                .tabItem {
                    Label(langManager.string(for: "tab_more"), systemImage: "square.grid.2x2.fill")
                }
                .tag(4)
        }
        .accentColor(VulcanColors.primaryAccent)
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

#Preview {
    ContentView()
}
