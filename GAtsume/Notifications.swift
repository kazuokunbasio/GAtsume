import Foundation
import UserNotifications

enum Notifications {
    private static let dailyId = "daily_reminder"

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleDaily() {
        cancelDaily()
        let content = UNMutableNotificationContent()
        content.title = "ゴキあつめ"
        content.body = "今日のゴキたちが集まってる頃。"
        content.sound = .default

        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelDaily() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyId]
        )
    }
}
