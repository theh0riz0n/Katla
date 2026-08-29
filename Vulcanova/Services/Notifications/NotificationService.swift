//
//  NotificationService.swift
//  Katla
//

import Foundation
import UserNotifications
import SwiftUI

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Requests notification permissions from user
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            print("[NotificationService] 🔔 Permission granted: \(granted)")
            return granted
        } catch {
            print("[NotificationService] ❌ Authorization error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Triggers immediate local notification
    public func scheduleNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] ❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("[NotificationService] 🚀 Notification scheduled: '\(title)'")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Including .list ensures the notification stays in the iOS Notification Center panel!
        completionHandler([.banner, .list, .sound, .badge])
    }
}
