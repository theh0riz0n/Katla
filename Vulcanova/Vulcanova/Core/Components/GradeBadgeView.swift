//
//  GradeBadgeView.swift
//  Vulcanova
//

import SwiftUI

public struct GradeBadgeView: View {
    public let gradeDisplayText: String
    public let numericValue: Double
    public let weight: Int?
    public let size: Size
    
    public enum Size {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 42
            case .large: return 52
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    public init(
        gradeDisplayText: String,
        numericValue: Double,
        weight: Int? = nil,
        size: Size = .medium
    ) {
        self.gradeDisplayText = gradeDisplayText
        self.numericValue = numericValue
        self.weight = weight
        self.size = size
    }
    
    private var gradeColor: Color {
        VulcanColors.color(forGrade: numericValue)
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(gradeDisplayText)
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(gradeColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: gradeColor.opacity(0.4), radius: 6, x: 0, y: 3)
            
            if let weight = weight {
                Text("\(weight)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .offset(x: 4, y: -4)
            }
        }
    }
}

#Preview {
    ZStack {
        VulcanColors.darkBackground.ignoresSafeArea()
        HStack(spacing: 16) {
            GradeBadgeView(gradeDisplayText: "6", numericValue: 6.0, weight: 3, size: .medium)
            GradeBadgeView(gradeDisplayText: "5+", numericValue: 5.5, weight: 2, size: .medium)
            GradeBadgeView(gradeDisplayText: "4", numericValue: 4.0, weight: 1, size: .medium)
            GradeBadgeView(gradeDisplayText: "2-", numericValue: 1.75, weight: 2, size: .medium)
            GradeBadgeView(gradeDisplayText: "1", numericValue: 1.0, weight: 3, size: .medium)
        }
    }
}
