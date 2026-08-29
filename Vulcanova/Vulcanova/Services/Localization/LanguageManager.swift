//
//  LanguageManager.swift
//  Katla
//

import SwiftUI
import Observation

public enum AppLanguage: String, CaseIterable, Identifiable {
    case polish = "pl"
    case english = "en"
    case ukrainian = "uk"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .polish: return "Polski 🇵🇱"
        case .english: return "English 🇬🇧"
        case .ukrainian: return "Українська 🇺🇦"
        }
    }
}

@Observable
public final class LanguageManager {
    public static let shared = LanguageManager()
    
    public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language_preference")
        }
    }
    
    private init() {
        let savedRaw = UserDefaults.standard.string(forKey: "app_language_preference") ?? AppLanguage.polish.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedRaw) ?? .polish
    }
    
    /// Translates key dynamically based on active language
    public func string(for key: String) -> String {
        let lang = currentLanguage
        switch key {
        // MARK: - Navigation Tabs
        case "tab_dashboard":
            switch lang {
            case .polish: return "Główna"
            case .english: return "Home"
            case .ukrainian: return "Головна"
            }
        case "tab_timetable":
            switch lang {
            case .polish: return "Plan lekcji"
            case .english: return "Timetable"
            case .ukrainian: return "Розклад"
            }
        case "tab_grades":
            switch lang {
            case .polish: return "Oceny"
            case .english: return "Grades"
            case .ukrainian: return "Оцінки"
            }
        case "tab_messages":
            switch lang {
            case .polish: return "Wiadomości"
            case .english: return "Messages"
            case .ukrainian: return "Повідомлення"
            }
        case "tab_more":
            switch lang {
            case .polish: return "Więcej"
            case .english: return "More"
            case .ukrainian: return "Більше"
            }
            
        // MARK: - Dashboard
        case "dash_welcome":
            switch lang {
            case .polish: return "Witaj z powrotem,"
            case .english: return "Welcome back,"
            case .ukrainian: return "З поверненням,"
            }
        case "dash_lucky":
            switch lang {
            case .polish: return "Szczęśliwy numer"
            case .english: return "Lucky Number"
            case .ukrainian: return "Щасливий номер"
            }
        case "dash_no_lucky":
            switch lang {
            case .polish: return "Brak dzisiaj"
            case .english: return "None today"
            case .ukrainian: return "Немає сьогодні"
            }
        case "dash_today_lessons":
            switch lang {
            case .polish: return "DZISIEJSZE LEKCJE"
            case .english: return "TODAY'S LESSONS"
            case .ukrainian: return "СЬОГОДНІШНІ УРОКИ"
            }
        case "dash_no_lessons":
            switch lang {
            case .polish: return "Brak lekcji na dzisiaj"
            case .english: return "No lessons today"
            case .ukrainian: return "Немає уроків на сьогодні"
            }
        case "dash_recent_grades":
            switch lang {
            case .polish: return "OSTATNIE OCENY"
            case .english: return "RECENT GRADES"
            case .ukrainian: return "ОСТАННІ ОЦІНКИ"
            }
        case "dash_upcoming_exams":
            switch lang {
            case .polish: return "NADCHODZĄCE SPRAWDZIANY"
            case .english: return "UPCOMING EXAMS"
            case .ukrainian: return "МАЙБУТНІ КОНТРОЛЬНІ"
            }
            
        // MARK: - Timetable
        case "tt_title":
            switch lang {
            case .polish: return "Plan lekcji"
            case .english: return "Timetable"
            case .ukrainian: return "Розклад уроків"
            }
        case "tt_today":
            switch lang {
            case .polish: return "Dzisiaj"
            case .english: return "Today"
            case .ukrainian: return "Сьогодні"
            }
        case "tt_no_lessons":
            switch lang {
            case .polish: return "Brak lekcji w tym dniu"
            case .english: return "No lessons on this day"
            case .ukrainian: return "Немає уроків у цей день"
            }
        case "tt_cancelled":
            switch lang {
            case .polish: return "ODWOŁANA"
            case .english: return "CANCELLED"
            case .ukrainian: return "СКАСОВАНО"
            }
        case "tt_substitution":
            switch lang {
            case .polish: return "ZASTĘPSTWO"
            case .english: return "SUBSTITUTION"
            case .ukrainian: return "ЗАМІНА"
            }
            
        // MARK: - Grades
        case "gr_title":
            switch lang {
            case .polish: return "Oceny"
            case .english: return "Grades"
            case .ukrainian: return "Оцінки"
            }
        case "gr_sem1":
            switch lang {
            case .polish: return "Semestr 1"
            case .english: return "Semester 1"
            case .ukrainian: return "Семестр 1"
            }
        case "gr_sem2":
            switch lang {
            case .polish: return "Semestr 2"
            case .english: return "Semester 2"
            case .ukrainian: return "Семестр 2"
            }
        case "gr_partial":
            switch lang {
            case .polish: return "Cząstkowe"
            case .english: return "Partial"
            case .ukrainian: return "Поточні"
            }
        case "gr_summary":
            switch lang {
            case .polish: return "Przewidywane i Końcowe"
            case .english: return "Predicted & Final"
            case .ukrainian: return "Підсумкові"
            }
        case "gr_avg":
            switch lang {
            case .polish: return "Średnia ważona"
            case .english: return "Weighted Average"
            case .ukrainian: return "Середній бал"
            }
        case "gr_no_grades":
            switch lang {
            case .polish: return "Brak ocen w tym semestrze"
            case .english: return "No grades this semester"
            case .ukrainian: return "Немає оцінок у цьому семестрі"
            }
            
        // MARK: - Messages
        case "msg_title":
            switch lang {
            case .polish: return "Wiadomości"
            case .english: return "Messages"
            case .ukrainian: return "Повідомлення"
            }
        case "msg_received":
            switch lang {
            case .polish: return "Odebrane"
            case .english: return "Inbox"
            case .ukrainian: return "Вхідні"
            }
        case "msg_sent":
            switch lang {
            case .polish: return "Wysłane"
            case .english: return "Sent"
            case .ukrainian: return "Надіслані"
            }
        case "msg_deleted":
            switch lang {
            case .polish: return "Kosz"
            case .english: return "Trash"
            case .ukrainian: return "Кошик"
            }
        case "msg_search":
            switch lang {
            case .polish: return "Szukaj po nadawcy lub temacie..."
            case .english: return "Search sender or subject..."
            case .ukrainian: return "Пошук за відправником або темою..."
            }
        case "msg_write":
            switch lang {
            case .polish: return "Napisz"
            case .english: return "Compose"
            case .ukrainian: return "Написати"
            }
        case "msg_recipient":
            switch lang {
            case .polish: return "ODBIORCA"
            case .english: return "RECIPIENT"
            case .ukrainian: return "ОТРИМУВАЧ"
            }
        case "msg_subject":
            switch lang {
            case .polish: return "TEMAT WIADOMOŚCI"
            case .english: return "SUBJECT"
            case .ukrainian: return "ТЕМА"
            }
        case "msg_content":
            switch lang {
            case .polish: return "TREŚĆ WIADOMOŚCI"
            case .english: return "MESSAGE CONTENT"
            case .ukrainian: return "ТЕКСТ ПОВІДОМЛЕННЯ"
            }
        case "msg_send_btn":
            switch lang {
            case .polish: return "Wyślij"
            case .english: return "Send"
            case .ukrainian: return "Надіслати"
            }
            
        // MARK: - Attendance
        case "att_title":
            switch lang {
            case .polish: return "Frekwencja"
            case .english: return "Attendance"
            case .ukrainian: return "Відвідуваність"
            }
        case "att_daily":
            switch lang {
            case .polish: return "Dzienny"
            case .english: return "Daily"
            case .ukrainian: return "Денний"
            }
        case "att_monthly":
            switch lang {
            case .polish: return "Miesięczny"
            case .english: return "Monthly"
            case .ukrainian: return "Місячний"
            }
        case "att_presence":
            switch lang {
            case .polish: return "Obecny"
            case .english: return "Present"
            case .ukrainian: return "Присутній"
            }
        case "att_absence":
            switch lang {
            case .polish: return "Nieobecny"
            case .english: return "Absent"
            case .ukrainian: return "Відсутній"
            }
        case "att_tardiness":
            switch lang {
            case .polish: return "Spóźnienie"
            case .english: return "Late"
            case .ukrainian: return "Запізнення"
            }
        case "att_excused":
            switch lang {
            case .polish: return "Zwolniony"
            case .english: return "Excused"
            case .ukrainian: return "Звільнений"
            }
            
        // MARK: - More Menu Titles
        case "more_teachers":
            switch lang {
            case .polish: return "Nauczyciele"
            case .english: return "Teachers"
            case .ukrainian: return "Вчителі"
            }
        case "more_exams":
            switch lang {
            case .polish: return "Sprawdziany"
            case .english: return "Exams"
            case .ukrainian: return "Контрольні"
            }
        case "more_homework":
            switch lang {
            case .polish: return "Prace domowe"
            case .english: return "Homework"
            case .ukrainian: return "Домашні завдання"
            }
        case "more_notes":
            switch lang {
            case .polish: return "Uwagi i pochwały"
            case .english: return "Notes & Praise"
            case .ukrainian: return "Зауваження"
            }
        case "more_meetings":
            switch lang {
            case .polish: return "Zebrania"
            case .english: return "Meetings"
            case .ukrainian: return "Збори"
            }
        case "more_duties":
            switch lang {
            case .polish: return "Dyżurni"
            case .english: return "Duties"
            case .ukrainian: return "Чергові"
            }
            
        // MARK: - Settings Sections & Titles
        case "set_title":
            switch lang {
            case .polish: return "Ustawienia"
            case .english: return "Settings"
            case .ukrainian: return "Налаштування"
            }
        case "set_sec_appearance":
            switch lang {
            case .polish: return "WYGLĄD I MOTYW"
            case .english: return "APPEARANCE & THEME"
            case .ukrainian: return "ВИГЛЯД ТА ТЕМА"
            }
        case "set_sec_privacy":
            switch lang {
            case .polish: return "PRYWATNOŚĆ"
            case .english: return "PRIVACY"
            case .ukrainian: return "КОНФІДЕНЦІЙНІСТЬ"
            }
        case "set_sec_grades":
            switch lang {
            case .polish: return "OCENY"
            case .english: return "GRADES"
            case .ukrainian: return "ОЦІНКИ"
            }
        case "set_sec_timetable":
            switch lang {
            case .polish: return "PLAN LEKCJI"
            case .english: return "TIMETABLE"
            case .ukrainian: return "РОЗКЛАД УРОКІВ"
            }
        case "set_sec_attendance":
            switch lang {
            case .polish: return "ZWOLNIENIA I FREKWENCJA"
            case .english: return "ATTENDANCE & EXCUSES"
            case .ukrainian: return "ВІДВІДУВАНІСТЬ"
            }
        case "set_sec_notifications":
            switch lang {
            case .polish: return "POWIADOMIENIA I SYNCHRONIZACJA"
            case .english: return "NOTIFICATIONS & SYNC"
            case .ukrainian: return "СПОБІЩЕННЯ ТА СИНХРОНІЗАЦІЯ"
            }
        case "set_sec_info":
            switch lang {
            case .polish: return "INFORMACJE"
            case .english: return "INFO"
            case .ukrainian: return "ІНФОРМАЦІЯ"
            }
        case "set_language", "settings_language":
            switch lang {
            case .polish: return "Język aplikacji"
            case .english: return "App Language"
            case .ukrainian: return "Мова додатку"
            }
        case "set_theme", "settings_theme":
            switch lang {
            case .polish: return "Motyw aplikacji"
            case .english: return "App Theme"
            case .ukrainian: return "Тема додатку"
            }
        case "set_accent":
            switch lang {
            case .polish: return "Kolor akcentu"
            case .english: return "Accent Color"
            case .ukrainian: return "Колір акценту"
            }
        case "set_start_screen":
            switch lang {
            case .polish: return "Startowy ekran"
            case .english: return "Start Screen"
            case .ukrainian: return "Стартовий екран"
            }
        case "set_logout":
            switch lang {
            case .polish: return "Wyloguj się z Katla"
            case .english: return "Log out of Katla"
            case .ukrainian: return "Вийти з Katla"
            }
            
        default:
            return key
        }
    }
}
