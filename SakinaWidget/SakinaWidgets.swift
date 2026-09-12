import WidgetKit
import SwiftUI

private func widgetLanguage(for locale: Locale = .current) -> AppLanguage {
    SharedStore.widgetLanguage ?? (locale.language.languageCode?.identifier == "ar" ? .arabic : .english)
}

private extension View {
    /// Set once at each WidgetKit entry root. The app's gallery remains free
    /// to preview a different language through its own locale environment.
    func haneenWidgetLanguage() -> some View {
        environment(\.locale, SharedStore.widgetLanguage?.locale ?? Locale.current)
            .environment(\.layoutDirection, widgetLanguage().layoutDirection)
    }
}

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let situation: Situation
}

/// Predictable changes are supplied as future entries, so midnight updates do
/// not depend on WidgetKit granting a fresh extension run at that exact time.
private enum WidgetTimelinePlan {
    static func dayDates(from now: Date, days: Int = 7, calendar: Calendar = Calendar(identifier: .gregorian)) -> [Date] {
        let start = calendar.startOfDay(for: now)
        return [now] + (1...max(1, days)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    static func prayerDates(from now: Date, schedule: PrayerSchedule?) -> [Date] {
        var dates = dayDates(from: now)
        let end = dates.last ?? now
        guard let schedule, schedule.schemaVersion == PrayerSchedule.currentSchemaVersion else { return dates }
        // Solar instants and the saved city's date boundaries may differ from
        // the phone's local midnight when a manually selected city is used.
        dates += schedule.allEvents.map(\.time).filter { $0 > now && $0 <= end && $0 <= schedule.expiresAt }
        dates += schedule.days.map(\.dayStart).filter { $0 > now && $0 <= end && $0 < schedule.expiresAt }
        // Include expiry itself. A reload request alone could leave an old
        // rendered prayer time visible if the system delays the next reload.
        if schedule.expiresAt > now && schedule.expiresAt <= end { dates.append(schedule.expiresAt) }
        return Array(Set(dates)).sorted()
    }
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, situation: SharedStore.situationOfTheDay())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let now = Date.now
        completion(VerseEntry(date: now, situation: SharedStore.situationOfTheDay(for: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let dates = WidgetTimelinePlan.dayDates(from: .now)
        let entries = dates.map { VerseEntry(date: $0, situation: SharedStore.situationOfTheDay(for: $0)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct PinnedProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, situation: SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let now = Date.now
        completion(VerseEntry(date: now, situation: SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay(for: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let now = Date.now
        if let pinned = SharedStore.pinnedSituation {
            // Changing the pin in Haneen explicitly reloads the widget.
            completion(Timeline(entries: [VerseEntry(date: now, situation: pinned)], policy: .never))
        } else {
            let entries = WidgetTimelinePlan.dayDates(from: now).map {
                VerseEntry(date: $0, situation: SharedStore.situationOfTheDay(for: $0))
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}

// MARK: - Prayer timeline

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let schedule: PrayerSchedule?
}

struct PrayerProvider: TimelineProvider {
    var includesPrayerEvents = true

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        let now = Date.now
        return PrayerWidgetEntry(date: now, schedule: .placeholder(now: now))
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        let now = Date.now
        let schedule = SharedStore.prayerSchedule ?? (context.isPreview ? .placeholder(now: now) : nil)
        completion(PrayerWidgetEntry(date: now, schedule: schedule))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date.now
        let schedule = SharedStore.prayerSchedule
        let dates = includesPrayerEvents
            ? WidgetTimelinePlan.prayerDates(from: now, schedule: schedule)
            : WidgetTimelinePlan.dayDates(from: now)
        let entries = dates.map { PrayerWidgetEntry(date: $0, schedule: schedule) }
        // Morning/evening completion is scoped to the entry's local day, even
        // for people who haven't configured prayer times. App progress changes
        // also trigger WidgetCenter reloads; no minute-by-minute polling is used.
        completion(Timeline(entries: entries, policy: .atEnd))
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
    let captionArabic: String
    @Environment(\.locale) private var locale
    var artwork: CompanionArtwork = .quran
    var choice: CompanionWidgetChoice = .daily
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VerseCompanionCard(situation: entry.situation, caption: widgetLanguage(for: locale).pick(caption, captionArabic),
                           compact: family == .systemSmall, artwork: artwork)
            .containerBackground(CompanionWidgetPalette.background(for: choice), for: .widget)
            .widgetURL(URL(string: "haneen://situation/\(entry.situation.id)"))
    }
}

// MARK: - Prayer widget view

struct PrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale
    private var language: AppLanguage { widgetLanguage(for: locale) }
    private var unavailablePrompt: String {
        entry.schedule == nil
            ? language.pick("Open Haneen to choose your location", "افتح حنين لتحديد موقعك")
            : language.pick("Open Haneen to refresh prayer times", "افتح حنين لتحديث مواقيت الصلاة")
    }

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
                CompanionWidgetPalette.background(for: .timetable)
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "haneen://prayer-times"))
    }

    private func inline(_ schedule: PrayerSchedule) -> some View {
        Group {
            if let nextEvent {
                Label(
                    "\(nextEvent.kind.displayName(locale: locale)) \(timeLabel(nextEvent.time, schedule: schedule))",
                    systemImage: nextEvent.kind.symbolName
                )
            } else {
                Label(language.pick("Open Haneen for prayer times", "افتح حنين لعرض مواقيت الصلاة"), systemImage: "location")
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
                    Text("\(language.pick("Then", "ثم")) \(followingEvent.kind.displayName(locale: locale))\(language.listSeparator)\(timeLabel(followingEvent.time, schedule: schedule))")
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
                Label(unavailablePrompt, systemImage: "location")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "location")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(unavailablePrompt)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.pick("Prayer times", "مواقيت الصلاة"))
                        .font(.headline)
                    Text(unavailablePrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            default:
                PrayerCompanionCard(schedule: entry.schedule, date: entry.date)
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
    private var language: AppLanguage { widgetLanguage(for: locale) }
    private var unavailablePrompt: String {
        entry.schedule == nil
            ? language.pick("Open Haneen to choose your location", "افتح حنين لتحديد موقعك")
            : language.pick("Open Haneen to refresh prayer times", "افتح حنين لتحديث مواقيت الصلاة")
    }

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
        .widgetURL(URL(string: "haneen://prayer-times"))
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
                Text(language.pick("Prayer times", "مواقيت الصلاة"))
                    .font(.system(size: 12, weight: .semibold))
                Text(unavailablePrompt)
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
            VerseWidgetView(entry: entry, caption: "Ayah of the day", captionArabic: "آية اليوم")
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(widgetLanguage().pick("Ayah of the Day", "آية اليوم"))
        .description(widgetLanguage().pick("A daily ayah from Haneen, refreshed each morning.", "آية من حنين تتجدد كل صباح."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaPinned", provider: PinnedProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Reflecting on", captionArabic: "آية للتأمل", artwork: .saved, choice: .pinned)
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(widgetLanguage().pick("Pinned Situation", "موقف مثبّت"))
        .description(widgetLanguage().pick("Keep a saved ayah on your Home Screen. Pin one from any guidance page in Haneen.", "احتفظ بآية على شاشتك الرئيسية، وثبّتها من إحدى صفحات الإرشاد في حنين."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PrayerTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PrayerSchedule.widgetKind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(widgetLanguage().pick("Prayer Times", "مواقيت الصلاة"))
        .description(widgetLanguage().pick("See the next prayer on your Lock Screen or today's full schedule on your Home Screen.", "اعرض موعد الصلاة القادمة على شاشة القفل، أو مواقيت اليوم كاملة على الشاشة الرئيسية."))
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
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(widgetLanguage().pick("Prayer Times, Fajr–Dhuhr", "مواقيت الصلاة، من الفجر إلى الظهر"))
        .description(widgetLanguage().pick("Place this widget on the left of your Lock Screen for Fajr, Sunrise and Dhuhr.", "ضع هذه الأداة على يسار شاشة القفل لعرض مواقيت الفجر والشروق والظهر."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LatePrayerTimesWidget: Widget {
    static let kind = "YaqeenPrayerTimesLate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerProvider()) { entry in
            PrayerScheduleHalfView(entry: entry, side: .late)
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(widgetLanguage().pick("Prayer Times, Asr–Isha", "مواقيت الصلاة، من العصر إلى العشاء"))
        .description(widgetLanguage().pick("Place this widget on the right of your Lock Screen for Asr, Maghrib and Isha.", "ضع هذه الأداة على يمين شاشة القفل لعرض مواقيت العصر والمغرب والعشاء."))
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
        StaticConfiguration(kind: "YaqeenCompanion.\(choice.rawValue)", provider: PrayerProvider(includesPrayerEvents: choice == .prayerCat || choice == .countdown)) { entry in
            ExtraCompanionWidgetView(choice: choice, entry: entry)
                .haneenWidgetLanguage()
        }
        .configurationDisplayName(choice.title(widgetLanguage()))
        .description(choice.detail(widgetLanguage()))
        .supportedFamilies(choice == .prayerCat ? [.systemSmall, .systemMedium, .accessoryRectangular] : [.systemSmall, .systemMedium])
    }
}

struct ExtraCompanionWidgetView: View {
    let choice: CompanionWidgetChoice
    let entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) private var family
    private var destination: URL {
        // Open the verse represented by this rendered timeline entry, even if
        // a cached Quiet Moment remains visible across a date change.
        if choice == .pause {
            let situation = SharedStore.situationOfTheDay(for: entry.date)
            return URL(string: "haneen://situation/\(situation.id)")!
        }
        return choice.destination
    }

    var body: some View {
        CompanionCollectionCard(choice: choice, date: entry.date, schedule: entry.schedule,
                                compact: family == .systemSmall, lockScreen: family == .accessoryRectangular)
            .containerBackground(for: .widget) {
                if family == .accessoryRectangular { Color.clear }
                else { CompanionWidgetPalette.background(for: choice) }
            }
            .widgetURL(destination)
    }
}
