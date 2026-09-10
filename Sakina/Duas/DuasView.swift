import SwiftUI

// MARK: - Du'as tab

/// Value-based routes inside the Du'as stack.
enum DuaRoute: Hashable {
    case feelings, counter, ruqyah, benefits, goals
}

struct DuasView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(DuaCollection.savedKey) private var savedRaw = ""
    @AppStorage(ReadingPlace.key) private var placesRaw = ""
    @AppStorage(PracticeLog.key) private var practiceLogRaw = ""
    @AppStorage(HeartLog.key) private var heartLogRaw = ""
    @State private var query = ""
    @State private var appeared = false
    private let showsNavigationBar: Bool

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    init(showsNavigationBar: Bool = false) {
        self.showsNavigationBar = showsNavigationBar
    }

    /// The fifteen collections in five rows of three.
    private static let tiles: [DuaPractice] = [
        .morning, .evening, .sleep,
        .tahajjud, .salah, .afterSalah,
        .istighfar, .praise, .salawat,
        .anytime, .ummah, .healing,
        .quran, .sunnah, .names,
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Du’a & dhikr", "الدعاء والذكر"),
                           subtitle: copy("For your day, and for what’s in your heart.", "ليومك، ولما في قلبك."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                SearchField(prompt: copy("A feeling, a du’a, a name…", "شعور، دعاء، اسم…"), text: $query, focus: $searchFocused)
                    .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                if isSearching {
                    searchResults
                } else {
                    heart.revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                    collections.revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                }
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
        .toolbar(showsNavigationBar ? .visible : .hidden, for: .navigationBar)
        .onAppear { appeared = true }
    }

    // MARK: Heart

    private var heart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("How’s your heart?", "كيف حال قلبك؟")) {
                NavigationLink { FeelingsView(language: language) } label: {
                    TextAction(title: copy("All \(DuaMood.allCases.count)", "الكل"))
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
                    NavigationLink { FeelingsView(language: language) } label: {
                        FeelingChip(symbol: "ellipsis", title: copy("More", "المزيد"), tint: BadgeTint.slate.color)
                    }
                    .buttonStyle(.yqPress)
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: Collections

    private var collections: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Collections", "المجموعات"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 10) {
                ForEach(Array(Self.tiles.enumerated()), id: \.element.id) { position, practice in
                    NavigationLink(value: practice) {
                        PracticeTile(practice: practice, language: language,
                                     detail: tileDetail(practice), done: PracticeLog.isDone(practice, in: practiceLogRaw))
                    }
                    .buttonStyle(.yqPress)
                    .revealed(position / 3, appeared: appeared, reduceMotion: reduceMotion)
                }
            }
        }
    }

    private func tileDetail(_ practice: DuaPractice) -> String {
        if PracticeLog.isDone(practice, in: practiceLogRaw) { return copy("Done today", "أُنجزت اليوم") }
        if ReadingPlace.entry(for: practice, in: placesRaw) != nil { return copy("Continue", "تابع") }
        return practice.countLabel(language)
    }

    // MARK: Search

    private var term: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var matchingMoods: [DuaMood] {
        DuaMood.allCases.filter { $0.title(language).localizedStandardContains(term) || $0.searchWords.contains { $0.localizedStandardContains(term) } }
    }
    private var matchingPractices: [DuaPractice] {
        DuaPractice.allCases.filter { $0.title(language).localizedStandardContains(term) }
    }
    private var matchingNames: [DivineName] {
        DivineName.all.filter { $0.arabic.localizedStandardContains(term) || $0.transliteration.localizedStandardContains(term) || $0.meaning(language).localizedStandardContains(term) }
    }

    private var searchResults: some View {
        let entries = DuaCollection.entries(query: query)
        return VStack(alignment: .leading, spacing: 16) {
            if !matchingMoods.isEmpty {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(matchingMoods) { mood in
                        NavigationLink(value: mood) {
                            FeelingChip(symbol: mood.symbol, title: mood.title(language), artwork: mood.artwork)
                        }
                        .buttonStyle(.yqPress)
                    }
                }
            }
            if !matchingPractices.isEmpty || !matchingNames.isEmpty {
                RowGroup {
                    ForEach(Array(matchingPractices.enumerated()), id: \.element.id) { i, practice in
                        NavigationLink(value: practice) {
                            BadgeRow(symbol: practice.symbol, tint: practice.tint, title: practice.title(language), subtitle: practice.countLabel(language), artwork: practice.artwork)
                        }
                        .buttonStyle(.yqPressSoft)
                        if i < matchingPractices.count - 1 || !matchingNames.isEmpty { RowDivider() }
                    }
                    ForEach(Array(matchingNames.prefix(6).enumerated()), id: \.element.id) { i, name in
                        NavigationLink { NamesOfAllahView(language: language, initialNameID: name.id) } label: {
                            BadgeRow(symbol: DuaPractice.names.symbol, tint: DuaPractice.names.tint, title: name.transliteration, subtitle: name.meaning(language), artwork: .names)
                        }
                        .buttonStyle(.yqPressSoft)
                        if i < min(6, matchingNames.count) - 1 { RowDivider() }
                    }
                }
            }
            if !entries.isEmpty {
                SectionHeader(copy("Du’as", "الأدعية"))
                RowGroup {
                    ForEach(Array(entries.prefix(25).enumerated()), id: \.element.id) { i, dua in
                        NavigationLink(value: dua) {
                            DuaListRow(dua: dua, index: i + 1, language: language, saved: DuaCollection.savedIDs(savedRaw).contains(dua.id))
                        }
                        .buttonStyle(.yqPressSoft)
                        if i < min(25, entries.count) - 1 { RowDivider(inset: 54) }
                    }
                }
            }
            if entries.isEmpty && matchingMoods.isEmpty && matchingPractices.isEmpty && matchingNames.isEmpty {
                DuaEmptyState(savedOnly: false, language: language)
            }
        }
    }
}

// MARK: - Practice tile

struct PracticeTile: View {
    let practice: DuaPractice
    let language: AppLanguage
    var detail: String
    var done = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                CompanionIllustration(artwork: practice.artwork, size: 68)
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.yqAccent, Color.yqSurface)
                        .offset(x: 2, y: -2)
                }
            }
            VStack(spacing: 2) {
                Text(practice.shortTitle(language))
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(detail)
                    .font(.yqCaption)
                    .foregroundStyle(done ? Color.yqAccentDeep : Color.yqSecondary)
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 128)
        .yqCard(cornerRadius: 18)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Feelings cloud

struct FeelingsView: View {
    let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(HeartLog.key) private var heartLogRaw = ""
    @State private var appeared = false
    private var copy: AppCopy { AppCopy(language: language) }

    private var recent: [DuaMood] {
        var seen = Set<DuaMood>()
        return HeartLog.entries(heartLogRaw).reversed().map(\.mood).filter { seen.insert($0).inserted }.prefix(4).map { $0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("How’s your heart, really?", "كيف حال قلبك حقًا؟"),
                           subtitle: copy("One tap. There’s no wrong answer.", "ضغطة واحدة، ولا توجد إجابة خاطئة."))
                if !recent.isEmpty {
                    band(title: copy("Recently", "مؤخرًا"), tint: BadgeTint.slate.color, moods: recent, order: 0)
                }
                ForEach(Array(FeelingFamily.allCases.enumerated()), id: \.element.id) { position, family in
                    band(title: family.title(language), subtitle: family.line(language), tint: family.tint, moods: family.moods, order: position + 1)
                }
                Text(copy("Feelings lead to reflections from the Qur’an and Sunnah. They are not prescriptions for an emotion.",
                          "تقود المشاعر إلى تأملات من القرآن والسنة، وليست وصفات لكل شعور."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationDestination(for: DuaMood.self) { MoodDetailView(mood: $0, language: language) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }

    private func band(title: String, subtitle: String? = nil, tint: Color, moods: [DuaMood], order: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let headingLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            headingLayout {
                Text(title).font(.yqHeadline).foregroundStyle(tint)
                if let subtitle {
                    Text(subtitle).font(.yqCaption).foregroundStyle(Color.yqTertiary)
                }
            }
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(moods) { mood in
                    NavigationLink(value: mood) {
                        FeelingChip(symbol: mood.symbol, title: mood.title(language), artwork: mood.artwork)
                    }
                    .buttonStyle(.yqPress)
                }
            }
        }
        .revealed(order, appeared: appeared, reduceMotion: reduceMotion)
    }
}

/// Legacy name.
typealias FeelingBrowseView = FeelingsView

// MARK: - Feeling → reader

extension DuaMood {
    /// One warm line that meets the person before the first du’a.
    func opening(_ language: AppLanguage) -> String {
        if let line = FeelingLibrary.opening(for: self, language: language) { return line }
        switch family {
        case .heavy: return language.pick("It’s heavy. You don’t have to carry it alone.", "الحمل ثقيل، ولست وحدك في حمله.")
        case .restless: return language.pick("Your heart is racing. Let it slow down here.", "قلبك يتسارع. دعه يهدأ هنا.")
        case .direction: return language.pick("The way isn’t clear yet. Ask the One who knows it.", "الطريق غير واضح بعد. اسأل من يعلمه.")
        case .returning: return language.pick("The door back is open. It always was.", "باب العودة مفتوح، وما زال كذلك.")
        case .peace: return language.pick("Good days are a gift. Say thank you for it.", "الأيام الطيبة نعمة، فاشكرها.")
        case .energy: return language.pick("Running low is allowed. Ask for strength.", "لا بأس أن تتعب. اطلب القوة.")
        }
    }
}

/// Per-feeling copy and mappings supplied by the content library when present.
enum FeelingLibrary {
    static var openings: [DuaMood: (english: String, arabic: String)] = DuaLibrary.openings
    static func opening(for mood: DuaMood, language: AppLanguage) -> String? {
        guard let line = openings[mood] else { return nil }
        return language.pick(line.english, line.arabic)
    }
}

struct MoodDetailView: View {
    let mood: DuaMood
    let language: AppLanguage
    private var copy: AppCopy { AppCopy(language: language) }
    private var entries: [GuidanceSupplication] { DuaCollection.entries(mood: mood) }
    private var title: String { copy("For when you feel \(mood.title(language).lowercased())", "حين تشعر أنك \(mood.title(language))") }

    var body: some View {
        if let first = entries.first {
            DuaReaderView(dua: first, sequence: entries, collectionTitle: title, mood: mood)
        } else {
            EmptyGuidanceState(title: copy("Nothing here yet", "لا يوجد شيء بعد"),
                               detail: copy("Try another feeling.", "جرّب شعورًا آخر."), symbol: "heart", artwork: mood.artwork)
                .yqScreen()
        }
    }
}

struct PracticeDestination: View {
    let practice: DuaPractice
    let language: AppLanguage
    var body: some View {
        if practice == .names {
            NamesOfAllahView(language: language)
        } else if let first = practice.entries.first {
            DuaReaderView(dua: first, sequence: practice.entries, collectionTitle: practice.title(language), practice: practice)
        } else {
            EmptyGuidanceState(title: language.pick("Coming soon", "قريبًا"), detail: practice.invitation(language), symbol: practice.symbol, artwork: practice.artwork)
                .yqScreen()
        }
    }
}

// MARK: - Rows and empty states

struct DuaListRow: View {
    let dua: GuidanceSupplication
    let index: Int
    let language: AppLanguage
    var saved = false

    var body: some View {
        HStack(spacing: 12) {
            Text(index.formatted(.number.locale(language.locale)))
                .font(.system(.caption, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.yqTertiary)
                .frame(width: 26, height: 26)
                .background(Color.yqFill, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(dua.title(language))
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(DuaCollection.sourceLabel(dua, language: language))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
            }
            Spacer(minLength: 0)
            if saved {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.yqAccent)
            }
            Chevron()
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct DuaEmptyState: View {
    let savedOnly: Bool
    let language: AppLanguage
    var body: some View {
        EmptyGuidanceState(
            title: savedOnly ? language.pick("Keep a few words close.", "احتفظ بكلمات قريبة من قلبك.")
                             : language.pick("Let’s try another word.", "لنجرّب كلمة أخرى."),
            detail: savedOnly
                ? language.pick("Save a du’a as you read. It will be here whenever you need it.", "احفظ دعاءً أثناء القراءة، وستجده هنا كلما احتجت إليه.")
                : language.pick("Try a feeling, a title, or a reference such as 28:24.", "جرّب شعورًا أو عنوانًا أو مرجعًا مثل 28:24."),
            symbol: savedOnly ? "bookmark" : "magnifyingglass",
            artwork: savedOnly ? .saved : .lost
        )
    }
}
