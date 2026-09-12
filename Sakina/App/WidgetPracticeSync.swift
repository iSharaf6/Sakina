import Foundation
import WidgetKit

/// Mirrors the reader's existing completion log into the App Group. This never
/// awards completion for merely opening a collection or checking a daily goal.
enum WidgetPracticeSync {
    static func syncLanguage(_ language: AppLanguage) {
        guard SharedStore.widgetLanguage != language else { return }
        SharedStore.widgetLanguage = language
        WidgetCenter.shared.reloadAllTimelines()
    }

    @discardableResult
    static func refresh(on date: Date = .now, calendar: Calendar = .autoupdatingCurrent,
                        appDefaults: UserDefaults = .standard,
                        sharedDefaults: UserDefaults = SharedStore.defaults,
                        reload: () -> Void = { WidgetCenter.shared.reloadAllTimelines() }) -> Bool {
        let raw = appDefaults.string(forKey: PracticeLog.key) ?? ""
        let progress = WidgetPracticeProgress(
            on: date,
            morningComplete: PracticeLog.isDone(.morning, on: date, calendar: calendar, in: raw),
            eveningComplete: PracticeLog.isDone(.evening, on: date, calendar: calendar, in: raw),
            calendar: calendar
        )
        guard SharedStore.savePracticeProgress(progress, in: sharedDefaults) else { return false }
        reload()
        return true
    }
}
