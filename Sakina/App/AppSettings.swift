import Foundation
import UserNotifications

// MARK: Reciters

enum Reciter: String, CaseIterable, Identifiable {
    case alafasy = "Alafasy_128kbps"
    case husary = "Husary_128kbps"
    case abdulBasit = "Abdul_Basit_Murattal_192kbps"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alafasy: return "Mishary Rashid Alafasy"
        case .husary: return "Mahmoud Khalil Al Husary"
        case .abdulBasit: return "Abdul Basit Abdus Samad"
        }
    }
}

// MARK: Settings keys

enum SettingsKeys {
    static let reciter = "reciterFolder"
    static let arabicScale = "arabicScale"
    static let reminderEnabled = "reminderEnabled"
    static let reminderHour = "reminderHour"
    static let reminderMinute = "reminderMinute"
}

// MARK: Notification routing

/// Receives notification taps and publishes the situation to open.
final class NotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    @Published var pendingSituationID: String?

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.content.userInfo["situationID"] as? String
        Task { @MainActor in
            self.pendingSituationID = id
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: Daily reminder

/// Schedules the next seven daily notifications, each carrying that date's
/// ayah of the day. Called on launch and whenever the setting changes.
enum ReminderScheduler {
    static func refresh() {
        let defaults = UserDefaults.standard
        let center = UNUserNotificationCenter.current()
        let ids = (0..<7).map { "sakinaDaily\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard defaults.bool(forKey: SettingsKeys.reminderEnabled) else { return }
        let hour = defaults.object(forKey: SettingsKeys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: SettingsKeys.reminderMinute) as? Int ?? 0

        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }

            let cal = Calendar.current
            for offset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: offset, to: .now) else { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: day)
                comps.hour = hour
                comps.minute = minute
                guard let fireDate = cal.date(from: comps), fireDate > .now else { continue }

                let situation = SharedStore.situationOfTheDay(for: day)
                let content = UNMutableNotificationContent()
                content.title = "Ayah of the day"
                content.body = "\(situation.title). \(situation.referenceLabel)"
                content.sound = .default
                content.userInfo = ["situationID": situation.id]

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                    repeats: false
                )
                try? await center.add(UNNotificationRequest(
                    identifier: "sakinaDaily\(offset)", content: content, trigger: trigger
                ))
            }
        }
    }
}
