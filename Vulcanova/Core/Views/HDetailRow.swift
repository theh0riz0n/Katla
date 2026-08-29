//
//  HDetailRow.swift
//  Katla
//

import SwiftUI

public struct HDetailRow: View {
    public let title: String
    public let value: String
    @Bindable private var themeManager = ThemeManager.shared
    
    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimaryColor)
        }
    }
}

#Preview {
    HDetailRow(title: "Nauczyciel", value: "mgr Jan Kowalski")
}
