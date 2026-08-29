//
//  AppSessionManager.swift
//  Vulcanova
//

import SwiftUI

@Observable
public final class AppSessionManager {
    public static let shared = AppSessionManager()
    
    public var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "is_logged_in")
        }
    }
    
    public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
        }
    }
    
    private init() {
        let loggedIn = UserDefaults.standard.bool(forKey: "is_logged_in")
        let accountExists = AccountManager.shared.activeAccount != nil
        self.isLoggedIn = loggedIn && accountExists
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    }
    
    public func completeOnboarding() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
    
    public func logIn() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isLoggedIn = true
        }
    }
    
    public func logOut() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            AccountManager.shared.clearAccount()
            isLoggedIn = false
        }
    }
}
