//
//  VulcanColors.swift
//  Katla
//

import SwiftUI

public enum VulcanColors {
    // MARK: - Brand Accents
    public static var primaryAccent: Color {
        ThemeManager.shared.primaryAccent
    }
    
    public static let primaryAccentLight = Color(hex: "8B5CF6")
    public static let secondaryAccent = Color(hex: "3B82F6")    // Electric Blue
    
    // MARK: - Surfaces & Backgrounds
    public static let darkBackground = Color(hex: "0F172A")     // Deep Slate Navy
    public static let cardBackground = Color(hex: "1E293B")     // Slate Card
    public static let cardBorder = Color(hex: "334155")         // Subtle Border
    
    // MARK: - Text & Icons
    public static let textPrimary = Color(hex: "F8FAFC")
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textMuted = Color(hex: "64748B")
    
    // MARK: - Grade Colors
    public static func color(forGrade gradeValue: Double) -> Color {
        switch gradeValue {
        case 5.5...6.0: return Color(hex: "10B981") // Emerald 6
        case 4.5..<5.5: return Color(hex: "22C55E") // Green 5
        case 3.5..<4.5: return Color(hex: "0EA5E9") // Sky Blue 4
        case 2.5..<3.5: return Color(hex: "F59E0B") // Amber 3
        case 1.5..<2.5: return Color(hex: "F97316") // Orange 2
        default:        return Color(hex: "EF4444") // Red 1
        }
    }
    
    // MARK: - Attendance Status Colors
    public static func color(forAttendanceSymbol symbol: String) -> Color {
        switch symbol.lowercased() {
        case "ob", "presence": return Color(hex: "10B981")
        case "nb", "absence":  return Color(hex: "EF4444")
        case "sp", "tardiness": return Color(hex: "F59E0B")
        case "u", "excused":   return Color(hex: "0EA5E9")
        default:               return Color(hex: "64748B")
        }
    }
}

// MARK: - Hex Initializer & Converter Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    public func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "7C3AED"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
