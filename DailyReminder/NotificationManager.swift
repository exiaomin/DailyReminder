import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyNotificationIdentifier = "dailyReminder"

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func scheduleEveningNotification(items: [ReminderItem]) {
        // Remove existing notification first
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyNotificationIdentifier])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "每日提醒"

        if items.isEmpty {
            content.body = "今日任务已全部完成！"
        } else {
            let itemNames = items.map { $0.name }.joined(separator: "、")
            content.body = "今日待办: \(itemNames)"
        }

        content.sound = .default

        // Schedule for 21:30 every day
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}