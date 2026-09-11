import WidgetKit
import SwiftUI

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let situation: Situation
}

private func nextMidnight(after date: Date) -> Date {
    let cal = Calendar.current
    return cal.nextDate(
        after: date,
        matching: DateComponents(hour: 0, minute: 0, second: 5),
        matchingPolicy: .nextTime
    ) ?? date.addingTimeInterval(86_400)
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, situation: SharedStore.situationOfTheDay())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, situation: SharedStore.situationOfTheDay()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entry = VerseEntry(date: .now, situation: SharedStore.situationOfTheDay())
        completion(Timeline(entries: [entry], policy: .after(nextMidnight(after: .now))))
    }
}

struct PinnedProvider: TimelineProvider {
    private func current() -> Situation {
        SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay()
    }

    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, situation: current())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, situation: current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entry = VerseEntry(date: .now, situation: current())
        completion(Timeline(entries: [entry], policy: .after(nextMidnight(after: .now))))
    }
}

// MARK: - Prayer timeline

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let schedule: PrayerSchedule?
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerWidgetEntry {
        PrayerWidgetEntry(date: .now, schedule: .placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        let schedule = SharedStore.prayerSchedule ?? (context.isPreview ? .placeholder() : nil)
        completion(PrayerWidgetEntry(date: .now, schedule: schedule))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date.now
        guard let schedule = SharedStore.prayerSchedule else {
            completion(Timeline(
                entries: [PrayerWidgetEntry(date: now, schedule: nil)],
                policy: .never
            ))
            return
        }

        let transitionDates = schedule.allEvents
            .map(\.time)
            .filter { $0 > now && $0 < schedule.expiresAt }
        let dates = [now] + transitionDates
        let entries = dates.map { PrayerWidgetEntry(date: $0, schedule: schedule) }
        let policy: TimelineReloadPolicy = schedule.expiresAt > now
            ? .after(schedule.expiresAt)
            : .never
        completion(Timeline(entries: entries, policy: policy))
    }
}

/// The Lock Screen only has room for three comfortably readable prayer rows in
/// an accessory rectangular widget. Two companion widgets recreate the full
/// six-event schedule: place `early` on the left and `late` on the right.
private enum PrayerWidgetSide {
    case early
    case late

    var kinds: [PrayerKind] {
        switch self {
        case .early:
            return [.fajr, .sunrise, .dhuhr]
        case .late:
            return [.asr, .maghrib, .isha]
        }
    }
}

// MARK: - Shared widget view

struct VerseWidgetView: View {
    let entry: VerseEntry
    let caption: String
    var artwork: CompanionArtwork = .quran
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VerseCompanionCard(situation: entry.situation, caption: caption,
                           compact: family == .systemSmall, artwork: artwork)
            .containerBackground(CompanionWidgetPalette.canvas, for: .widget)
            .widgetURL(URL(string: "sakina://situation/\(entry.situation.id)"))
    }
}

// MARK: - Prayer widget view

struct PrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale

    private var nextEvent: PrayerEvent? {
        entry.schedule?.nextEvent(after: entry.date)
    }

    private var followingEvent: PrayerEvent? {
        entry.schedule?.followingEvent(after: entry.date)
    }

    var body: some View {
        Group {
            if let schedule = entry.schedule, !schedule.isStale(at: entry.date) {
                switch family {
                case .accessoryInline:
                    inline(schedule)
                case .accessoryCircular:
                    circular(schedule)
                case .accessoryRectangular:
                    rectangular(schedule)
                default:
                    medium(schedule)
                }
            } else {
                unavailable
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemMedium {
                CompanionWidgetPalette.canvas
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "sakina://prayer-times"))
    }

    private func inline(_ schedule: PrayerSchedule) -> some View {
        Group {
            if let nextEvent {
                Label(
                    "\(nextEvent.kind.displayName(locale: locale)) \(timeLabel(nextEvent.time, schedule: schedule))",
                    systemImage: nextEvent.kind.symbolName
                )
            } else {
                Label("Open Haneen for prayer times", systemImage: "location")
            }
        }
    }

    private func circular(_ schedule: PrayerSchedule) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            if let nextEvent {
                VStack(spacing: 1) {
                    Image(systemName: nextEvent.kind.symbolName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(nextEvent.kind.displayName(locale: locale))
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                    Text(timeLabel(nextEvent.time, schedule: schedule))
                        .font(.system(size: 10, weight: .bold))
                        .minimumScaleFactor(0.72)
                        .monospacedDigit()
                }
                .padding(3)
            } else {
                Image(systemName: "location")
            }
        }
    }

    private func rectangular(_ schedule: PrayerSchedule) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(schedule.locationLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 2)
                Image(systemName: "location.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            if let nextEvent {
                HStack(alignment: .firstTextBaseline) {
                    Text(nextEvent.kind.displayName(locale: locale))
                        .font(.system(size: 16, weight: .bold))
                    Spacer(minLength: 6)
                    Text(timeLabel(nextEvent.time, schedule: schedule))
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                }
                if let followingEvent {
                    Text("Then \(followingEvent.kind.displayName(locale: locale)) · \(timeLabel(followingEvent.time, schedule: schedule))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func medium(_ schedule: PrayerSchedule) -> some View {
        PrayerCompanionCard(schedule: schedule, date: entry.date)
    }

    private var unavailable: some View {
        Group {
            switch family {
            case .accessoryInline:
                Label("Open Haneen to set prayer times", systemImage: "location")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "location")
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text("Prayer times")
                        .font(.headline)
                    Text("Open Haneen to choose your location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            default:
                PrayerCompanionCard(schedule: nil, date: entry.date)
            }
        }
    }

    private func timeLabel(_ date: Date, schedule: PrayerSchedule) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = schedule.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }
}

/// A compact three-row schedule designed specifically for the Lock Screen.
/// WidgetKit renders accessory widgets with the user's selected Lock Screen
/// tint, so the view intentionally uses semantic primary/secondary styles.
private struct PrayerScheduleHalfView: View {
    let entry: PrayerWidgetEntry
    let side: PrayerWidgetSide

    @Environment(\.locale) private var locale

    private var nextEvent: PrayerEvent? {
        entry.schedule?.nextEvent(after: entry.date)
    }

    var body: some View {
        Group {
            if let schedule = entry.schedule,
               !schedule.isStale(at: entry.date),
               !events(in: schedule).isEmpty {
                prayerRows(events(in: schedule), schedule: schedule)
            } else {
                unavailable
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
        .widgetURL(URL(string: "sakina://prayer-times"))
    }

    private func prayerRows(_ events: [PrayerEvent], schedule: PrayerSchedule) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(events) { event in
                HStack(spacing: 5) {
                    prayerMarker(isNext: event.id == nextEvent?.id)

                    Text(event.kind.displayName(locale: locale))
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 3)

                    Text(timeLabel(event.time, schedule: schedule))
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func prayerMarker(isNext: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 1.25)
            if isNext {
                Circle()
                    .fill()
            }
        }
        .frame(width: 8, height: 8)
        .accessibilityHidden(true)
    }

    private func events(in schedule: PrayerSchedule) -> [PrayerEvent] {
        // After Isha, advance both halves together to tomorrow's schedule.
        let scheduleDate = schedule.nextEvent(after: entry.date)?.time ?? entry.date
        let dayEvents = schedule.events(on: scheduleDate)
        return side.kinds.compactMap { kind in
            dayEvents.first { $0.kind == kind }
        }
    }

    private var unavailable: some View {
        HStack(spacing: 7) {
            Image(systemName: "location.circle")
                .font(.system(size: 20, weight: .medium))
            VStack(alignment: .leading, spacing: 2) {
                Text("Prayer times")
                    .font(.system(size: 12, weight: .semibold))
                Text("Open Haneen to set your location")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func timeLabel(_ date: Date, schedule: PrayerSchedule) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = schedule.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }
}

// MARK: - Widgets

struct VerseOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaVerseOfDay", provider: DailyProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Ayah of the day")
        }
        .configurationDisplayName("Ayah of the Day")
        .description("A daily ayah from Haneen, refreshed each morning.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaPinned", provider: PinnedProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Reflecting on", artwork: .praise)
        }
        .configurationDisplayName("Pinned Situation")
        .description("Keep a saved ayah on your Home Screen. Pin one from any guidance page in Haneen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PrayerTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PrayerSchedule.widgetKind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("See the next prayer on your Lock Screen or today's full schedule on your Home Screen.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
            .systemMedium,
        ])
    }
}

struct EarlyPrayerTimesWidget: Widget {
    static let kind = "YaqeenPrayerTimesEarly"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerProvider()) { entry in
            PrayerScheduleHalfView(entry: entry, side: .early)
        }
        .configurationDisplayName("Prayer Times · Fajr–Dhuhr")
        .description("Place this widget on the left of your Lock Screen for Fajr, Sunrise and Dhuhr.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LatePrayerTimesWidget: Widget {
    static let kind = "YaqeenPrayerTimesLate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerProvider()) { entry in
            PrayerScheduleHalfView(entry: entry, side: .late)
        }
        .configurationDisplayName("Prayer Times · Asr–Isha")
        .description("Place this widget on the right of your Lock Screen for Asr, Maghrib and Isha.")
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct SakinaWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseOfDayWidget()
        PinnedVerseWidget()
        PrayerTimesWidget()
        EarlyPrayerTimesWidget()
        LatePrayerTimesWidget()
        ExtraCompanionWidget(choice: .prayerCat)
        ExtraCompanionWidget(choice: .countdown)
        ExtraCompanionWidget(choice: .morning)
        ExtraCompanionWidget(choice: .evening)
        ExtraCompanionWidget(choice: .pause)
    }
}

#Preview("Fajr–Dhuhr Lock Screen", as: .accessoryRectangular) {
    EarlyPrayerTimesWidget()
} timeline: {
    PrayerWidgetEntry(date: .now, schedule: .placeholder())
}

#Preview("Asr–Isha Lock Screen", as: .accessoryRectangular) {
    LatePrayerTimesWidget()
} timeline: {
    PrayerWidgetEntry(date: .now, schedule: .placeholder())
}

struct ExtraCompanionWidget: Widget {
    let choice: CompanionWidgetChoice
    init() { choice = .prayerCat }
    init(choice: CompanionWidgetChoice) { self.choice = choice }
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YaqeenCompanion.\(choice.rawValue)", provider: PrayerProvider()) { entry in
            ExtraCompanionWidgetView(choice: choice, entry: entry)
        }
        .configurationDisplayName(choice.title)
        .description(choice.detail)
        .supportedFamilies(choice == .prayerCat ? [.systemSmall, .systemMedium, .accessoryRectangular] : [.systemSmall, .systemMedium])
    }
}

struct ExtraCompanionWidgetView: View {
    let choice: CompanionWidgetChoice
    let entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        CompanionCollectionCard(choice: choice, date: entry.date, schedule: entry.schedule,
                                compact: family == .systemSmall, lockScreen: family == .accessoryRectangular)
            .containerBackground(CompanionWidgetPalette.canvas, for: .widget)
            .widgetURL(choice.destination)
    }
}
