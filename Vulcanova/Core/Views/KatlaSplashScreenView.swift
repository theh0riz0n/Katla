//
//  KatlaSplashScreenView.swift
//  Katla
//

import SwiftUI

public struct KatlaSplashScreenView: View {
    @State private var scale: CGFloat = 0.88
    @State private var opacity: Double = 0.0
    
    public var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            Image("KatlaIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    KatlaSplashScreenView()
}
