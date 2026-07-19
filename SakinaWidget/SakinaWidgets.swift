import WidgetKit
import SwiftUI

// MARK: - Widget palette (self-contained; the widget target does not compile the app theme)

private extension Color {
    static let widgetInk = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let widgetMuted = Color(red: 0.58, green: 0.61, blue: 0.68)
    static let widgetGold = Color(red: 0.85, green: 0.70, blue: 0.42)
    static let widgetCanvasTop = Color(red: 0.06, green: 0.08, blue: 0.13)
    static let widgetCanvasBottom = Color(red: 0.03, green: 0.045, blue: 0.08)
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
        .description("A daily verse for the heart, refreshed each morning.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaPinned", provider: PinnedProvider()) { entry in
            VerseWidgetView(entry: entry, caption: "Working through")
        }
        .configurationDisplayName("Pinned Situation")
        .description("Keep the verse you are working through on your home screen. Pin one from any verse page in Sakina.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SakinaWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseOfDayWidget()
        PinnedVerseWidget()
    }
}
