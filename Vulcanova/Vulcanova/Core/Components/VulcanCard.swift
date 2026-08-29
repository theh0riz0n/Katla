//
//  VulcanCard.swift
//  Vulcanova
//

import SwiftUI

public struct VulcanCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private var theme = ThemeManager.shared
    
    public init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(theme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.cardBorderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(theme.currentTheme == .amoled ? 0 : 0.12), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        ThemeManager.shared.backgroundColor.ignoresSafeArea()
        VulcanCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Przykładowa karta")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.textPrimaryColor)
                Text("Dizajn karty ze wsparciem AMOLED i Light Mode")
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.shared.textSecondaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
