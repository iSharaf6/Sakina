import Foundation

/// Completion recorded by the reader, scoped to a local calendar day. A reading
/// bookmark, an open collection, or a goal checkbox is not completion evidence.
struct WidgetPracticeProgress: Codable, Equatable {
    private let day: String
    let morningComplete: Bool
    let eveningComplete: Bool

    var completedCount: Int { (morningComplete ? 1 : 0) + (eveningComplete ? 1 : 0) }

    init(on date: Date = .now, morningComplete: Bool = false, eveningComplete: Bool = false,
         calendar: Calendar = .autoupdatingCurrent) {
        day = Self.dayKey(for: date, calendar: calendar)
        self.morningComplete = morningComplete
        self.eveningComplete = eveningComplete
    }

    /// Timeline entries must resolve against their own date, so a completed
    /// collection never appears completed on tomorrow's widget.
    func current(on date: Date, calendar: Calendar = .autoupdatingCurrent) -> Self {
        guard day == Self.dayKey(for: date, calendar: calendar) else {
            return Self(on: date, calendar: calendar)
        }
        return self
    }

    /// PracticeLog uses a Gregorian local date even when the user's preferred
    /// display calendar is Hijri. Both app and extension use the same rule.
    static func dayKey(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
