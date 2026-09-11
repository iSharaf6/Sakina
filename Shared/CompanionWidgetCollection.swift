import SwiftUI
import WidgetKit

enum CompanionWidgetChoice: String, CaseIterable, Identifiable {
    case daily, pinned, timetable, early, late, prayerCat, countdown, morning, evening, pause
    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: return "Ayah of the Day"
        case .pinned: return "Pinned Situation"
        case .timetable: return "Prayer Times"
        case .early: return "Prayer Times · Fajr–Dhuhr"
        case .late: return "Prayer Times · Asr–Isha"
        case .prayerCat: return "Prayer Companion"
        case .countdown: return "Until the Next Prayer"
        case .morning: return "Morning Companion"
        case .evening: return "Evening Companion"
        case .pause: return "A Quiet Moment"
        }
    }
    var detail: String {
        switch self {
        case .daily: return "A new ayah to carry into the day."
        case .pinned: return "Keep a meaningful passage close."
        case .timetable: return "Your whole prayer day at a glance."
        case .early: return "Fajr, sunrise and Dhuhr on your Lock Screen."
        case .late: return "Asr, Maghrib and Isha alongside them."
        case .prayerCat: return "A little companion beside the next prayer."
        case .countdown: return "Watch the minutes until your next prayer."
        case .morning: return "One tap into your morning adhkar."
        case .evening: return "Let the day end with remembrance."
        case .pause: return "A small invitation to pause and reflect."
        }
    }
    var artwork: CompanionArtwork {
        switch self {
        case .daily: return .quran
        case .pinned: return .saved
        case .timetable: return .salah
        case .early: return .morning
        case .late: return .evening
        case .prayerCat: return .tahajjud
        case .countdown: return .clock
        case .morning: return .morning
        case .evening: return .evening
        case .pause: return .breathe
        }
    }
    var isLock: Bool { self == .early || self == .late }
    var destination: URL {
        let route: String
        switch self {
        case .daily, .pause: route = "daily"
        case .pinned: route = "situation/\((SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay()).id)"
        case .morning: route = "collection/morning"
        case .evening: route = "collection/evening"
        default: route = "prayer-times"
        }
        return URL(string: "yaqeen://\(route)")!
    }
}

/// Production content reused by the widget extension and the in-app chooser.
struct CompanionCollectionCard: View {
    let choice: CompanionWidgetChoice
    let date: Date
    let schedule: PrayerSchedule?
    var compact = false
    var lockScreen = false
    var preview = false
    private var next: PrayerEvent? { schedule?.nextEvent(after: date) }
    var body: some View {
        Group {
            if lockScreen {
                HStack(spacing: 8) {
                    Image(uiImage: CompanionImage.inkMask(choice.artwork)).resizable().renderingMode(.template)
                        .scaledToFit().frame(width: 58, height: 58).widgetAccentable()
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(next?.kind.displayName(locale: .current) ?? "Prayer times").font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                        if let next { Text(time(next.time)).font(.subheadline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.8) }
                        else { Text("Set your location in Yaqeen").font(.caption2).lineLimit(2) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            } else if choice == .timetable {
                PrayerCompanionCard(schedule: schedule, date: date)
            } else if choice == .daily || choice == .pinned {
                VerseCompanionCard(situation: choice == .pinned ? (SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay(for: date)) : SharedStore.situationOfTheDay(for: date), caption: choice.title, compact: compact, artwork: choice.artwork)
            } else if choice == .early || choice == .late {
                let kinds: [PrayerKind] = choice == .early ? [.fajr, .sunrise, .dhuhr] : [.asr, .maghrib, .isha]
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(kinds, id: \.self) { kind in
                        HStack {
                            Circle().fill(next?.kind == kind ? Color.primary : .clear).frame(width: 5, height: 5).overlay(Circle().stroke(lineWidth: 1))
                            Text(kind.displayName(locale: .current))
                            Spacer(minLength: 4)
                            if let event = schedule?.events(on: next?.time ?? date).first(where: { $0.kind == kind }) { Text(time(event.time)).monospacedDigit() }
                            else { Text("—") }
                        }.font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
            } else {
                let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 18))
                layout {
                    CompanionIllustration(artwork: choice.artwork, size: compact ? 60 : 92)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(choice == .countdown || choice == .prayerCat ? "NEXT PRAYER" : "YAQEEN · \(choice == .morning ? "MORNING" : choice == .evening ? "EVENING" : "PAUSE")")
                            .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(CompanionWidgetPalette.accent)
                        if choice == .countdown || choice == .prayerCat {
                            if let next {
                                Text(next.kind.displayName(locale: .current)).font(.system(size: compact ? 20 : 24, weight: .semibold, design: .serif))
                                if choice == .countdown {
                                    Group {
                                        if preview { Text("30:00") }
                                        else { Text(timerInterval: date...max(date, next.time), countsDown: true) }
                                    }.font(.system(size: compact ? 21 : 28, weight: .medium, design: .rounded)).monospacedDigit()
                                } else { Text(time(next.time)).font(.title3.monospacedDigit()) }
                            } else {
                                Text("Find your prayer times").font(.headline)
                                Text("Set your location in Yaqeen").font(.caption).foregroundStyle(CompanionWidgetPalette.secondary)
                            }
                        } else {
                            Text(choice == .morning ? "Begin with remembrance." : choice == .evening ? "Let the day soften." : "A breath. An ayah. A little peace.")
                                .font(.system(size: compact ? 17 : 23, weight: .medium, design: .serif)).fixedSize(horizontal: false, vertical: true)
                            if !compact { Text(choice.detail).font(.caption).foregroundStyle(CompanionWidgetPalette.secondary) }
                        }
                    }
                    if !compact { Spacer(minLength: 0) }
                }
            }
        }.foregroundStyle(lockScreen ? Color.primary : CompanionWidgetPalette.ink)
    }
    private func time(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.timeZone = schedule?.timeZone ?? .current
        formatter.setLocalizedDateFormatFromTemplate("jm"); return formatter.string(from: date)
    }
}
