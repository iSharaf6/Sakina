import SwiftUI

/// One viewport. What the app is for, what is next, and one tap into it.
struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Binding var path: NavigationPath
    var prayerRequest = 0
    var settingsRequest = 0
    var openSearch: (String) -> Void

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.prayerCalculationMethod) private var prayerMethodRaw = PrayerCalculationMethod.muslimWorldLeague.rawValue
    @AppStorage(SettingsKeys.prayerAsrMethod) private var prayerAsrRaw = PrayerAsrMethod.standard.rawValue
    @AppStorage(SettingsKeys.prayerHighLatitude) private var highLatitudeRaw = PrayerHighLatitudePreference.automatic.rawValue
    @AppStorage(DuaCollection.lastReadKey) private var lastReadID = ""
    @AppStorage(HeartLog.key) private var heartLogRaw = ""
    @ObservedObject private var prayerService = PrayerTimesService.shared
    @State private var query = ""
    @State private var sheet: HomeSheet?
    @State private var showBreathing = false
    @State private var today = SharedStore.situationOfTheDay()
    @State private var duaToday = DuaCollection.duaOfTheDay()
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    private enum HomeSheet: String, Identifiable {
        case settings, prayers
        var id: String { rawValue }
    }

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var prayerSettings: PrayerCalculationSettings {
        var settings = PrayerCalculationSettings.default
        settings.method = PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muslimWorldLeague
        settings.asrMethod = PrayerAsrMethod(rawValue: prayerAsrRaw) ?? .standard
        settings.highLatitudePreference = PrayerHighLatitudePreference(rawValue: highLatitudeRaw) ?? .automatic
        return settings
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header.revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                    searchField.revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                    prayerCard.revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                    HomePracticeSection(language: language)
                        .revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                    duaTodayCard.revealed(4, appeared: appeared, reduceMotion: reduceMotion)
                    goalsCard.revealed(5, appeared: appeared, reduceMotion: reduceMotion)
                    heart.revealed(6, appeared: appeared, reduceMotion: reduceMotion)
                    todayGrid.revealed(7, appeared: appeared, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .yqScreen()
            .navigationDestination(for: GuidanceSupplication.self) { DuaReaderView(dua: $0) }
            .navigationDestination(for: DuaMood.self) { MoodDetailView(mood: $0, language: language) }
            .navigationDestination(for: DuaPractice.self) { PracticeDestination(practice: $0, language: language) }
            .navigationDestination(for: DuaRoute.self) { route in
                switch route {
                case .feelings: FeelingsView(language: language)
                case .counter: DhikrListView(language: language)
                case .ruqyah: RuqyahView(language: language)
                case .benefits: AdhkarBenefitsView(language: language)
                case .goals: DailyGoalsView(language: language)
                }
            }
            .navigationDestination(for: DhikrItem.self) { DhikrCounterView(item: $0, language: language) }
            .navigationDestination(for: Situation.self) { SituationDetailView(situation: $0) }
            .navigationDestination(for: LifeGroup.self) { LifeGroupView(group: $0) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $sheet) { item in
                switch item {
                case .settings:
                    SettingsView(showsDismissButton: true)
                case .prayers:
                    NavigationStack {
                        ScrollView { prayerSheetCard.padding(20) }
                            .yqScreen()
                            .navigationTitle(copy("Prayer times", "مواقيت الصلاة"))
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("Done", "تم")) { sheet = nil } } }
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .fullScreenCover(isPresented: $showBreathing) { BreathingView(language: language) }
            .onChange(of: prayerRequest) { _, _ in sheet = .prayers }
            .onChange(of: settingsRequest) { _, _ in sheet = .settings }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = SharedStore.situationOfTheDay()
                    duaToday = DuaCollection.duaOfTheDay()
                }
            }
            .onAppear { appeared = true }
        }
    }

    // MARK: Header

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 4..<12: return copy("Good morning", "صباح الخير")
        case 12..<17: return copy("Good afternoon", "طاب يومك")
        case 17..<21: return copy("Good evening", "مساء الخير")
        default: return copy("Good night", "ليلة طيبة")
        }
    }

    private var hijriDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = language.locale
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: .now)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    YaqeenBrandIcon(size: 28)
                    Text("Haneen")
                        .font(.yqCaptionBold)
                        .foregroundStyle(Color.yqAccentDeep)
                        .tracking(0.4)
                    Text(hijriDate)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqTertiary)
                        .lineLimit(1)
                }
                Text(greeting)
                    .font(.yqLargeTitle)
                    .tracking(-0.5)
                    .foregroundStyle(Color.yqInk)
                    .accessibilityAddTraits(.isHeader)
                Text(copy("Du’a, dhikr and Qur’an for how you feel.", "دعاء وذكر وقرآن لما تشعر به."))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 0)
            Button { sheet = .settings } label: { CompanionIllustration(artwork: .settings, size: 44) }
                .buttonStyle(.yqPress)
                .accessibilityLabel(copy("Settings", "الإعدادات"))
                .padding(.top, 2)
        }
    }

    private var searchField: some View {
        SearchField(prompt: copy("What’s on your mind?", "ما الذي يشغل بالك؟"), text: $query, focus: $searchFocused) {
            let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            searchFocused = false
            openSearch(value)
            query = ""
        }
    }

    // MARK: Prayer

    @ViewBuilder private var prayerCard: some View {
        Button { sheet = .prayers } label: {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                if let schedule = prayerService.schedule, !schedule.isStale() {
                    NextPrayerCard(schedule: schedule, now: context.date, language: language)
                } else {
                    PrayerSetupCard(language: language, isRefreshing: prayerService.isRefreshing)
                }
            }
        }
        .buttonStyle(.yqPress)
        .accessibilityHint(copy("Opens the full prayer schedule", "يفتح جدول مواقيت الصلاة"))
    }

    @ViewBuilder private var prayerSheetCard: some View {
        if let schedule = prayerService.schedule, !schedule.isStale() {
            PrayerHeroCard(schedule: schedule, language: language, isRefreshing: prayerService.isRefreshing, refresh: refreshPrayerTimes)
        } else {
            PrayerPermissionCard(language: language, isRefreshing: prayerService.isRefreshing,
                                 errorMessage: prayerService.errorMessage, action: refreshPrayerTimes)
        }
    }

    private func refreshPrayerTimes() {
        Task { await prayerService.refreshUsingCurrentLocation(settings: prayerSettings) }
    }

    // MARK: Du’a today

    private var duaTodayCard: some View {
        NavigationLink(value: duaToday) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    CapsLabel(text: copy("Du’a today", "دعاء اليوم"), color: .yqAccentDeep)
                    Spacer(minLength: 0)
                    Text(DuaCollection.sourceLabel(duaToday, language: language))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqTertiary)
                        .lineLimit(1)
                }
                Text(duaToday.arabic)
                    .font(.arabicProse(22))
                    .lineSpacing(8)
                    .foregroundStyle(Color.yqInk)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                HStack(spacing: 10) {
                    CompanionIllustration(artwork: duaToday.kind == .quranic ? .quran : .sunnah, size: 34)
                    Text(duaToday.title(language))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqInk)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(copy("Read", "اقرأ"))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqAccentDeep)
                    Chevron()
                }
            }
            .padding(16)
            .yqCard(cornerRadius: 20)
        }
        .buttonStyle(.yqPress)
        .accessibilityHint(copy("Opens today’s du’a", "يفتح دعاء اليوم"))
    }

    // MARK: Goals

    private var goalsCard: some View {
        NavigationLink { DailyGoalsView(language: language) } label: {
            DailyGoalsCard(language: language)
        }
        .buttonStyle(.yqPress)
    }

    // MARK: Heart

    private var heart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("How’s your heart?", "كيف حال قلبك؟")) {
                NavigationLink { FeelingsView(language: language) } label: {
                    TextAction(title: copy("All feelings", "كل المشاعر"))
                }
                .buttonStyle(.yqPressSoft)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HeartLog.suggestions(from: heartLogRaw)) { mood in
                        NavigationLink(value: mood) {
                            FeelingChip(symbol: mood.symbol, title: mood.title(language), artwork: mood.artwork)
                        }
                        .buttonStyle(.yqPress)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            if !HeartLog.entries(heartLogRaw).isEmpty {
                HeartStrip(log: HeartLog.week(from: heartLogRaw), language: language)
            }
        }
    }

    // MARK: Today

    private var todayGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Today", "اليوم")) {
                Button { showBreathing = true } label: {
                    HStack(spacing: 5) {
                        CompanionIllustration(artwork: .breathe, size: 32)
                        Text(copy("Breathe", "تنفّس"))
                    }
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqAccentDeep)
                    .frame(minHeight: 36)
                }
                .buttonStyle(.yqPressSoft)
                .accessibilityLabel(copy("A moment to breathe", "لحظة تتنفس فيها"))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                NavigationLink { DuasView(showsNavigationBar: true) } label: {
                    BadgeTile(symbol: "book.closed.fill", tint: .yqAccent,
                              title: copy("Du’a collections", "مجموعات الأدعية"),
                              detail: copy("For every part of your day", "لكل أوقات يومك"), artwork: .sunnah)
                }
                .buttonStyle(.yqPress)

                NavigationLink(value: today) {
                    BadgeTile(symbol: "quote.opening", tint: BadgeTint.green.color,
                              title: copy("Ayah today", "آية اليوم"),
                              detail: today.localizedTitle(language), artwork: .quran)
                }
                .buttonStyle(.yqPress)

                if let last = DuaCollection.dua(lastReadID) {
                    NavigationLink(value: last) {
                        BadgeTile(symbol: "book.pages.fill", tint: BadgeTint.teal.color,
                                  title: copy("Continue", "أكمل"),
                                  detail: last.title(language), artwork: .sunnah)
                    }
                    .buttonStyle(.yqPress)
                } else {
                    NavigationLink(value: DuaPractice.istighfar) {
                        BadgeTile(symbol: DuaPractice.istighfar.symbol, tint: DuaPractice.istighfar.tint,
                                  title: DuaPractice.istighfar.title(language),
                                  detail: DuaPractice.istighfar.countLabel(language), artwork: .istighfar)
                    }
                    .buttonStyle(.yqPress)
                }

                NavigationLink { QiblaView() } label: {
                    BadgeTile(symbol: "location.north.circle.fill", tint: BadgeTint.blue.color,
                              title: copy("Qibla", "القبلة"),
                              detail: copy("Find the direction", "اعرف الاتجاه"), artwork: .qibla)
                }
                .buttonStyle(.yqPress)
            }
        }
    }
}

// MARK: - Settings button (every tab)

/// The companion gear that opens Settings, shared by every tab's header.
struct SettingsButton: View {
    let language: AppLanguage
    let action: () -> Void
    var body: some View {
        Button(action: action) { CompanionIllustration(artwork: .settings, size: 44) }
            .buttonStyle(.yqPress)
            .accessibilityLabel(language.pick("Settings", "الإعدادات"))
            .padding(.top, 2)
    }
}

// MARK: - Heart log (the return loop)

/// Remembers which feeling was opened on which day, on this device only.
/// Stored as `yyyy-MM-dd=moodID` pairs joined by `|`.
enum HeartLog {
    static let key = "yaqeen.heartLog"

    private static var formatter: DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    static func entries(_ raw: String) -> [(day: String, mood: DuaMood)] {
        raw.split(separator: "|").compactMap { pair in
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, let mood = DuaMood(rawValue: parts[1]) else { return nil }
            return (parts[0], mood)
        }
    }

    static func recording(_ mood: DuaMood, on date: Date = .now, in raw: String) -> String {
        let day = formatter.string(from: date)
        var kept = entries(raw).filter { $0.day != day }
        kept.append((day, mood))
        return kept.suffix(60).map { "\($0.day)=\($0.mood.rawValue)" }.joined(separator: "|")
    }

    /// The last seven days, oldest first. `nil` where nothing was opened.
    static func week(from raw: String, ending date: Date = .now) -> [(date: Date, mood: DuaMood?)] {
        let lookup = Dictionary(entries(raw).map { ($0.day, $0.mood) }, uniquingKeysWith: { _, new in new })
        return (0..<7).reversed().map { offset in
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: date) ?? date
            return (day, lookup[formatter.string(from: day)])
        }
    }

    /// Recently opened feelings first, then the editorial defaults.
    static func suggestions(from raw: String) -> [DuaMood] {
        var seen = Set<DuaMood>()
        let recent = entries(raw).reversed().map(\.mood).filter { seen.insert($0).inserted }.prefix(3)
        return Array(recent) + DuaMood.featured.filter { seen.insert($0).inserted }.prefix(6 - recent.count)
    }
}

private struct HeartStrip: View {
    let log: [(date: Date, mood: DuaMood?)]
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(log.enumerated()), id: \.offset) { index, day in
                let isToday = index == log.count - 1
                VStack(spacing: 5) {
                    ZStack {
                        if let mood = day.mood {
                            CompanionIllustration(artwork: mood.artwork, size: 30)
                        } else {
                            Circle().strokeBorder(isToday ? Color.yqAccent : Color.yqHairline,
                                                  style: StrokeStyle(lineWidth: 1.2, dash: isToday ? [] : [2, 2]))
                        }
                    }
                    .frame(width: 26, height: 26)
                    Text(day.date.formatted(.dateTime.weekday(.narrow).locale(language.locale)))
                        .font(.system(.caption2, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? Color.yqInk : Color.yqTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .yqCard(cornerRadius: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.pick("Your week", "أسبوعك"))
    }
}

// MARK: - Next prayer (dark card)

struct NextPrayerCard: View {
    let schedule: PrayerSchedule
    let now: Date
    let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        let next = schedule.nextEvent(after: now)
        let events = schedule.events(on: next?.time ?? now)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    CapsLabel(text: copy("Next prayer", "الصلاة القادمة"), color: .yqAccentDeep)
                    if let next {
                        let headlineLayout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
                        headlineLayout {
                            Text(next.kind.displayName(locale: language.locale))
                                .font(.yqTitle)
                            Text(time(next.time))
                                .font(.yqHeadline)
                                .foregroundStyle(Color.yqSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        Text(countdown(to: next.time))
                            .font(.yqSubheadMedium)
                            .foregroundStyle(Color.yqSecondary)
                    }
                }
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize {
                    CompanionIllustration(artwork: (next?.kind ?? .isha).artwork, size: 86)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                     count: dynamicTypeSize.isAccessibilitySize ? 2 : 3), spacing: 8) {
                ForEach(events) { event in
                    VStack(spacing: 3) {
                        Text(event.kind.displayName(locale: language.locale))
                            .font(.system(.caption2, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(time(event.time))
                            .font(.system(.caption, weight: event.kind == next?.kind ? .bold : .medium).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(event.kind == next?.kind ? Color.yqAccentDeep : Color.yqSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(event.kind == next?.kind ? Color.yqAccent.opacity(0.08) : .clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .foregroundStyle(Color.yqInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard(cornerRadius: 20)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary(events: events, next: next))
    }

    private func accessibilitySummary(events: [PrayerEvent], next: PrayerEvent?) -> String {
        let heading = next.map {
            "\(copy("Next prayer", "الصلاة القادمة")), \($0.kind.displayName(locale: language.locale)), \(time($0.time)), \(countdown(to: $0.time)). "
        } ?? ""
        let schedule = events.map {
            "\($0.kind.displayName(locale: language.locale)), \(time($0.time))"
        }.joined(separator: ". ")
        return heading + schedule
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = schedule.timeZone
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func countdown(to date: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSince(now) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 { return copy("in \(hours) hr \(remainder) min", "بعد \(hours) س و\(remainder) د") }
        return copy("in \(remainder) min", "بعد \(remainder) دقيقة")
    }
}

private struct PrayerSetupCard: View {
    let language: AppLanguage
    let isRefreshing: Bool
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        HStack(spacing: 14) {
            CompanionIllustration(artwork: .lost, size: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(copy("Prayer times, where you are", "مواقيت الصلاة حيث أنت"))
                    .font(.yqHeadline)
                Text(isRefreshing ? copy("Finding your city…", "جارٍ تحديد مدينتك…")
                                  : copy("Set once. Calculated on your iPhone.", "تُضبط مرة واحدة وتُحسب على جهازك."))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.yqSecondary)
        }
        .foregroundStyle(Color.yqInk)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard(cornerRadius: 20)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Prayer sheet

struct PrayerHeroCard: View {
    let schedule: PrayerSchedule
    let language: AppLanguage
    let isRefreshing: Bool
    let refresh: () -> Void
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let events = schedule.events(on: context.date)
            let next = schedule.nextEvent(after: context.date)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    HStack(spacing: 14) {
                        CompanionIllustration(artwork: event.kind.artwork, size: 42)
                        Text(event.kind.displayName(locale: language.locale))
                            .font(event.kind == next?.kind ? .yqBodyMedium : .yqBody)
                            .foregroundStyle(Color.yqInk)
                        Spacer()
                        if event.kind == next?.kind {
                            Tag(text: copy("Next", "التالية"))
                        }
                        Text(time(event.time))
                            .font(.system(.body, weight: event.kind == next?.kind ? .semibold : .regular).monospacedDigit())
                            .foregroundStyle(Color.yqInk)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 56)
                    if index < events.count - 1 { RowDivider() }
                }
            }
            .yqCard()
            Button(action: refresh) {
                HStack(spacing: 8) {
                    if isRefreshing { ProgressView().controlSize(.small) } else { CompanionIllustration(artwork: .lost, size: 30) }
                    Text(schedule.locationLabel).lineLimit(1)
                    Spacer()
                    Text(copy("Update", "تحديث")).foregroundStyle(Color.yqAccentDeep)
                }
                .font(.yqSubheadMedium)
                .foregroundStyle(Color.yqSecondary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
            }
            .buttonStyle(.yqPressSoft)
            .disabled(isRefreshing)
        }
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = schedule.timeZone
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PrayerPermissionCard: View {
    let language: AppLanguage
    let isRefreshing: Bool
    let errorMessage: String?
    let action: () -> Void
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CompanionIllustration(artwork: .lost, size: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(copy("Prayer times, where you are", "مواقيت الصلاة حيث أنت"))
                    .font(.yqTitle2)
                    .foregroundStyle(Color.yqInk)
                Text(copy("Calculated privately on your iPhone. Your coordinates never leave the device.",
                          "تُحسب على جهازك بخصوصية، ولا تغادر إحداثياتك الجهاز."))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.yqCaption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: action) {
                PrimaryButton(title: isRefreshing ? copy("Finding your city…", "جارٍ تحديد مدينتك…") : copy("Use my location", "استخدم موقعي"),
                              symbol: isRefreshing ? nil : "location.fill")
            }
            .buttonStyle(.yqPress)
            .disabled(isRefreshing)
        }
        .padding(20)
        .yqCard()
    }
}

// MARK: - Daily practice on Home

private struct HomePracticeSection: View {
    let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(ReadingPlace.key) private var placesRaw = ""
    @AppStorage(PracticeLog.key) private var practiceLogRaw = ""
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            VStack(alignment: .leading, spacing: 20) {
                rightNow
                tools
            }
        }
    }

    private var suggested: DuaPractice { DuaPractice.suggested() }

    // MARK: Right now

    private var rightNow: some View {
        NavigationLink(value: suggested) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 16))
            layout {
                ZStack {
                    CompanionIllustration(artwork: suggested.artwork, size: 80)
                    if let progress = progress(for: suggested), progress > 0 {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(suggested.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 88, height: 88)
                    }
                }
                .frame(width: 88, height: 88)
                VStack(alignment: .leading, spacing: 4) {
                    CapsLabel(text: copy("Right now", "الآن"), color: suggested.tint)
                    Text(suggested.title(language))
                        .font(.yqTitle2)
                        .foregroundStyle(Color.yqInk)
                    Text(rightNowDetail)
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.yqOnAccent)
                    .frame(width: 36, height: 36)
                    .background(Color.yqAccent, in: Circle())
            }
            .multilineTextAlignment(.leading)
            .padding(16)
            .yqCard(cornerRadius: 22)
        }
        .buttonStyle(.yqPress)
    }

    private var rightNowDetail: String {
        if PracticeLog.isDone(suggested, in: practiceLogRaw) {
            return copy("Done for today. Read again any time.", "أُنجزت اليوم. اقرأها مجددًا متى شئت.")
        }
        if let entryID = ReadingPlace.entry(for: suggested, in: placesRaw),
           let position = suggested.entryIDs.firstIndex(of: entryID) {
            return copy("Continue · \(position + 1) of \(suggested.entries.count)", "تابع · \(position + 1) من \(suggested.entries.count)")
        }
        return suggested.invitation(language)
    }

    private func progress(for practice: DuaPractice) -> Double? {
        if PracticeLog.isDone(practice, in: practiceLogRaw) { return 1 }
        guard let entryID = ReadingPlace.entry(for: practice, in: placesRaw),
              let position = practice.entryIDs.firstIndex(of: entryID),
              !practice.entries.isEmpty else { return nil }
        return Double(position) / Double(practice.entries.count)
    }

    // MARK: Tools

    private var tools: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
            NavigationLink(value: DuaRoute.counter) {
                BadgeTile(symbol: "hand.tap.fill", tint: .yqAccent,
                          title: copy("Tasbih", "التسبيح"),
                          detail: copy("Tap to count dhikr", "اضغط لعدّ الذكر"), artwork: .anytime)
            }
            .buttonStyle(.yqPress)
            NavigationLink(value: DuaRoute.goals) {
                BadgeTile(symbol: "checkmark.circle.fill", tint: .yqAccent,
                          title: copy("Daily goals", "أهداف اليوم"),
                          detail: copy("Small, daily, yours", "صغيرة، يومية، لك"), artwork: .salah)
            }
            .buttonStyle(.yqPress)
            NavigationLink(value: DuaRoute.ruqyah) {
                BadgeTile(symbol: "cross.case.fill", tint: .yqAccent,
                          title: copy("Ruqyah", "الرقية"),
                          detail: copy("Qur’an and Sunnah", "من القرآن والسنة"), artwork: .healing)
            }
            .buttonStyle(.yqPress)
            NavigationLink(value: DuaRoute.benefits) {
                BadgeTile(symbol: "sparkles", tint: .yqAccent,
                          title: copy("Why dhikr?", "لماذا الذكر؟"),
                          detail: copy("The benefits of adhkar", "فوائد الأذكار"), artwork: .praise)
            }
            .buttonStyle(.yqPress)
            NavigationLink { MushafView(language: language, showsTabBar: false) } label: {
                BadgeTile(symbol: "book.closed.fill", tint: .yqAccent,
                          title: copy("Mushaf", "المصحف"),
                          detail: AyahLibrary.shared.lastReadKey.flatMap { QuranStore.shared.ayah($0)?.reference(language) }
                              ?? copy("Read the Qur’an", "اقرأ القرآن"), artwork: .quran)
            }
            .buttonStyle(.yqPress)
            NavigationLink { AyahLibraryView(language: language) } label: {
                BadgeTile(symbol: "bookmark.fill", tint: .yqAccent,
                          title: copy("My ayat", "آياتي"),
                          detail: copy("Highlights and notes", "تظليلات وملاحظات"), artwork: .saved)
            }
            .buttonStyle(.yqPress)
        }
    }

}
