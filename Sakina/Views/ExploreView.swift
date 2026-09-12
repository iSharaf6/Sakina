import SwiftUI

struct ExploreView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var path: NavigationPath
    @Binding var searchText: String
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @FocusState private var searchFocused: Bool
    @State private var appeared = false
    @State private var showSettings = false

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var results: [Situation] { GuidanceCatalog.search(searchText) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top, spacing: 12) {
                        PageHeader(title: copy("Explore", "استكشف"),
                                   subtitle: copy("Qur’an and Sunnah for the season you’re in.", "قرآن وسنة للمرحلة التي تعيشها."))
                        SettingsButton(language: language) { showSettings = true }
                    }
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                    SearchField(prompt: copy("A feeling or a situation", "شعور أو موقف"), text: $searchText, focus: $searchFocused)
                        .revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                    if isSearching {
                        searchResults
                    } else {
                        ayahNow.revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                        nearYou.revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                        groups.revealed(4, appeared: appeared, reduceMotion: reduceMotion)
                        feelingRow.revealed(5, appeared: appeared, reduceMotion: reduceMotion)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .yqScreen()
            .navigationDestination(for: LifeGroup.self) { LifeGroupView(group: $0) }
            .navigationDestination(for: Situation.self) { SituationDetailView(situation: $0) }
            .navigationDestination(for: DuaRoute.self) { route in
                switch route {
                case .feelings: FeelingsView(language: language)
                case .counter: DhikrListView(language: language)
                case .ruqyah: RuqyahView(language: language)
                case .benefits: AdhkarBenefitsView(language: language)
                case .goals: DailyGoalsView(language: language)
                }
            }
            .navigationDestination(for: DuaMood.self) { MoodDetailView(mood: $0, language: language) }
            .navigationDestination(for: NearbyPlaceKind.self) { NearbyPlacesView(kind: $0, language: language) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(showsDismissButton: true) }
            .onAppear { appeared = true }
        }
    }

    // MARK: Sections

    private var ayahNow: some View {
        NavigationLink { QuickGuidanceView() } label: {
            HStack(spacing: 14) {
                CompanionIllustration(artwork: .quran, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(copy("An ayah for right now", "آية لهذه اللحظة"))
                        .font(.yqHeadline)
                        .foregroundStyle(Color.yqInk)
                    Text(copy("Worry · feeling lost · setbacks · hope", "القلق · الضياع · الانتكاسات · الأمل"))
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Chevron()
            }
            .multilineTextAlignment(.leading)
            .padding(14)
            .yqCard(cornerRadius: 20)
        }
        .buttonStyle(.yqPress)
    }

    private var nearYou: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Near you", "بالقرب منك"))
            RowGroup {
                NavigationLink { NearbyPlacesView(kind: .mosques, language: language) } label: {
                    BadgeRow(symbol: "building.columns.fill", title: copy("Mosques near me", "مساجد قريبة"),
                             subtitle: copy("Apple Maps and OpenStreetMap, cross-checked", "خرائط Apple وOpenStreetMap مع مطابقة"))
                }
                .buttonStyle(.yqPressSoft)
                RowDivider()
                NavigationLink { NearbyPlacesView(kind: .halal, language: language) } label: {
                    BadgeRow(symbol: "fork.knife", title: copy("Halal food near me", "طعام حلال قريب"),
                             subtitle: copy("Confirm with the restaurant before you order", "تأكد من المطعم قبل الطلب"))
                }
                .buttonStyle(.yqPressSoft)
            }
        }
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Where are you in life?", "أين أنت من الحياة؟"))
            RowGroup {
                ForEach(Array(GuidanceCatalog.groups.enumerated()), id: \.element.id) { index, group in
                    NavigationLink(value: group) {
                        BadgeRow(symbol: group.badgeSymbol, tint: group.tint, title: group.title(language),
                                 subtitle: group.stages.prefix(2).map { $0.title(language) }.joined(separator: " · "),
                                 artwork: group.artwork, subtitleLines: 1) {
                            HStack(spacing: 8) {
                                Text("\(group.situations.count)")
                                    .font(.system(.caption, weight: .semibold).monospacedDigit())
                                    .foregroundStyle(Color.yqTertiary)
                                Chevron()
                            }
                        }
                    }
                    .buttonStyle(.yqPressSoft)
                    if index < GuidanceCatalog.groups.count - 1 { RowDivider() }
                }
            }
        }
    }

    private var feelingRow: some View {
        NavigationLink(value: DuaRoute.feelings) {
            HStack(spacing: 14) {
                CompanionIllustration(artwork: .breathe, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy("Start with a feeling", "ابدأ بشعور"))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqInk)
                    Text(copy("\(DuaMood.allCases.count) feelings, one tap to a du’a.", "\(DuaMood.allCases.count) شعورًا، وضغطة واحدة إلى دعاء."))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }
                Spacer(minLength: 0)
                Chevron()
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .frame(minHeight: 60)
            .yqCard()
        }
        .buttonStyle(.yqPress)
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            let moods = DuaMood.allCases.filter { mood in
                let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                return mood.title(language).localizedStandardContains(term) || mood.searchWords.contains { $0.localizedStandardContains(term) }
            }
            if !moods.isEmpty {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(moods) { mood in
                        NavigationLink(value: mood) {
                            FeelingChip(symbol: mood.symbol, title: mood.title(language), artwork: mood.artwork)
                        }
                        .buttonStyle(.yqPress)
                    }
                }
            }
            SectionHeader(results.isEmpty ? copy("No match yet", "لا توجد نتيجة بعد") : copy("Guidance", "هداية")) {
                if !results.isEmpty {
                    Text(results.count == 1 ? copy("1 moment", "موقف واحد") : copy("\(results.count) moments", "\(results.count) مواقف"))
                        .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                }
            }
            if results.isEmpty {
                EmptyGuidanceState(
                    title: copy("No matching moments", "لا توجد مواقف مطابقة"),
                    detail: copy("Try a simpler feeling, or choose a life group.", "ابحث بكلمة أبسط أو اختر مجموعة من مجموعات الحياة."),
                    symbol: "text.magnifyingglass", artwork: .evening
                )
            } else {
                RowGroup {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, situation in
                        NavigationLink(value: situation) {
                            SituationRow(situation: situation, language: language)
                        }
                        .buttonStyle(.yqPressSoft)
                        if index < results.count - 1 { RowDivider(inset: 58) }
                    }
                }
            }
        }
    }
}

// MARK: - Group detail (stages flattened into sections)

struct LifeGroupView: View {
    let group: LifeGroup
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 14) {
                    CompanionIllustration(artwork: group.artwork, size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.title(language))
                            .font(.yqLargeTitle)
                            .tracking(-0.4)
                            .foregroundStyle(Color.yqInk)
                        Text(group.subtitle(language))
                            .font(.yqSubhead)
                            .foregroundStyle(Color.yqSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                ForEach(Array(group.stages.enumerated()), id: \.element.id) { index, stage in
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.title(language)).font(.yqSection).foregroundStyle(Color.yqInk)
                            Text(stage.prompt(language)).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        }
                        RowGroup {
                            ForEach(Array(stage.situations.enumerated()), id: \.element.id) { position, situation in
                                NavigationLink(value: situation) {
                                    SituationRow(situation: situation, language: language, tint: group.tint, showsBadge: false)
                                }
                                .buttonStyle(.yqPressSoft)
                                if position < stage.situations.count - 1 { RowDivider(inset: 14) }
                            }
                        }
                    }
                    .revealed(index + 1, appeared: appeared, reduceMotion: reduceMotion)
                }
                Text(copy("Choose one moment. Take one thing with you.", "اختر موقفًا واحدًا، وخذ منه ما ينفعك."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .yqScreen()
        .navigationDestination(for: Situation.self) { SituationDetailView(situation: $0) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }
}

// MARK: - Shared rows

struct SituationRow: View {
    let situation: Situation
    let language: AppLanguage
    var tint: Color? = nil
    var showsBadge = true

    init(situation: Situation, language: AppLanguage = .english, tint: Color? = nil, showsBadge: Bool = true) {
        self.situation = situation
        self.language = language
        self.tint = tint
        self.showsBadge = showsBadge
    }

    /// Compatibility with the previous chapter-based row call sites.
    init(situation: Situation, hue: Color) {
        self.init(situation: situation, language: .english)
    }

    private var group: LifeGroup { GuidanceCatalog.group(containing: situation) }

    var body: some View {
        HStack(spacing: 12) {
            if showsBadge {
                CompanionIllustration(artwork: group.artwork, size: 42)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(situation.localizedTitle(language))
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(situation.referenceLabel)
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Chevron()
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
