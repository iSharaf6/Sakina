#if DEBUG
import SwiftUI

/// Launched with -yqWidgetGallery. These are the shared production card views,
/// inset by WidgetKit's standard margins; providers and deep links remain in the extension.
struct CompanionWidgetGallery: View {
    private let situation = SharedStore.situationOfTheDay()
    private let schedule = PrayerSchedule.placeholder()
    private var previewDate: Date { schedule.days[0].events[2].time.addingTimeInterval(-1_800) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Yaqeen widgets").font(.largeTitle.bold())
                Text("Lock Screen · Prayer Companion").font(.headline)
                HStack(spacing: 12) {
                    lockCard(date: schedule.days[0].events[0].time.addingTimeInterval(-1800))
                    lockCard(date: schedule.days[0].events[4].time.addingTimeInterval(-1800))
                }
                lockCard(date: previewDate, hasLocation: false)
                HStack(spacing: 16) {
                    card(width: 170) {
                        VerseCompanionCard(situation: situation, caption: "Ayah of the day", compact: true)
                    }
                    card(width: 170) {
                        VerseCompanionCard(situation: situation, caption: "Reflecting on", compact: true, artwork: .praise)
                    }
                }
                card {
                    VerseCompanionCard(situation: situation, caption: "Ayah of the day", compact: false)
                }
                card { PrayerCompanionCard(schedule: schedule, date: previewDate) }
                card { PrayerCompanionCard(schedule: nil, date: previewDate) }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func lockCard(date: Date, hasLocation: Bool = true) -> some View {
        CompanionCollectionCard(choice: .prayerCat, date: date,
                                schedule: hasLocation ? schedule : nil, lockScreen: true, preview: true)
            .foregroundStyle(.white)
            .environment(\.colorScheme, .dark)
            .padding(12)
            .frame(width: 180, height: 86)
            .background(Color(white: 0.26), in: RoundedRectangle(cornerRadius: 18))
    }

    private func card<Content: View>(width: CGFloat = 356, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(width: width, height: 170)
            .background(CompanionWidgetPalette.canvas, in: RoundedRectangle(cornerRadius: 24))
    }
}
struct CompanionPrayerCardGallery: View {
    private let schedule = PrayerSchedule.placeholder()
    private var language: AppLanguage {
        ProcessInfo.processInfo.arguments.contains("-yqArabicPreview") ? .arabic : .english
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(language.pick("Prayer cards", "الصلاة القادمة")).font(.largeTitle.bold())
                ForEach(schedule.days[0].events) { event in
                    NextPrayerCard(schedule: schedule, now: event.time.addingTimeInterval(-1_800), language: language)
                }
            }
            .padding(20)
        }
        .yqScreen()
        .yaqeenLanguage(language)
    }
}
#endif
