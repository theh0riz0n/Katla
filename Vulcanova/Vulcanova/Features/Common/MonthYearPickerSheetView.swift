//
//  MonthYearPickerSheetView.swift
//  Vulcanova
//

import SwiftUI

public struct MonthYearPickerSheetView: View {
    @Binding public var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    DatePicker(
                        "Wybierz datę",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(VulcanColors.primaryAccent)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(themeManager.cardBorderColor, lineWidth: 1)
                    )
                    .padding(20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Wybierz miesiąc i dzień")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gotowe") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(VulcanColors.primaryAccent)
                }
            }
        }
    }
}

#Preview {
    MonthYearPickerSheetView(selectedDate: .constant(Date()))
}
