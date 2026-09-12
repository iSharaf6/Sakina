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
        case .prayerCat: return .widgetEvening
        case .countdown: return .widgetMorning
        case .morning: return .widgetMorning
        case .evening: return .widgetEvening
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
    private var next: PrayerEvent? {
        guard let schedule, !schedule.isStale(at: date) else { return nil }
        return schedule.nextEvent(after: date)
    }

    var body: some View {
        Group {
            if lockScreen {
                lockContent
            } else if choice == .timetable {
                PrayerCompanionCard(schedule: schedule, date: date)
            } else if choice == .daily || choice == .pinned || choice == .pause {
                VerseCompanionCard(
                    situation: choice == .pinned ? (SharedStore.pinnedSituation ?? SharedStore.situationOfTheDay(for: date)) : SharedStore.situationOfTheDay(for: date),
                    caption: choice.title(language), compact: compact, artwork: choice.artwork)
            } else if choice == .early || choice == .late {
                prayerRows
            } else if choice == .prayerCat || choice == .countdown {
                if let next { prayerContent(next) }
                else { WidgetPrayerSetupCard(hasSchedule: schedule != nil, compact: compact) }
            } else {
                adhkarContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(lockScreen ? Color.primary : CompanionWidgetPalette.ink)
    }

    private var lockContent: some View {
        HStack(spacing: 7) {
            Image(uiImage: CompanionImage.inkMask(.tahajjud)).resizable().renderingMode(.template)
                .scaledToFit().frame(width: 61, height: 61).widgetAccentable()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(next?.kind.displayName(locale: locale) ?? language.pick("Prayer times", "مواقيت الصلاة"))
                    .font(.system(size: 15, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                if let next {
                    Text(time(next.time)).font(.system(size: 14, weight: .medium)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.8)
                } else {
                    Text(schedule == nil ? language.pick("Choose your city", "اختر مدينتك") : language.pick("Open to refresh", "افتح لتحديث المواقيت"))
                        .font(.caption2).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var prayerRows: some View {
        let kinds: [PrayerKind] = choice == .early ? [.fajr, .sunrise, .dhuhr] : [.asr, .maghrib, .isha]
        return VStack(alignment: .leading, spacing: 5) {
            ForEach(kinds, id: \.self) { kind in
                HStack {
                    Circle().fill(next?.kind == kind ? Color.primary : .clear).frame(width: 6, height: 6)
                        .overlay(Circle().stroke(lineWidth: 1)).accessibilityHidden(true)
                    Text(kind.displayName(locale: locale))
                    Spacer(minLength: 4)
                    if next != nil, let event = schedule?.events(on: next?.time ?? date).first(where: { $0.kind == kind }) {
                        Text(time(event.time)).monospacedDigit()
                    } else { Text("—") }
                }.font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
    }

    @ViewBuilder private func prayerContent(_ event: PrayerEvent) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 4) {
                Text(choice == .countdown ? language.pick("Until ", "الوقت المتبقي حتى ") + event.kind.displayName(locale: locale)
                     : language.pick("Next, ", "التالي، ") + event.kind.displayName(locale: locale))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CompanionWidgetPalette.accent).lineLimit(1).minimumScaleFactor(0.8)
                if choice == .countdown {
                    countdown(event, size: 28)
                } else {
                    Text(time(event.time)).font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 0) {
                    WidgetCompanionArt(artwork: choice.artwork, size: 82)
                    Spacer(minLength: 0)
                    WidgetOpenCue().padding(.bottom, 3)
                }.frame(height: 69, alignment: .bottom)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 16) {
                    WidgetCompanionArt(artwork: choice.artwork, size: 94)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(upcomingLabel(event))
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(CompanionWidgetPalette.accent)
                        Text(event.kind.displayName(locale: locale))
                            .font(.system(size: 24, weight: .semibold, design: .serif)).lineLimit(1)
                        if choice == .countdown { countdown(event, size: 29) }
                        else { Text(time(event.time)).font(.system(size: 25, weight: .semibold, design: .rounded)).monospacedDigit() }
                        if choice == .countdown {
                            Text(time(event.time)).font(.system(size: 11, weight: .medium)).foregroundStyle(CompanionWidgetPalette.secondary)
                        } else if let location = schedule?.locationLabel {
                            Text(location).font(.system(size: 11)).foregroundStyle(CompanionWidgetPalette.secondary).lineLimit(1)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 4) {
                    if let following = schedule?.followingEvent(after: date) {
                        Text(language.pick("Then ", "ثم ") + following.kind.displayName(locale: locale) + language.listSeparator + time(following.time))
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(CompanionWidgetPalette.secondary)
                            .lineLimit(1).minimumScaleFactor(0.85)
                    }
                    Spacer(minLength: 0)
                    WidgetOpenCue()
                }.frame(height: 24)
            }
        }
    }

    private func upcomingLabel(_ event: PrayerEvent) -> String {
        event.kind == .sunrise ? language.pick("Coming up", "الموعد القادم") : language.pick("Next prayer", "الصلاة القادمة")
    }

    private func countdown(_ event: PrayerEvent, size: CGFloat) -> some View {
        Group {
            if preview { Text(language.pick("30:00", "٣٠:٠٠")) }
            else { Text(timerInterval: date...max(date, event.time), countsDown: true) }
        }
        .font(.system(size: size, weight: .semibold, design: .rounded))
        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
        .multilineTextAlignment(.leading)
    }

    private var adhkarComplete: Bool {
        let progress = SharedStore.practiceProgress(on: date)
        // The labelled in-app preview illustrates both available states.
        if preview { return choice == .morning }
        return choice == .morning ? progress.morningComplete : progress.eveningComplete
    }

    private var adhkarTitle: String {
        choice == .morning ? language.pick("Morning adhkar", "أذكار الصباح") : language.pick("Evening adhkar", "أذكار المساء")
    }

    private var adhkarContent: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 5) {
                    Text(adhkarTitle).font(.system(size: 17, weight: .semibold, design: .serif))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    completionLabel
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: 0) {
                        WidgetCompanionArt(artwork: choice.artwork, size: 92)
                        Spacer(minLength: 0)
                        WidgetOpenCue().padding(.bottom, 3)
                    }.frame(height: 76, alignment: .bottom)
                }
            } else {
                HStack(spacing: 18) {
                    WidgetCompanionArt(artwork: choice.artwork, size: 125)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(language.pick("Today", "اليوم"))
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(CompanionWidgetPalette.accent)
                        Text(adhkarTitle).font(.system(size: 23, weight: .semibold, design: .serif))
                            .lineLimit(2).minimumScaleFactor(0.85)
                        completionLabel
                        Spacer(minLength: 0)
                        WidgetOpenCue(label: adhkarComplete ? language.pick("Read again", "اقرأ مجددًا") : language.pick("Begin", "ابدأ"))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var completionLabel: some View {
        HStack(spacing: 4) {
            if adhkarComplete {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).accessibilityHidden(true)
            }
            Text(adhkarComplete ? language.pick("Completed today", "أتممتها اليوم") : language.pick("Ready for today", "جاهزة ليومك"))
                .font(.system(size: 10, weight: .medium)).lineLimit(1)
        }
        .foregroundStyle(adhkarComplete ? CompanionWidgetPalette.accent : CompanionWidgetPalette.secondary)
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = schedule?.timeZone ?? .current
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter.string(from: date)
    }
}
