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
    static let appLanguage = "appLanguage"
    static let translationVisible = "translationVisible"
    static let transliterationVisible = "transliterationVisible"
    static let prayerCalculationMethod = "prayerCalculationMethod"
    static let prayerAsrMethod = "prayerAsrMethod"
    static let prayerHighLatitude = "prayerHighLatitude"
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
        let storedID = response.notification.request.content.userInfo["situationID"] as? String
        // Repeating reminders cannot carry a different payload each day, so
        // resolve the daily reading at the moment the person returns.
        let id = storedID ?? SharedStore.situationOfTheDay().id
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
        // The app already shows the daily moment. Avoid interrupting somebody
        // who is actively reading it with a second banner and sound.
        completionHandler([])
    }
}

// MARK: Daily reminder

/// Schedules one durable, quiet daily invitation. A repeating calendar trigger
/// keeps working even when the app has not been launched recently.
enum ReminderScheduler {
    private static let identifier = "yaqeen.daily-guidance"

    static func refresh() {
        let defaults = UserDefaults.standard
        let center = UNUserNotificationCenter.current()
        let legacyIDs = (0..<7).map { "sakinaDaily\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: legacyIDs + [identifier])

        guard defaults.bool(forKey: SettingsKeys.reminderEnabled) else { return }
        let hour = defaults.object(forKey: SettingsKeys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: SettingsKeys.reminderMinute) as? Int ?? 0
        let language = AppLanguage(
            rawValue: defaults.string(forKey: SettingsKeys.appLanguage) ?? AppLanguage.english.rawValue
        ) ?? .english

        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert])) ?? false
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = language.pick("A quiet moment with the Qur’an", "لحظة هادئة مع القرآن")
            content.body = language.pick(
                "Your daily Yaqeen guidance is ready whenever you are.",
                "هداية يقين اليومية بانتظارك متى كنت مستعدًا."
            )
            content.interruptionLevel = .passive
            content.userInfo = ["openDaily": true]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: hour, minute: minute),
                repeats: true
            )
            try? await center.add(UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            ))
        }
    }
}
