import SwiftUI
import UIKit

struct ExploreView: View {
    @Binding var path: NavigationPath
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var results: [Situation] { GuidanceCatalog.search(searchText) }
    private var groupColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

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
                columns: groupColumns,
                spacing: 12
            ) {
                ForEach(GuidanceCatalog.groups) { group in
                    NavigationLink(value: group) {
                        LifeGroupCard(group: group, language: language)
                    }
                    .buttonStyle(.yaqeenPressable)
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
                    .buttonStyle(.yaqeenPressable)
                }
            }
        }
    }
}

// MARK: - Group cards

struct LifeGroupCard: View {
    let group: LifeGroup
    let language: AppLanguage

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                cornerLayout
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityHint(language.pick("Opens this life group", "يفتح هذه المجموعة"))
    }

    private var cornerLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            LifeGroupArtwork(group: group)
                .scaledToFit()
                .frame(width: 68, height: 68)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)

            Spacer(minLength: 12)

            labels
        }
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
    }

    private var accessibilityLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            labels
                .frame(maxWidth: .infinity, alignment: .leading)

            LifeGroupArtwork(group: group)
                .scaledToFit()
                .frame(width: 62, height: 62)
                .accessibilityHidden(true)
        }
    }

    private var labels: some View {
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
}

private struct LifeGroupArtwork: View {
    let group: LifeGroup

    @ViewBuilder
    var body: some View {
        if let artwork = UIImage(named: group.id.artworkAssetName) {
            Image(uiImage: artwork)
                .resizable()
                .interpolation(.high)
        } else {
            Image(systemName: group.symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.sakinaInk)
                .padding(26)
                .background(Color.sakinaInk.opacity(0.08))
        }
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
                                .buttonStyle(.yaqeenPressable)
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
            LifeGroupArtwork(group: group)
                .scaledToFit()
                .frame(width: 94, height: 94)
                .accessibilityHidden(true)

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

typealias YaqeenPressStyle = YaqeenPressableButtonStyle
