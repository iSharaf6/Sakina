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
        case .early: return "Prayer Times, Fajr–Dhuhr"
        case .late: return "Prayer Times, Asr–Isha"
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
    func title(_ language: AppLanguage) -> String {
        guard language == .arabic else { return title }
        switch self {
        case .daily: return "آية اليوم"
        case .pinned: return "موقف مثبّت"
        case .timetable: return "مواقيت الصلاة"
        case .early: return "مواقيت الصلاة، من الفجر إلى الظهر"
        case .late: return "مواقيت الصلاة، من العصر إلى العشاء"
        case .prayerCat: return "رفيق الصلاة"
        case .countdown: return "الوقت المتبقي للصلاة"
        case .morning: return "رفيق الصباح"
        case .evening: return "رفيق المساء"
        case .pause: return "لحظة هدوء"
        }
    }

    func detail(_ language: AppLanguage) -> String {
        guard language == .arabic else { return detail }
        switch self {
        case .daily: return "آية تتأملها في يومك."
        case .pinned: return "احتفظ بآية تهمّك على شاشتك."
        case .timetable: return "مواقيت صلواتك اليومية في لمحة."
        case .early: return "مواعيد الفجر والشروق والظهر على شاشة القفل."
        case .late: return "مواعيد العصر والمغرب والعشاء على شاشة القفل."
        case .prayerCat: return "رفيق صغير بجوار موعد الصلاة القادمة."
        case .countdown: return "تابع الوقت المتبقي حتى الصلاة القادمة."
        case .morning: return "افتح أذكار الصباح بضغطة واحدة."
        case .evening: return "اختم يومك بذكر الله."
        case .pause: return "خذ لحظة للهدوء والتأمل."
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
        return URL(string: "haneen://\(route)")!
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
    @Environment(\.locale) private var locale
    private var language: AppLanguage { locale.language.languageCode?.identifier == "ar" ? .arabic : .english }
    private var next: PrayerEvent? { schedule?.nextEvent(after: date) }
    var body: some View {
        Group {
            if lockScreen {
                HStack(spacing: 8) {
                    Image(uiImage: CompanionImage.inkMask(choice.artwork)).resizable().renderingMode(.template)
                        .scaledToFit().frame(width: 58, height: 58).widgetAccentable()
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(next?.kind.displayName(locale: locale) ?? language.pick("Prayer times", "مواقيت الصلاة")).font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                        if let next { Text(time(next.time)).font(.subheadline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.8) }
                        else { Text(language.pick("Set your location in Haneen", "حدّد موقعك في حنين")).font(.caption2).lineLimit(2) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            } else if choice == .timetable {
                PrayerCompanionCard(schedule: schedule, date: date)
            } else if choice == .daily || choice == .pinned {
                VerseCompanionCard(situation: choice == .pinned ? (SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay(for: date)) : SharedStore.situationOfTheDay(for: date), caption: choice.title(language), compact: compact, artwork: choice.artwork)
            } else if choice == .early || choice == .late {
                let kinds: [PrayerKind] = choice == .early ? [.fajr, .sunrise, .dhuhr] : [.asr, .maghrib, .isha]
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(kinds, id: \.self) { kind in
                        HStack {
                            Circle().fill(next?.kind == kind ? Color.primary : .clear).frame(width: 5, height: 5).overlay(Circle().stroke(lineWidth: 1))
                            Text(kind.displayName(locale: locale))
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
                        Text(choice == .countdown || choice == .prayerCat ? language.pick("NEXT PRAYER", "الصلاة القادمة") : language.pick("HANEEN", "حنين") + language.listSeparator + choice.title(language))
                            .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(CompanionWidgetPalette.accent)
                        if choice == .countdown || choice == .prayerCat {
                            if let next {
                                Text(next.kind.displayName(locale: locale)).font(.system(size: compact ? 20 : 24, weight: .semibold, design: .serif))
                                if choice == .countdown {
                                    Group {
                                        if preview { Text("30:00") }
                                        else { Text(timerInterval: date...max(date, next.time), countsDown: true) }
                                    }.font(.system(size: compact ? 21 : 28, weight: .medium, design: .rounded)).monospacedDigit()
                                } else { Text(time(next.time)).font(.title3.monospacedDigit()) }
                            } else {
                                Text(language.pick("Find your prayer times", "تعرّف على مواقيت الصلاة")).font(.headline)
                                Text(language.pick("Set your location in Haneen", "حدّد موقعك في حنين")).font(.caption).foregroundStyle(CompanionWidgetPalette.secondary)
                            }
                        } else {
                            Text(choice == .morning ? language.pick("Begin with remembrance.", "ابدأ يومك بذكر الله.") : choice == .evening ? language.pick("Let the day soften.", "اختم يومك بذكر الله.") : language.pick("A breath. An ayah. A little peace.", "لحظة للتنفّس والتأمّل."))
                                .font(.system(size: compact ? 17 : 23, weight: .medium, design: .serif)).fixedSize(horizontal: false, vertical: true)
                            if !compact { Text(choice.detail(language)).font(.caption).foregroundStyle(CompanionWidgetPalette.secondary) }
                        }
                    }
                    if !compact { Spacer(minLength: 0) }
                }
            }
        }.foregroundStyle(lockScreen ? Color.primary : CompanionWidgetPalette.ink)
    }
    private func time(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = locale; formatter.timeZone = schedule?.timeZone ?? .current
        formatter.setLocalizedDateFormatFromTemplate("jm"); return formatter.string(from: date)
    }
}
