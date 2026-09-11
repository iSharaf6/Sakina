import AppIntents
import Foundation

/// A tiny handoff surface shared by App Intents and the root tab router.
/// Intents write only a destination token; all navigation remains in SwiftUI.
enum YaqeenIntentDestination: String, Sendable {
    case today
    case qibla

    private static let pendingKey = "yaqeen.pending-intent-destination"

    @MainActor
    static func request(_ destination: YaqeenIntentDestination) {
        UserDefaults.standard.set(destination.rawValue, forKey: pendingKey)
    }

    @MainActor
    static func consume() -> YaqeenIntentDestination? {
        let defaults = UserDefaults.standard
        guard let rawValue = defaults.string(forKey: pendingKey) else { return nil }
        defaults.removeObject(forKey: pendingKey)
        return YaqeenIntentDestination(rawValue: rawValue)
    }
}

struct OpenTodayInYaqeenIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today in Haneen"
    static let description = IntentDescription("Open today’s Qur’anic guidance in Haneen.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        YaqeenIntentDestination.request(.today)
        return .result(dialog: "Opening today’s guidance.")
    }
}

struct OpenQiblaInYaqeenIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Qibla in Haneen"
    static let description = IntentDescription("Open Haneen’s private Qibla compass.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        YaqeenIntentDestination.request(.qibla)
        return .result(dialog: "Opening the Qibla compass.")
    }
}

struct NextPrayerInYaqeenIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Prayer in Haneen"
    static let description = IntentDescription("Hear the next calculated prayer and its local time.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date.now
        guard let schedule = SharedStore.prayerSchedule,
              !schedule.isStale(at: now),
              let event = schedule.nextEvent(after: now) else {
            return .result(dialog: "Open Haneen and set your prayer location first.")
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = schedule.timeZone
        formatter.timeStyle = .short
        let time = formatter.string(from: event.time)

        return .result(dialog: "The next prayer is \(event.kind.englishName) at \(time).")
    }
}

struct YaqeenAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayInYaqeenIntent(),
            phrases: [
                "Open today’s guidance in \(.applicationName)",
                "Open today’s \(.applicationName)",
            ],
            shortTitle: "Today’s guidance",
            systemImageName: "book.pages"
        )

        AppShortcut(
            intent: OpenQiblaInYaqeenIntent(),
            phrases: [
                "Find Qibla with \(.applicationName)",
                "Open Qibla in \(.applicationName)",
            ],
            shortTitle: "Find Qibla",
            systemImageName: "location.north.circle"
        )

        AppShortcut(
            intent: NextPrayerInYaqeenIntent(),
            phrases: [
                "What is the next prayer in \(.applicationName)",
                "Ask \(.applicationName) for the next prayer",
            ],
            shortTitle: "Next prayer",
            systemImageName: "clock"
        )
    }
}
