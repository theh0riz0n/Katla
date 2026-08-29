//
//  LuckyNumberCard.swift
//  Vulcanova
//

import SwiftUI

public struct LuckyNumberCard: View {
    public let number: Int?
    
    public init(number: Int?) {
        self.number = number
    }
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "7C3AED"),
                    Color(hex: "C084FC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: "7C3AED").opacity(0.4), radius: 10, x: 0, y: 5)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SZCZĘŚLIWY NUMEREK")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1.2)
                    
                    if let number = number {
                        Text("Dzisiaj numer \(number)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("Brak danych na dziś")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 54, height: 54)
                    
                    if let number = number {
                        Text("\(number)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "clover.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    ZStack {
        VulcanColors.darkBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            LuckyNumberCard(number: 14)
            LuckyNumberCard(number: nil)
        }
        .padding()
    }
}
