import SwiftUI

struct ExploreView: View {
    @Binding var path: NavigationPath
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var results: [Situation] { GuidanceCatalog.search(searchText) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtmosphereBackground()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 26) {
                        header
                        searchField

                        if isSearching {
                            searchResults
                        } else {
                            NavigationLink {
                                QuickGuidanceView()
                            } label: {
                                QuickGuidanceShortcutCard(language: language)
                            }
                            .buttonStyle(YaqeenPressStyle())

                            groupsGrid
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 44)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationDestination(for: LifeGroup.self) { group in
                LifeGroupView(group: group)
            }
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            YaqeenMark()
                .frame(width: 38, height: 44)
                .foregroundStyle(Color.sakinaInk)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(copy("Explore", "استكشف"))
                    .font(.display(34))
                    .foregroundStyle(Color.sakinaInk)
                Text(copy("Start with the part of life you are in.", "ابدأ بالجانب الذي تعيشه الآن."))
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.sakinaMuted)

            TextField(
                copy("Search a feeling or situation", "ابحث عن شعور أو موقف"),
                text: $searchText
            )
            .font(.body)
            .foregroundStyle(Color.sakinaInk)
            .focused($searchFocused)
            .submitLabel(.search)

            if isSearching {
                Button {
                    searchText = ""
                    searchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.sakinaMuted)
                }
                .accessibilityLabel(copy("Clear search", "مسح البحث"))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.sakinaElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }

    private var groupsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionEyebrow(
                title: copy("Life groups", "مجموعات الحياة"),
                detail: copy("Choose where you need guidance", "اختر أين تحتاج إلى الهداية")
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(GuidanceCatalog.groups) { group in
                    NavigationLink(value: group) {
                        LifeGroupCard(group: group, language: language)
                    }
                    .buttonStyle(YaqeenPressStyle())
                }
            }
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow(
                title: results.isEmpty
                    ? copy("No match yet", "لا توجد نتيجة بعد")
                    : copy("Guidance", "هداية"),
                detail: results.isEmpty
                    ? copy("Try “worried”, “marriage”, or “debt”.", "جرّب «قلق» أو «زواج» أو «دَين». ")
                    : copy("\(results.count) relevant moments", "\(results.count) مواقف ذات صلة")
            )

            if results.isEmpty {
                EmptyGuidanceState(
                    title: copy("Your words matter", "كلماتك مهمة"),
                    detail: copy(
                        "Search with a simpler feeling or choose a life group below.",
                        "ابحث بكلمة أبسط أو اختر مجموعة من مجموعات الحياة."
                    ),
                    symbol: "text.magnifyingglass"
                )
                .padding(.top, 20)
            } else {
                ForEach(results) { situation in
                    NavigationLink(value: situation) {
                        SituationRow(situation: situation, language: language)
                    }
                    .buttonStyle(YaqeenPressStyle())
                }
            }
        }
    }
}

// MARK: - Group cards

struct LifeGroupCard: View {
    let group: LifeGroup
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.sakinaInk.opacity(0.08))
                Image(systemName: group.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.sakinaInk)
            }
            .frame(width: 42, height: 42)

            Spacer(minLength: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(group.title(language))
                    .font(.headline)
                    .foregroundStyle(Color.sakinaInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(group.situations.count == 1
                     ? language.pick("1 moment", "موقف واحد")
                     : language.pick("\(group.situations.count) moments", "\(group.situations.count) موقفًا"))
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .leading)
        .sakinaCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityHint(language.pick("Opens this life group", "يفتح هذه المجموعة"))
    }
}

// MARK: - Group detail

struct LifeGroupView: View {
    let group: LifeGroup

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedStageID: String
    @Namespace private var selectionNamespace

    init(group: LifeGroup) {
        self.group = group
        _selectedStageID = State(initialValue: group.stages.first?.id ?? "")
    }

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var selectedStage: GuidanceStage {
        group.stages.first { $0.id == selectedStageID } ?? group.stages[0]
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    groupHeader

                    Section {
                        VStack(alignment: .leading, spacing: 13) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(copy("What are you going through?", "بماذا تمر الآن؟"))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.sakinaInk)
                                Text(selectedStage.prompt(language))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.sakinaMuted)
                            }
                            .padding(.bottom, 3)

                            ForEach(selectedStage.situations) { situation in
                                NavigationLink(value: situation) {
                                    SituationRow(situation: situation, language: language)
                                }
                                .buttonStyle(YaqeenPressStyle())
                            }
                        }
                        .id(selectedStage.id)
                        .transition(.opacity)
                        .padding(.horizontal, 20)
                    } header: {
                        stagePicker
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 50)
            }
        }
        .navigationTitle(group.title(language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var groupHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.sakinaInk)
                Image(systemName: group.symbol)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.sakinaCanvas)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 8) {
                Text(group.title(language))
                    .font(.display(36))
                    .foregroundStyle(Color.sakinaInk)
                Text(group.subtitle(language))
                    .font(.body)
                    .foregroundStyle(Color.sakinaMuted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var stagePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(group.stages) { stage in
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 1)) {
                            selectedStageID = stage.id
                        }
                    } label: {
                        Text(stage.title(language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                selectedStageID == stage.id ? Color.sakinaCanvas : Color.sakinaInk
                            )
                            .padding(.horizontal, 15)
                            .frame(minHeight: 40)
                            .background {
                                if selectedStageID == stage.id {
                                    Capsule()
                                        .fill(Color.sakinaInk)
                                        .matchedGeometryEffect(id: "stage", in: selectionNamespace)
                                } else {
                                    Capsule().fill(Color.sakinaElevated)
                                }
                            }
                            .overlay(
                                Capsule().strokeBorder(
                                    selectedStageID == stage.id ? Color.clear : Color.sakinaHairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Shared guidance components

struct SituationRow: View {
    let situation: Situation
    let language: AppLanguage

    init(situation: Situation, language: AppLanguage = .english) {
        self.situation = situation
        self.language = language
    }

    /// Compatibility with the previous chapter-based row call sites.
    init(situation: Situation, hue: Color) {
        self.situation = situation
        self.language = .english
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(situation.localizedTitle(language))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    ResourceBadge(symbol: "book.closed", label: language.pick("Ayah", "آية"))
                    ResourceBadge(symbol: "text.book.closed", label: language.pick("Hadith", "حديث"))
                    ResourceBadge(symbol: "hands.sparkles", label: language.pick("Du’a", "دعاء"))
                }
            }

            Spacer(minLength: 10)

            Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.sakinaMuted.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.sakinaElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ResourceBadge: View {
    let symbol: String
    let label: String

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.sakinaMuted)
            .labelStyle(.titleAndIcon)
    }
}

struct SectionEyebrow: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.sakinaInk)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

struct EmptyGuidanceState: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.sakinaInk)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.sakinaInk)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.sakinaMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
    }
}

struct YaqeenPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
