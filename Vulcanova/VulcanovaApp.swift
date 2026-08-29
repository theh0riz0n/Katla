//
//  VulcanovaApp.swift
//  Katla
//

import SwiftUI

@main
struct VulcanovaApp: App {
    @State private var sessionManager = AppSessionManager.shared
    @State private var themeManager = ThemeManager.shared
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if sessionManager.isLoggedIn {
                        ContentView()
                    } else {
                        OnboardingView()
                    }
                }
                
                if isShowingSplash {
                    KatlaSplashScreenView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .preferredColorScheme(themeManager.preferredColorScheme)
            .task {
                _ = await NotificationService.shared.requestAuthorization()
                
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
