import Foundation
import UserNotifications
import AppKit

public final class RitualAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    public override init() { super.init() }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    // Show banners even while the app is open.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

enum Notifier {
    static func reschedule(_ rituals: [Ritual], period: Period) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let active = rituals.filter { $0.reminderOn }
        guard !active.isEmpty else { return }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            for r in active {
                let t = Cal.cal.dateComponents([.hour, .minute], from: r.reminderTime)
                var d = DateComponents()
                d.hour = t.hour
                d.minute = t.minute
                switch period {
                case .weekly: d.weekday = r.reminderWeekday
                case .monthly: d.day = r.reminderDay
                case .yearly: d.month = r.reminderMonth; d.day = r.reminderDay
                }
                let c = UNMutableNotificationContent()
                c.title = "\(r.emoji) \(r.name)"
                var body = "Time for your \(period.rawValue) ritual. Tick it off to keep your streak!"
                if !r.benefit.isEmpty { body += "\n" + String(r.benefit.prefix(110)) }
                c.body = body
                c.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: d, repeats: true)
                center.add(UNNotificationRequest(identifier: r.id.uuidString, content: c, trigger: trigger))
            }
        }
    }

    static func sendTest() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let c = UNMutableNotificationContent()
            c.title = "🔔 Test reminder"
            c.body = "Notifications are working!"
            c.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            center.add(UNNotificationRequest(identifier: "test", content: c, trigger: trigger))
        }
    }
}
