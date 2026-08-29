//
//  ThemeManager.swift
//  Katla
//

import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "Ciemny (Granat)"
    case amoled = "AMOLED (Czerń)"
    case light = "Jasny"
    case system = "Systemowy"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dark: return "moon.stars.fill"
        case .amoled: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "iphone"
        }
    }
}

public struct AccentColorPreset: Identifiable {
    public let id: String
    public let name: String
    public let hex: String
    public let color: Color
}

@Observable
public final class ThemeManager {
    public static let shared = ThemeManager()
    
    public static let presetAccents: [AccentColorPreset] = [
        AccentColorPreset(id: "purple", name: "Fiolet (Katla)", hex: "7C3AED", color: Color(hex: "7C3AED")),
        AccentColorPreset(id: "blue", name: "Ocean Blue", hex: "2563EB", color: Color(hex: "2563EB")),
        AccentColorPreset(id: "emerald", name: "Szmaragd", hex: "059669", color: Color(hex: "059669")),
        AccentColorPreset(id: "orange", name: "Płomienny", hex: "EA580C", color: Color(hex: "EA580C")),
        AccentColorPreset(id: "crimson", name: "Karmazyn", hex: "E11D48", color: Color(hex: "E11D48")),
        AccentColorPreset(id: "pink", name: "Neon Pink", hex: "DB2777", color: Color(hex: "DB2777"))
    ]
    
    public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme_preference")
        }
    }
    
    public var accentHex: String {
        didSet {
            UserDefaults.standard.set(accentHex, forKey: "app_accent_hex")
        }
    }
    
    public var primaryAccent: Color {
        Color(hex: accentHex)
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme_preference") ?? AppTheme.dark.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .dark
        
        self.accentHex = UserDefaults.standard.string(forKey: "app_accent_hex") ?? "7C3AED"
    }
    
    // MARK: - Dynamic Theme Colors
    public var backgroundColor: Color {
        switch currentTheme {
        case .dark: return VulcanColors.darkBackground
        case .amoled: return Color.black
        case .light: return Color(hex: "F8FAFC")
        case .system: return Color(uiColor: .systemBackground)
        }
    }
    
    public var cardBackgroundColor: Color {
        switch currentTheme {
        case .dark: return VulcanColors.cardBackground
        case .amoled: return Color(hex: "121212")
        case .light: return Color.white
        case .system: return Color(uiColor: .secondarySystemBackground)
        }
    }
    
    public var cardBorderColor: Color {
        switch currentTheme {
        case .dark: return VulcanColors.cardBorder
        case .amoled: return Color(hex: "262626")
        case .light: return Color(hex: "E2E8F0")
        case .system: return Color(uiColor: .separator)
        }
    }
    
    public var textPrimaryColor: Color {
        switch currentTheme {
        case .dark, .amoled: return Color(hex: "F8FAFC")
        case .light: return Color(hex: "0F172A")
        case .system: return Color(uiColor: .label)
        }
    }
    
    public var textSecondaryColor: Color {
        switch currentTheme {
        case .dark, .amoled: return Color(hex: "94A3B8")
        case .light: return Color(hex: "64748B")
        case .system: return Color(uiColor: .secondaryLabel)
        }
    }
    
    public var preferredColorScheme: ColorScheme? {
        switch currentTheme {
        case .dark, .amoled: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
