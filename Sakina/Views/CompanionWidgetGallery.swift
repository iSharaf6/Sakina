#if DEBUG
import SwiftUI

/// `-yqWidgetGallery` exercises production content at WidgetKit dimensions.
/// Add `-yqArabicPreview` and/or `-yqDarkPreview` for deterministic QA variants.
struct CompanionWidgetGallery: View {
    private let schedule = PrayerSchedule.placeholder()
    private var previewDate: Date { schedule.days[0].events[2].time.addingTimeInterval(-1_800) }
    private var language: AppLanguage { ProcessInfo.processInfo.arguments.contains("-yqArabicPreview") ? .arabic : .english }
    private var scheme: ColorScheme { ProcessInfo.processInfo.arguments.contains("-yqDarkPreview") ? .dark : .light }
    private var homeChoices: [CompanionWidgetChoice] {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-yqWidgetFocus"), args.indices.contains(index + 1),
           let choice = CompanionWidgetChoice(rawValue: args[index + 1]) { return [choice] }
        return [.prayerCat, .daily, .countdown, .morning, .evening, .pause, .pinned, .timetable]
    }

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 32, 356)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(language.pick("Haneen widgets", "أدوات حنين")).font(.largeTitle.bold())
                    Text(language.pick("Production previews, example times and progress", "معاينات الأدوات، بمواقيت وتقدّم للعرض فقط"))
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(homeChoices) { choice in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(choice.title(language)).font(.headline)
                            CompanionWidgetPreview(choice: choice, size: .medium, schedule: schedule,
                                                   date: previewDate, availableWidth: width)
                            if choice != .timetable {
                                HStack(alignment: .top, spacing: 16) {
                                    CompanionWidgetPreview(choice: choice, size: .small, schedule: schedule,
                                                           date: previewDate, availableWidth: (width - 16) / 2)
                                    CompanionWidgetPreview(choice: choice, size: .small, schedule: schedule,
                                                           date: previewDate, availableWidth: (width - 16) / 2)
                                        .environment(\.colorScheme, scheme == .dark ? .light : .dark)
                                }
                            }
                        }
                    }
                    Text(language.pick("Lock Screen", "شاشة القفل")).font(.title2.bold())
                    ForEach([CompanionWidgetChoice.prayerCat, .early, .late], id: \.self) { choice in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(choice.title(language)).font(.headline)
                            CompanionWidgetPreview(choice: choice, size: .lock, schedule: schedule,
                                                   date: previewDate, availableWidth: width)
                                .frame(width: width, height: 120)
                                .background(Color(red: 0.22, green: 0.29, blue: 0.26), in: RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    Text(language.pick("Location not set", "لم يُحدّد الموقع")).font(.headline)
                    CompanionWidgetPreview(choice: .prayerCat, size: .medium, schedule: nil,
                                           date: previewDate, availableWidth: width)
                    CompanionWidgetPreview(choice: .prayerCat, size: .lock, schedule: nil,
                                           date: previewDate, availableWidth: width)
                        .frame(width: width, height: 120)
                        .background(Color(red: 0.22, green: 0.29, blue: 0.26), in: RoundedRectangle(cornerRadius: 24))
                }.frame(width: width).padding(.vertical, 20).frame(maxWidth: .infinity)
            }.background(Color.yqCanvas)
        }
        .yaqeenLanguage(language)
        .preferredColorScheme(scheme)
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
