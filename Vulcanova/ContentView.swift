//
//  ContentView.swift
//  Katla
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    
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
            
            MoreMenuView()
                .tabItem {
                    Label(langManager.string(for: "tab_more"), systemImage: "square.grid.2x2.fill")
                }
                .tag(3)
        }
        .accentColor(VulcanColors.primaryAccent)
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

#Preview {
    ContentView()
}
