import SwiftUI

struct WidgetCollectionView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var screen: WidgetPreviewScreen = .home
    @State private var selected: WidgetSelection?
    private let schedule = PrayerSchedule.placeholder()
    private var language: AppLanguage {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-yqWidgetCollection") {
            return ProcessInfo.processInfo.arguments.contains("-yqArabicPreview") ? .arabic : .english
        }
        #endif
        return AppLanguage(rawValue: languageRaw) ?? .english
    }
    private var copy: AppCopy { AppCopy(language: language) }
    private var date: Date { schedule.days[0].events[2].time.addingTimeInterval(-1_800) }

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 40, 540)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy("A little closer,\nevery day.", "أقرب إليك،\nكل يوم."))
                            .font(.yqTitle).foregroundStyle(Color.yqInk)
                        Text(copy("Your next prayer, a little dhikr, an ayah to return to.", "صلاتك القادمة، ولحظة ذكر، وآية تعود إليها."))
                            .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    }
                    Picker(copy("Screen", "الشاشة"), selection: $screen) {
                        ForEach(WidgetPreviewScreen.allCases) { option in
                            Text(option.title(language)).tag(option)
                        }
                    }.pickerStyle(.segmented)
                        .accessibilityIdentifier("widgets.screen")

                    if screen == .home {
                        choiceCard(.prayerCat, size: .medium, width: width)
                        pair(.daily, .countdown, width: width)
                        choiceCard(.timetable, size: .medium, width: width)
                        pair(.pinned, .morning, width: width)
                        pair(.evening, .pause, width: width)
                    } else {
                        lockChoice(.prayerCat, width: width)
                        lockChoice(.early, width: width)
                        lockChoice(.late, width: width)
                    }
                    Text(copy("Previews use example times and progress. Tap a design to add it.", "تستخدم المعاينات مواقيت وتقدّمًا للعرض فقط. اضغط على تصميم لمعرفة كيفية إضافته."))
                        .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: width, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
        }
        .yqScreen()
        .yaqeenLanguage(language)
        .navigationTitle(copy("Widgets", "الأدوات"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { selection in
            WidgetAddingSheet(selection: selection, language: language, schedule: schedule)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func pair(_ first: CompanionWidgetChoice, _ second: CompanionWidgetChoice, width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 16) {
            choiceCard(first, size: .small, width: (width - 16) / 2)
            choiceCard(second, size: .small, width: (width - 16) / 2)
        }
    }

    private func choiceCard(_ choice: CompanionWidgetChoice, size: WidgetPreviewSize, width: CGFloat) -> some View {
        Button { selected = WidgetSelection(choice: choice, size: size) } label: {
            VStack(alignment: .leading, spacing: 10) {
                CompanionWidgetPreview(choice: choice, size: size, schedule: schedule, date: date, availableWidth: width)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(choice.title(language)).font(.yqSubheadBold).foregroundStyle(Color.yqInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "plus.circle.fill").font(.system(size: 18))
                        .foregroundStyle(Color.yqAccentDeep)
                }
                if size == .medium {
                    Text(choice.detail(language)).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.frame(width: width, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(choice.title(language))
            .accessibilityHint(copy("Shows sizes and how to add this widget", "يعرض الأحجام وطريقة إضافة الأداة"))
            .accessibilityIdentifier("widgets.\(choice.rawValue)")
    }

    private func lockChoice(_ choice: CompanionWidgetChoice, width: CGFloat) -> some View {
        Button { selected = WidgetSelection(choice: choice, size: .lock) } label: {
            VStack(alignment: .leading, spacing: 10) {
                CompanionWidgetPreview(choice: choice, size: .lock, schedule: schedule, date: date, availableWidth: width)
                    .frame(width: width, height: 138)
                    .background(lockWallpaper, in: RoundedRectangle(cornerRadius: 28))
                HStack {
                    Text(choice.title(language)).font(.yqSubheadBold).foregroundStyle(Color.yqInk)
                    Spacer(minLength: 0)
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.yqAccentDeep)
                }
                Text(choice.detail(language)).font(.yqCaption).foregroundStyle(Color.yqSecondary)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(choice.title(language))
            .accessibilityHint(copy("Shows how to add this Lock Screen widget", "يعرض طريقة إضافة الأداة إلى شاشة القفل"))
            .accessibilityIdentifier("widgets.lock.\(choice.rawValue)")
    }
}

private enum WidgetPreviewScreen: String, CaseIterable, Identifiable {
    case home, lock
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        self == .home ? language.pick("Home Screen", "الشاشة الرئيسية") : language.pick("Lock Screen", "شاشة القفل")
    }
}

/// Preview dimensions match the extension's families, including its 16pt margins.
/// Small displays scale the whole preview down, keeping the production layout intact.
enum WidgetPreviewSize: String, CaseIterable, Identifiable {
    case small, medium, lock
    var id: String { rawValue }
    var dimensions: CGSize {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-yqCompactWidgetPreview") {
            switch self {
            case .small: return CGSize(width: 158, height: 158)
            case .medium: return CGSize(width: 338, height: 158)
            case .lock: break
            }
        }
        #endif
        switch self {
        case .small: return CGSize(width: 170, height: 170)
        case .medium: return CGSize(width: 356, height: 170)
        case .lock: return CGSize(width: 180, height: 86)
        }
    }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .small: return language.pick("Small", "صغيرة")
        case .medium: return language.pick("Medium", "متوسطة")
        case .lock: return language.pick("Lock Screen", "شاشة القفل")
        }
    }
}

struct CompanionWidgetPreview: View {
    let choice: CompanionWidgetChoice
    let size: WidgetPreviewSize
    let schedule: PrayerSchedule?
    let date: Date
    let availableWidth: CGFloat

    var body: some View {
        let dimensions = size.dimensions
        let scale = min(1, max(0.1, availableWidth / dimensions.width))
        CompanionCollectionCard(choice: choice, date: date, schedule: schedule,
                                compact: size == .small, lockScreen: size == .lock && choice == .prayerCat, preview: true)
            .padding(size == .lock ? 12 : 16)
            .frame(width: dimensions.width, height: dimensions.height)
            .background(size == .lock ? Color.white.opacity(0.12) : CompanionWidgetPalette.background(for: choice),
                        in: RoundedRectangle(cornerRadius: size == .lock ? 18 : 25))
            .clipShape(RoundedRectangle(cornerRadius: size == .lock ? 18 : 25))
            .environment(\.dynamicTypeSize, .medium)
            .environment(\.colorScheme, size == .lock ? .dark : colorScheme)
            .scaleEffect(scale)
            .frame(width: dimensions.width * scale, height: dimensions.height * scale)
            .frame(maxWidth: .infinity)
    }
    @Environment(\.colorScheme) private var colorScheme
}

private struct WidgetSelection: Identifiable {
    let choice: CompanionWidgetChoice
    let size: WidgetPreviewSize
    var id: String { "\(choice.id)-\(size.rawValue)" }
}

private struct WidgetAddingSheet: View {
    let selection: WidgetSelection
    let language: AppLanguage
    let schedule: PrayerSchedule
    @Environment(\.dismiss) private var dismiss
    @State private var size: WidgetPreviewSize
    private var copy: AppCopy { AppCopy(language: language) }
    private var choice: CompanionWidgetChoice { selection.choice }
    private var sizes: [WidgetPreviewSize] {
        if choice.isLock { return [.lock] }
        if choice == .timetable { return [.medium] }
        return choice == .prayerCat ? [.small, .medium, .lock] : [.small, .medium]
    }

    init(selection: WidgetSelection, language: AppLanguage, schedule: PrayerSchedule) {
        self.selection = selection
        self.language = language
        self.schedule = schedule
        _size = State(initialValue: selection.size)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(spacing: 18) {
                            CompanionWidgetPreview(choice: choice, size: size, schedule: schedule,
                                                   date: schedule.days[0].events[2].time.addingTimeInterval(-1_800),
                                                   availableWidth: geometry.size.width - 64)
                                .frame(height: 190)
                                .frame(maxWidth: .infinity)
                                .background(size == .lock ? lockWallpaper : homeWallpaper, in: RoundedRectangle(cornerRadius: 28))
                            if sizes.count > 1 {
                                Picker(copy("Widget size", "حجم الأداة"), selection: $size) {
                                    ForEach(sizes) { option in Text(option.title(language)).tag(option) }
                                }.pickerStyle(.segmented)
                                    .accessibilityIdentifier("widgets.previewSize")
                            }
                        }
                        Text(choice.detail(language)).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                        Text(size == .lock ? copy("Add to your Lock Screen", "أضفها إلى شاشة القفل") : copy("Add to your Home Screen", "أضفها إلى الشاشة الرئيسية"))
                            .font(.yqHeadline)
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text((index + 1).formatted(.number.locale(language.locale)))
                                        .font(.yqCaption).foregroundStyle(Color.yqAccentDeep)
                                        .frame(width: 25, height: 25).background(Color.yqFill, in: Circle())
                                    Text(step).font(.yqSubhead).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        Text(copy("Previews use example times and progress.", "تستخدم المعاينات مواقيت وتقدّمًا للعرض فقط."))
                            .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }.padding(24)
                }
            }.background(Color.yqCanvas)
                .navigationTitle(choice.title(language)).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("Done", "تم")) { dismiss() } } }
        }
        .yaqeenLanguage(language)
    }

    private var steps: [String] {
        if size == .lock {
            return [copy("Touch and hold your Lock Screen.", "اضغط مطولًا على شاشة القفل."),
                    copy("Tap Customize, then Lock Screen.", "اختر تخصيص، ثم شاشة القفل."),
                    copy("Tap the widget area and find Haneen.", "اضغط على مساحة الأدوات وابحث عن حنين."),
                    copy("Choose \(choice.title(language)), then tap Done.", "اختر \(choice.title(language))، ثم اضغط على تم.")]
        }
        return [copy("Touch and hold your Home Screen.", "اضغط مطولًا على الشاشة الرئيسية."),
                copy("Tap Edit, then Add Widget.", "اختر تحرير، ثم إضافة أداة."),
                copy("Search for Haneen and choose \(choice.title(language)).", "ابحث عن حنين واختر \(choice.title(language))."),
                choice == .timetable
                    ? copy("Tap Add Widget, then Done.", "اضغط على إضافة أداة، ثم تم.")
                    : copy("Swipe to the size you want, then tap Add Widget.", "اسحب لاختيار الحجم الذي تريده، ثم اضغط على إضافة أداة.")]
    }
}

private let lockWallpaper = LinearGradient(colors: [Color(red: 0.27, green: 0.36, blue: 0.31), Color(red: 0.13, green: 0.19, blue: 0.17)], startPoint: .topLeading, endPoint: .bottomTrailing)
private let homeWallpaper = LinearGradient(colors: [Color.yqFill, Color.yqSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
