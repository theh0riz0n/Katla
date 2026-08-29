//
//  OnboardingView.swift
//  Katla
//

import SwiftUI

public struct OnboardingSlide: Identifiable {
    public let id = UUID()
    public let iconName: String
    public let title: String
    public let description: String
    public let accentColor: Color
}

public struct OnboardingView: View {
    @State private var currentTab = 0
    @State private var showLoginView = false
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    
    private var slides: [OnboardingSlide] {
        let lang = langManager.currentLanguage
        switch lang {
        case .polish:
            return [
                OnboardingSlide(
                    iconName: "graduationcap.fill",
                    title: "Witaj w Katla",
                    description: "Nowoczesny, niezwykle szybki i piękny klient dla dziennika elektronicznego EduVulcan.",
                    accentColor: VulcanColors.primaryAccent
                ),
                OnboardingSlide(
                    iconName: "chart.bar.doc.horizontal.fill",
                    title: "Plan Lekcji, Oceny i Numerek",
                    description: "Błyskawiczne sprawdzanie ocen ze średnimi ważonymi, planu lekcji oraz Szczęśliwego Numerka.",
                    accentColor: Color(hex: "0EA5E9")
                ),
                OnboardingSlide(
                    iconName: "moon.stars.fill",
                    title: "Tryb AMOLED i Prywatność",
                    description: "Czysta czerń dla oszczędności baterii. Twoje dane są bezpiecznie szyfrowane na Twoim urządzeniu.",
                    accentColor: Color(hex: "10B981")
                )
            ]
        case .english:
            return [
                OnboardingSlide(
                    iconName: "graduationcap.fill",
                    title: "Welcome to Katla",
                    description: "Modern, ultra-fast and beautiful mobile client for EduVulcan school gradebook.",
                    accentColor: VulcanColors.primaryAccent
                ),
                OnboardingSlide(
                    iconName: "chart.bar.doc.horizontal.fill",
                    title: "Timetable, Grades & Lucky Number",
                    description: "Instant access to weighted average grades, class schedules, and your daily Lucky Number.",
                    accentColor: Color(hex: "0EA5E9")
                ),
                OnboardingSlide(
                    iconName: "moon.stars.fill",
                    title: "AMOLED Dark Mode & Privacy",
                    description: "Pure dark theme for maximum battery saving. Your data is encrypted locally on device.",
                    accentColor: Color(hex: "10B981")
                )
            ]
        case .ukrainian:
            return [
                OnboardingSlide(
                    iconName: "graduationcap.fill",
                    title: "Ласкаво просимо до Katla",
                    description: "Сучасний, надшвидкий та красивий мобільний клієнт для щоденника EduVulcan.",
                    accentColor: VulcanColors.primaryAccent
                ),
                OnboardingSlide(
                    iconName: "chart.bar.doc.horizontal.fill",
                    title: "Розклад, Оцінки та Номер",
                    description: "Миттєва перевірка оцінок із середнім балом, розкладу уроків та Щасливого Номера.",
                    accentColor: Color(hex: "0EA5E9")
                ),
                OnboardingSlide(
                    iconName: "moon.stars.fill",
                    title: "AMOLED Режим та Безпека",
                    description: "Темна тема для економії акумулятора. Ваші дані надійно зашифровані на пристрої.",
                    accentColor: Color(hex: "10B981")
                )
            ]
        }
    }
    
    private var loginButtonTitle: String {
        switch langManager.currentLanguage {
        case .polish: return "Zaloguj się kontem EduVulcan"
        case .english: return "Log in with EduVulcan"
        case .ukrainian: return "Увійти через EduVulcan"
        }
    }
    
    private var demoButtonTitle: String {
        switch langManager.currentLanguage {
        case .polish: return "Wypróbuj wersję demonstracyjną"
        case .english: return "Try Demo Mode"
        case .ukrainian: return "Спробувати демо-версію"
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Language Selector Button
                    HStack {
                        Spacer()
                        
                        Menu {
                            ForEach(AppLanguage.allCases) { lang in
                                Button {
                                    withAnimation {
                                        langManager.currentLanguage = lang
                                    }
                                } label: {
                                    HStack {
                                        Text(lang.displayName)
                                        if langManager.currentLanguage == lang {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 14, weight: .bold))
                                Text(langManager.currentLanguage.displayName)
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(themeManager.textPrimaryColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(themeManager.cardBackgroundColor)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(themeManager.cardBorderColor, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // MARK: - Carousel Page View
                    TabView(selection: $currentTab) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            let slide = slides[index]
                            
                            VStack(spacing: 28) {
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .fill(slide.accentColor.opacity(0.15))
                                        .frame(width: 140, height: 140)
                                    
                                    Image(systemName: slide.iconName)
                                        .font(.system(size: 64, weight: .bold))
                                        .foregroundColor(slide.accentColor)
                                }
                                .shadow(color: slide.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                VStack(spacing: 12) {
                                    Text(slide.title)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(slide.description)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                        .padding(.horizontal, 24)
                                }
                                
                                Spacer()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // MARK: - Page Indicator Strip
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentTab ? VulcanColors.primaryAccent : themeManager.cardBorderColor)
                                .frame(width: index == currentTab ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTab)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    // MARK: - Bottom Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showLoginView = true
                        } label: {
                            HStack {
                                Text(loginButtonTitle)
                                    .font(.system(size: 17, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(VulcanColors.primaryAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: VulcanColors.primaryAccent.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        
                        Button {
                            // Demo Mode
                            AppSessionManager.shared.completeOnboarding()
                            AppSessionManager.shared.logIn()
                        } label: {
                            Text(demoButtonTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showLoginView) {
                LoginView()
            }
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

#Preview {
    OnboardingView()
}
