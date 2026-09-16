import Foundation

/// Local-only timing, based on completed sessions, never on a predicted rating.
/// StoreKit decides whether its prompt is actually shown and reveals no response.
@MainActor
final class ReviewPromptPolicy {
    static let shared = ReviewPromptPolicy()
    static let storageKey = "haneen.reviewTiming.v1"

    private struct State: Codable {
        var firstCompletion: Date?
        var activeDays: [Date] = []
        var currentDay: Date?
        var completionIDsToday: Set<String> = []
        var completedSessions = 0
        var completedSessionsAtLastRequest = 0
        var lastRequestedVersion: String?
        var requestDates: [Date] = []
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private var state: State

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = calendar.timeZone
        self.calendar = localCalendar
        if let data = defaults.data(forKey: Self.storageKey),
           let restored = try? JSONDecoder().decode(State.self, from: data) {
            state = restored
        } else {
            state = State()
        }
    }

    func recordCompletion(id: String, on date: Date = .now) {
        let day = calendar.startOfDay(for: date)
        if state.currentDay != day {
            state.currentDay = day
            state.completionIDsToday = []
        }
        guard state.completionIDsToday.insert(id).inserted else { return }
        state.firstCompletion = state.firstCompletion ?? date
        if !state.activeDays.contains(day) { state.activeDays.append(day) }
        // Only a few recent dates are needed to establish repeat use.
        state.activeDays = Array(state.activeDays.sorted().suffix(14))
        state.completedSessions += 1
        save()
    }

    func isEligible(version: String, on date: Date = .now) -> Bool {
        guard let first = state.firstCompletion,
              date.timeIntervalSince(first) >= 7 * 24 * 60 * 60,
              state.activeDays.count >= 3,
              state.completedSessions - state.completedSessionsAtLastRequest >= 5,
              state.lastRequestedVersion != version else { return false }

        if let last = state.requestDates.max(),
           date.timeIntervalSince(last) < 120 * 24 * 60 * 60 { return false }

        let recentRequests = state.requestDates.filter {
            date.timeIntervalSince($0) < 365 * 24 * 60 * 60
        }
        return recentRequests.count < 3
    }

    /// Record an attempt even when StoreKit elects not to display anything.
    func recordRequest(version: String, on date: Date = .now) {
        state.lastRequestedVersion = version
        state.completedSessionsAtLastRequest = state.completedSessions
        state.requestDates = state.requestDates.filter {
            date.timeIntervalSince($0) < 365 * 24 * 60 * 60
        }
        state.requestDates.append(date)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
