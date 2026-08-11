import WidgetKit
import SwiftUI

// MARK: - Widget palette (self-contained; the widget target does not compile the app theme)

private extension Color {
    static let widgetInk = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let widgetMuted = Color(red: 0.72, green: 0.79, blue: 0.75)
    static let widgetGold = Color(red: 0.84, green: 0.72, blue: 0.48)
    static let widgetCanvasTop = Color(red: 0.08, green: 0.25, blue: 0.21)
    static let widgetCanvasBottom = Color(red: 0.035, green: 0.14, blue: 0.12)
}

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

    @Environment(\.widgetFamily) private var family

    private var verse: Verse? { entry.situation.primaryVerse }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [.widgetCanvasTop, .widgetCanvasBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .overlay(
                    RadialGradient(
                        colors: [Color.widgetGold.opacity(0.16), .clear],
                        center: UnitPoint(x: 0.9, y: -0.1),
                        startRadius: 4, endRadius: 180
                    )
                )
            }
            .widgetURL(URL(string: "sakina://situation/\(entry.situation.id)"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                header
                Spacer(minLength: 0)
                Text(entry.situation.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.widgetInk)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                reference
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                header
                if let verse {
                    Text(verse.arabic)
                        .font(.custom("KFGQPC HAFS Uthmanic Script", size: 17))
                        .foregroundStyle(Color.widgetInk)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .lineSpacing(5)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    Text(entry.situation.title)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.widgetInk)
                        .lineLimit(2)
                    Spacer()
                    reference
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(caption.uppercased())
                .font(.system(size: 8.5, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Color.widgetGold)
            Spacer()
            SmallStar()
                .fill(Color.widgetGold.opacity(0.85))
                .frame(width: 8, height: 8)
        }
    }

    private var reference: some View {
        Text(entry.situation.referenceLabel.uppercased())
            .font(.system(size: 8.5, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(Color.widgetMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
                LinearGradient(
                    colors: [.widgetCanvasTop, .widgetCanvasBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RadialGradient(
                        colors: [Color.widgetGold.opacity(0.18), .clear],
                        center: UnitPoint(x: 0.92, y: 0.02),
                        startRadius: 2,
                        endRadius: 190
                    )
                )
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
                Label("Open Yaqeen for prayer times", systemImage: "location")
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
                        .font(.system(size: 10, weight: .bold, design: .rounded))
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
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Spacer(minLength: 6)
                    Text(timeLabel(nextEvent.time, schedule: schedule))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
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
        let events = schedule.events(on: nextEvent?.time ?? entry.date)
        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YAQEEN")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2.2)
                        .foregroundStyle(Color.widgetGold)
                    Text(schedule.locationLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.widgetMuted)
                        .lineLimit(1)
                }
                Spacer()
                if let nextEvent {
                    HStack(spacing: 6) {
                        Image(systemName: nextEvent.kind.symbolName)
                            .font(.system(size: 11, weight: .semibold))
                        Text(nextEvent.kind.displayName(locale: locale))
                            .font(.system(size: 12, weight: .semibold))
                        Text(timeLabel(nextEvent.time, schedule: schedule))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color.widgetInk)
                }
            }

            Grid(horizontalSpacing: 8, verticalSpacing: 7) {
                ForEach(0..<2, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if events.indices.contains(index) {
                                prayerCell(events[index], schedule: schedule)
                            }
                        }
                    }
                }
            }
        }
        .foregroundStyle(Color.widgetInk)
    }

    private func prayerCell(_ event: PrayerEvent, schedule: PrayerSchedule) -> some View {
        let isNext = event.id == nextEvent?.id
        return HStack(spacing: 5) {
            Image(systemName: event.kind.symbolName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isNext ? Color.widgetGold : Color.widgetMuted)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.kind.displayName(locale: locale))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isNext ? Color.widgetInk : Color.widgetMuted)
                    .lineLimit(1)
                Text(timeLabel(event.time, schedule: schedule))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.widgetInk)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isNext ? Color.widgetGold.opacity(0.13) : Color.white.opacity(0.035))
        )
    }

    private var unavailable: some View {
        Group {
            switch family {
            case .accessoryInline:
                Label("Open Yaqeen to set prayer times", systemImage: "location")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "location")
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text("Prayer times")
                        .font(.headline)
                    Text("Open Yaqeen to choose your location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            default:
                HStack(spacing: 14) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.widgetGold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prayer times")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.widgetInk)
                        Text("Open Yaqeen to choose your location")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.widgetMuted)
                    }
                }
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
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 3)

                    Text(timeLabel(event.time, schedule: schedule))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text("Open Yaqeen to set your location")
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

/// Khatam star, duplicated locally so the widget stays independent of the app theme.
struct SmallStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<2 {
            let rotation = CGFloat(i) * .pi / 4
            var square = Path()
            for j in 0..<4 {
                let angle = rotation + CGFloat(j) * .pi / 2
                let point = CGPoint(x: center.x + radius * cos(angle),
                                    y: center.y + radius * sin(angle))
                if j == 0 { square.move(to: point) } else { square.addLine(to: point) }
            }
            square.closeSubpath()
            path.addPath(square)
        }
        return path
    }
}

// MARK: - Widgets

struct VerseOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaVerseOfDay", provider: DailyProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Ayah of the day")
        }
        .configurationDisplayName("Ayah of the Day")
        .description("A daily ayah from Yaqeen, refreshed each morning.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaPinned", provider: PinnedProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Reflecting on")
        }
        .configurationDisplayName("Pinned Situation")
        .description("Keep a saved ayah on your Home Screen. Pin one from any guidance page in Yaqeen.")
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
