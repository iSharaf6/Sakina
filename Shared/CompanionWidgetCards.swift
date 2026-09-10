import SwiftUI

/// Shared with the app's debug gallery so screenshots exercise the actual widget layouts.
enum CompanionWidgetPalette {
    static let canvas = adaptive(0xFFFFFF, 0x151A17)
    static let ink = adaptive(0x101714, 0xF2F5F3)
    static let secondary = adaptive(0x616B66, 0xA2ACA6)
    static let accent = adaptive(0x15803D, 0x4ADE80)
    static let line = adaptive(0xE6EAE8, 0x2B332E)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

struct VerseCompanionCard: View {
    let situation: Situation
    let caption: String
    let compact: Bool
    var artwork: CompanionArtwork = .quran

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 2) {
                        Text(caption)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CompanionWidgetPalette.secondary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        CompanionIllustration(artwork: artwork, size: 58)
                    }
                    Spacer(minLength: 0)
                    title(size: 16)
                    reference
                }
            } else {
                HStack(spacing: 14) {
                    VStack(spacing: 6) {
                        CompanionIllustration(artwork: artwork, size: 78)
                        Text("Yaqeen")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CompanionWidgetPalette.accent)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(caption)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CompanionWidgetPalette.secondary)
                        if let verse = situation.primaryVerse {
                            Text(verse.arabic)
                                .font(.custom("KFGQPC HAFS Uthmanic Script", size: 18))
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        Spacer(minLength: 0)
                        title(size: 13)
                        reference
                    }
                }
            }
        }
        .foregroundStyle(CompanionWidgetPalette.ink)
    }

    private func title(size: CGFloat) -> some View {
        Text(situation.title)
            .font(.system(size: size, weight: .semibold))
            .lineLimit(compact ? 3 : 2)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var reference: some View {
        Text(situation.referenceLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(CompanionWidgetPalette.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct PrayerCompanionCard: View {
    let schedule: PrayerSchedule?
    let date: Date
    @Environment(\.locale) private var locale

    private var next: PrayerEvent? { schedule?.nextEvent(after: date) }
    private var isArabic: Bool { locale.language.languageCode?.identifier == "ar" }

    var body: some View {
        Group {
            if let schedule, !schedule.isStale(at: date), let next {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        CompanionIllustration(artwork: next.kind.artwork, size: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isArabic ? "التالي · \(next.kind.displayName(locale: locale))" : "Next · \(next.kind.displayName(locale: locale))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(CompanionWidgetPalette.accent)
                                .lineLimit(1)
                            Text(timeLabel(next.time, schedule: schedule))
                                .font(.system(size: 23, weight: .semibold))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 4)
                        Text(schedule.locationLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CompanionWidgetPalette.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 88, alignment: .trailing)
                    }
                    Rectangle().fill(CompanionWidgetPalette.line).frame(height: 0.5)
                    let events = schedule.events(on: next.time)
                    Grid(horizontalSpacing: 8, verticalSpacing: 6) {
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
            } else {
                HStack(spacing: 16) {
                    CompanionIllustration(artwork: .lost, size: 84)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(isArabic ? "مواقيت الصلاة" : "Prayer times")
                            .font(.system(size: 17, weight: .semibold))
                        Text(isArabic ? "افتح يقين لاختيار موقعك" : "Open Yaqeen to choose your location.")
                            .font(.system(size: 12))
                            .foregroundStyle(CompanionWidgetPalette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .foregroundStyle(CompanionWidgetPalette.ink)
    }

    private func prayerCell(_ event: PrayerEvent, schedule: PrayerSchedule) -> some View {
        HStack(spacing: 4) {
            CompanionIllustration(artwork: event.kind.artwork, size: 27)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.kind.displayName(locale: locale))
                    .font(.system(size: 10, weight: event.id == next?.id ? .bold : .medium))
                    .foregroundStyle(event.id == next?.id ? CompanionWidgetPalette.accent : CompanionWidgetPalette.secondary)
                Text(timeLabel(event.time, schedule: schedule))
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func timeLabel(_ date: Date, schedule: PrayerSchedule) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = schedule.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }
}
