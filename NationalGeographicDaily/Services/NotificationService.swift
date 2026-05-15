import UserNotifications

actor NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private let notificationID = "com.natgeodaily.daily"

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func scheduleDailyNotification(hour: Int, minute: Int) async {
        cancelPending()

        let content = UNMutableNotificationContent()
        content.title = "National Geographic Photo of the Day"
        content.body = "Today's photo is ready to view."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDailyNotification() {
        cancelPending()
    }

    private func cancelPending() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
