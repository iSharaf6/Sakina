import SwiftUI
import WidgetKit

/// Shared with the app's gallery, so previews use the actual widget layouts.
enum CompanionWidgetPalette {
    static let canvas = adaptive(0xF3F5EF, 0x202B25)
    static let paper = adaptive(0xFBF3E3, 0x302B23)
    static let dusk = adaptive(0xEEEAF5, 0x2C2938)
    static let ink = adaptive(0x233B2E, 0xF4F3E9)
    static let secondary = adaptive(0x637064, 0xBDC6B9)
    static let accent = adaptive(0x3E6548, 0xB8D9AE)
    static let line = adaptive(0xD8E1D2, 0x465346)

    static func background(for choice: CompanionWidgetChoice) -> Color {
        switch choice {
        case .daily, .pinned, .morning: return paper
        case .evening, .pause: return dusk
        default: return canvas
        }
    }

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

/// No square paper backing, extra padding or glow around the character.
struct WidgetCompanionArt: View {
    let artwork: CompanionArtwork
    let size: CGFloat

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                Image(uiImage: CompanionImage.image(artwork)).resizable()
                    .widgetAccentedRenderingMode(.fullColor)
            } else {
                Image(uiImage: CompanionImage.image(artwork)).resizable()
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A visual affordance for the widget's existing deep link, not a nested button.
struct WidgetOpenCue: View {
    var label: String? = nil
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        HStack(spacing: 6) {
            if let label {
                Text(label).font(.system(size: 11, weight: .semibold)).lineLimit(1)
            }
            Image(systemName: direction == .rightToLeft ? "arrow.left" : "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .frame(width: 29, height: 29)
                .background(CompanionWidgetPalette.accent, in: Circle())
                .foregroundStyle(CompanionWidgetPalette.background(for: .morning))
        }
        .foregroundStyle(CompanionWidgetPalette.accent)
        .accessibilityHidden(true)
    }
}

struct VerseCompanionCard: View {
    let situation: Situation
    let caption: String
    let compact: Bool
    var artwork: CompanionArtwork = .quran
    @Environment(\.locale) private var locale
    private var language: AppLanguage { locale.language.languageCode?.identifier == "ar" ? .arabic : .english }
    private var character: CompanionArtwork { artwork == .quran ? .widgetReading : artwork }

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 5) {
                    captionLabel
                    Text(situation.widgetTitle(language))
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .lineLimit(3).minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: 0) {
                        WidgetCompanionArt(artwork: character, size: 76)
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 7) {
                            Text(situation.primaryVerse?.key ?? "")
                                .font(.system(size: 10, weight: .semibold)).monospacedDigit()
                            WidgetOpenCue()
                        }.padding(.bottom, 3)
                    }.frame(height: 64, alignment: .bottom)
                }
            } else {
                HStack(spacing: 15) {
                    WidgetCompanionArt(artwork: character, size: 112)
                    VStack(alignment: .leading, spacing: 5) {
                        captionLabel
                        if let verse = situation.primaryVerse {
                            Text(verse.arabic)
                                .font(.custom("KFGQPC HAFS Uthmanic Script", size: 20))
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                            Text(language == .arabic ? "\(verse.surahNameArabic) \(verse.key)" : verse.reference)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(CompanionWidgetPalette.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        HStack(alignment: .bottom, spacing: 5) {
                            Text(situation.widgetTitle(language))
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(2)
                            Spacer(minLength: 0)
                            WidgetOpenCue()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(CompanionWidgetPalette.ink)
    }

    private var captionLabel: some View {
        Text(caption)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CompanionWidgetPalette.accent)
            .lineLimit(1)
    }
}

struct PrayerCompanionCard: View {
    let schedule: PrayerSchedule?
    let date: Date
    @Environment(\.locale) private var locale
    private var language: AppLanguage { locale.language.languageCode?.identifier == "ar" ? .arabic : .english }
    private var next: PrayerEvent? { schedule?.nextEvent(after: date) }

    var body: some View {
        Group {
            if let schedule, !schedule.isStale(at: date), let next {
                HStack(spacing: 13) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.pick("Next, ", "التالي، ") + next.kind.displayName(locale: locale))
                            .font(.system(size: 11, weight: .semibold)).lineLimit(1)
                            .foregroundStyle(CompanionWidgetPalette.accent)
                        Text(timeLabel(next.time, schedule: schedule))
                            .font(.system(size: 23, weight: .semibold, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                        WidgetCompanionArt(artwork: .widgetEvening, size: 79)
                    }.frame(width: 112, alignment: .leading)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(schedule.locationLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CompanionWidgetPalette.secondary).lineLimit(1)
                        ForEach(schedule.events(on: next.time)) { event in
                            HStack(spacing: 6) {
                                Text(event.kind.displayName(locale: locale))
                                Spacer(minLength: 3)
                                Text(timeLabel(event.time, schedule: schedule)).monospacedDigit()
                            }
                            .font(.system(size: 11, weight: event.id == next.id ? .bold : .medium))
                            .foregroundStyle(event.id == next.id ? CompanionWidgetPalette.accent : CompanionWidgetPalette.ink)
                            .lineLimit(1).minimumScaleFactor(0.8)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(event.id == next.id ? CompanionWidgetPalette.line : .clear, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                WidgetPrayerSetupCard(hasSchedule: schedule != nil, compact: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(CompanionWidgetPalette.ink)
    }

    private func timeLabel(_ date: Date, schedule: PrayerSchedule) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = schedule.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }
}

struct WidgetPrayerSetupCard: View {
    let hasSchedule: Bool
    let compact: Bool
    @Environment(\.locale) private var locale
    private var language: AppLanguage { locale.language.languageCode?.identifier == "ar" ? .arabic : .english }

    var body: some View {
        let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 16))
        layout {
            if !compact { WidgetCompanionArt(artwork: .widgetEvening, size: 112) }
            VStack(alignment: .leading, spacing: 5) {
                Text(language.pick("Your prayer times", "مواقيت صلاتك"))
                    .font(.system(size: compact ? 16 : 20, weight: .semibold, design: .serif))
                Text(hasSchedule ? language.pick("Open Haneen to refresh", "افتح حنين لتحديث المواقيت")
                     : language.pick("Choose your city in Haneen", "اختر مدينتك في حنين"))
                    .font(.system(size: 11)).foregroundStyle(CompanionWidgetPalette.secondary)
                    .lineLimit(2)
                if !compact { WidgetOpenCue(label: language.pick("Open Haneen", "افتح حنين")).padding(.top, 5) }
            }
            if compact {
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    WidgetCompanionArt(artwork: .widgetEvening, size: 79)
                    Spacer(minLength: 0)
                    WidgetOpenCue()
                }.frame(height: 68, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
