//
//  SubjectGradesDetailView.swift
//  Vulcanova
//

import SwiftUI

public struct SubjectGradesDetailView: View {
    public let group: SubjectGradesGroup
    @Bindable private var themeManager = ThemeManager.shared
    
    public var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Subject Header Banner with Weighted Average
                    VStack(spacing: 12) {
                        Text(group.subjectName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 2) {
                                Text("ŚREDNIA WAŻONA")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(VulcanColors.textMuted)
                                    .tracking(1.1)
                                Text(group.average > 0 ? String(format: "%.2f", group.average) : "—")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(VulcanColors.primaryAccent)
                            }
                            
                            if let summary = group.summary {
                                Divider()
                                    .frame(height: 36)
                                    .overlay(themeManager.cardBorderColor)
                                
                                VStack(spacing: 2) {
                                    Text("PRZEWIDYWANA")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(VulcanColors.textMuted)
                                        .tracking(1.1)
                                    Text(summary.entry1 ?? "—")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                
                                Divider()
                                    .frame(height: 36)
                                    .overlay(themeManager.cardBorderColor)
                                
                                VStack(spacing: 2) {
                                    Text("KOŃCOWA")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(VulcanColors.textMuted)
                                        .tracking(1.1)
                                    Text(summary.entry2 ?? "—")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(VulcanColors.primaryAccent)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(themeManager.cardBorderColor, lineWidth: 1)
                    )
                    
                    // MARK: - Detailed Partial Grades List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("OCENY CZĄSTKOWE (\(group.grades.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            Spacer()
                        }
                        
                        if group.grades.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(VulcanColors.textMuted)
                                Text("Brak ocen cząstkowych z tego przedmiotu")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                            .padding(.vertical, 30)
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(group.grades) { grade in
                                HStack(spacing: 16) {
                                    // Big Color Grade Box
                                    Text(grade.displayText)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 52, height: 52)
                                        .background(colorForGrade(grade.value))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(grade.content.isEmpty ? grade.categoryName : grade.content)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(themeManager.textPrimaryColor)
                                        
                                        HStack(spacing: 10) {
                                            Text("Waga: \(grade.weight)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(VulcanColors.primaryAccent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(VulcanColors.primaryAccent.opacity(0.12))
                                                .clipShape(Capsule())
                                            
                                            Text(grade.categoryName)
                                                .font(.caption)
                                                .foregroundColor(themeManager.textSecondaryColor)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background(themeManager.cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(themeManager.cardBorderColor, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(group.subjectName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func colorForGrade(_ val: Double) -> Color {
        switch val {
        case 5.0...6.0: return Color.green
        case 4.0..<5.0: return Color.blue
        case 3.0..<4.0: return Color.orange
        case 2.0..<3.0: return Color.purple
        default: return Color.red
        }
    }
}
