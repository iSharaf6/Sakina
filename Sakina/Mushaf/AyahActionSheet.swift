import SwiftUI
import UIKit

/// Everything a reader can do with one ayah: listen, read tafsir and the
/// translation, favourite, bookmark, share, copy, colour it, file it under a
/// category and write a note. Presented by the mushaf as a sheet.
struct AyahActionSheet: View {
    let ayah: QuranAyah
    let language: AppLanguage

    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SettingsKeys.translationVisible) private var meaningVisible = true
    @AppStorage(SettingsKeys.transliterationVisible) private var transliterationVisible = true
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(MushafPreferences.scriptKey) private var scriptRaw = QuranScript.uthmani.rawValue
    @AppStorage(MushafPreferences.translationKey) private var translationID = QuranTranslationEdition.saheehInternational.id

    @State private var note = ""
    @State private var noteLoaded = false
    @State private var noteSaveTask: Task<Void, Never>?
    @FocusState private var noteFocused: Bool

    @State private var showTranslation = false
    @State private var showTafsir = false
    @State private var tafsirEdition: TafsirService.Edition
    @State private var tafsir: TafsirState = .idle
    @State private var tafsirTask: Task<Void, Never>?

    @State private var showCategoryEditor = false
    @State private var copied = false
    @State private var scrollTarget: String?

    private enum TafsirState: Equatable {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    init(ayah: QuranAyah, language: AppLanguage) {
        self.ayah = ayah
        self.language = language
        _tafsirEdition = State(initialValue: .preferred(for: language))
    }

    private var copy: AppCopy { AppCopy(language: language) }
    private var key: String { ayah.key }
    private var script: QuranScript { QuranScript(rawValue: scriptRaw) ?? .uthmani }
    private var edition: QuranTranslationEdition {
        QuranTranslationStore.shared.edition(translationID) ?? .saheehInternational
    }
    private var translationText: String { QuranTranslationStore.shared.text(for: ayah, edition: translationID) }
    /// Whether the chosen translation reads right to left.
    private var translationIsRTL: Bool {
        ["arabic", "urdu", "persian", "farsi", "hebrew", "pashto", "sindhi", "kurdish", "dari", "uyghur"].contains(edition.language.lowercased())
    }
    private var sharedText: String { AyahLibraryCopy.shareText(for: ayah, language: language) }
    private var isThisPlaying: Bool { player.playingKey == key && player.isPlaying }
    private var isThisBuffering: Bool { player.playingKey == key && player.isBuffering }
    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    ayahCard
                    actionGrid
                    if showTranslation {
                        translationSection
                            .id("translation")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    highlightSection
                    categoriesSection
                    noteSection.id("note")
                    if showTafsir {
                        tafsirSection
                            .id("tafsir")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(90))
                    withAnimation(motion) { proxy.scrollTo(target, anchor: .top) }
                    scrollTarget = nil
                }
            }
        }
        .yqScreen(pattern: .none)
        .yaqeenLanguage(language)
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorSheet(language: language) { category in
                library.toggle(category: category, for: key)
            }
        }
        .onAppear {
            guard !noteLoaded else { return }
            note = library.note(key)
            noteLoaded = true
        }
        .onChange(of: note) { _, text in scheduleNoteSave(text) }
        .onDisappear { flushNote() }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Tag(text: ayah.reference(language))
                Text(copy("Juz \(ayah.juz) · Page \(ayah.page)", "الجزء \(QuranAyah.arabicDigits(ayah.juz)) · صفحة \(QuranAyah.arabicDigits(ayah.page))"))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button { dismiss() } label: { CircleButton(symbol: "xmark", size: 32) }
                    .buttonStyle(.yqPress)
                    .accessibilityLabel(copy("Close", "إغلاق"))
            }
            let inCategories = library.categories(for: key)
            if !inCategories.isEmpty {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(inCategories) { category in
                        Tag(text: category.title(language), tint: category.color.color)
                    }
                }
            }
        }
    }

    // MARK: Ayah card

    private var ayahCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // The renderer picks the script's font, colours tajweed and
            // draws the marks the KFGQPC font gets wrong in the system font.
            Text(QuranTextRenderer.swiftUI(ayah, script: script, size: 28 * arabicScale))
                .lineSpacing(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .rightToLeft)
                .textSelection(.enabled)
            if transliterationVisible, let text = QuranTransliterationStore.shared.text(for: key) {
                Text(text).font(.yqSubhead).lineSpacing(6).foregroundStyle(Color.yqSecondary)
                    .environment(\.layoutDirection, .leftToRight)
                    .textSelection(.enabled)
            }
            if meaningVisible {
            Text(translationText)
                .font(translationIsRTL ? .arabicProse(18) : .yqBody)
                .lineSpacing(6)
                .foregroundStyle(Color.yqInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, translationIsRTL ? .rightToLeft : .leftToRight)
                .textSelection(.enabled)
            }
            if let url = URL(string: ayah.canonicalURL) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text("\(edition.name) · Quran.com")
                        Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .bold))
                    }
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                }
            }
        }
        .padding(20)
        .yqCard(cornerRadius: 22)
    }

    // MARK: Actions

    private var actionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 18) {
            Button {
                Haptics.tap()
                player.toggle(key)
            } label: {
                ActionTile(symbol: isThisPlaying ? "pause.fill" : "play.fill",
                           title: isThisPlaying ? copy("Pause", "إيقاف") : copy("Listen", "استمع"),
                           active: isThisPlaying, busy: isThisBuffering)
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                withAnimation(motion) { showTafsir = true }
                if case .loaded = tafsir {} else { loadTafsir() }
                scrollTarget = "tafsir"
            } label: {
                ActionTile(symbol: "text.book.closed.fill", title: copy("Tafsir", "تفسير"), active: showTafsir)
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                withAnimation(motion) { showTranslation.toggle() }
                if showTranslation { scrollTarget = "translation" }
            } label: {
                ActionTile(symbol: "character.bubble.fill", title: copy("Translate", "ترجمة"), active: showTranslation)
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                library.toggleFavourite(key)
            } label: {
                ActionTile(symbol: library.isFavourite(key) ? "heart.fill" : "heart",
                           title: copy("Favourite", "مفضلة"), active: library.isFavourite(key))
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                library.toggleBookmark(key)
            } label: {
                ActionTile(symbol: library.isBookmarked(key) ? "bookmark.fill" : "bookmark",
                           title: copy("Bookmark", "علامة"), active: library.isBookmarked(key))
            }
            .buttonStyle(.yqPress)

            ShareLink(item: sharedText) {
                ActionTile(symbol: "square.and.arrow.up", title: copy("Share", "مشاركة"))
            }
            .buttonStyle(.yqPress)

            Button {
                UIPasteboard.general.string = sharedText
                Haptics.success()
                withAnimation(motion) { copied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(motion) { copied = false }
                }
            } label: {
                ActionTile(symbol: copied ? "checkmark" : "doc.on.doc",
                           title: copied ? copy("Copied", "نُسخ") : copy("Copy", "نسخ"), active: copied)
            }
            .buttonStyle(.yqPress)

            Button {
                Haptics.tap()
                scrollTarget = "note"
                noteFocused = true
            } label: {
                ActionTile(symbol: "note.text", title: copy("Note", "ملاحظة"), active: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .buttonStyle(.yqPress)
        }
    }

    // MARK: Translation

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Translation", "الترجمة")) {
                Button {
                    withAnimation(motion) { showTranslation = false }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.yqTertiary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(copy("Hide translation", "إخفاء الترجمة"))
            }
            VStack(alignment: .leading, spacing: 14) {
                editionMenu
                Text(translationText)
                    .font(translationIsRTL ? .arabicProse(21) : .system(.title3))
                    .lineSpacing(translationIsRTL ? 9 : 7)
                    .foregroundStyle(Color.yqInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, translationIsRTL ? .rightToLeft : .leftToRight)
                    .textSelection(.enabled)
                    .id(translationID)
                Text(copy("\(edition.name) · via Quran.com", "\(edition.name) · عبر Quran.com"))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
                if let url = URL(string: ayah.canonicalURL) {
                    Link(destination: url) {
                        HStack(spacing: 5) {
                            Text(copy("Read on Quran.com", "اقرأ على Quran.com")).font(.yqSubheadBold)
                            Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Color.yqAccentDeep)
                        .frame(minHeight: 36)
                    }
                }
            }
            .padding(20)
            .yqCard(cornerRadius: 22)
        }
    }

    /// Edition name with a chevron; a menu of every bundled translation.
    private var editionMenu: some View {
        Menu {
            ForEach(QuranTranslationStore.shared.editions) { candidate in
                Button {
                    guard candidate.id != translationID else { return }
                    Haptics.selection()
                    withAnimation(motion) { translationID = candidate.id }
                } label: {
                    if candidate.id == translationID {
                        Label(candidate.name, systemImage: "checkmark")
                    } else {
                        Text(candidate.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(edition.name)
                    .font(.yqSubheadBold)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Color.yqAccentDeep)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(Color.yqAccentTint, in: Capsule(style: .continuous))
        }
        .accessibilityLabel(copy("Translation edition", "إصدار الترجمة"))
        .accessibilityValue(edition.name)
    }

    // MARK: Highlight

    private var highlightSection: some View {
        let current = library.highlight(key)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Highlight", "التظليل"))
            HStack(spacing: 6) {
                ForEach(HighlightColor.allCases) { color in
                    Button {
                        Haptics.press()
                        library.setHighlight(color, for: key)
                    } label: {
                        HighlightSwatch(color: color, selected: current == color)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.title(language))
                    .accessibilityAddTraits(current == color ? .isSelected : [])
                }
                Button {
                    Haptics.press()
                    library.setHighlight(nil, for: key)
                } label: {
                    HighlightSwatch(color: nil, selected: current == nil)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy("No highlight", "بدون تظليل"))
                .accessibilityAddTraits(current == nil ? .isSelected : [])
                Spacer(minLength: 0)
            }
            Toggle(isOn: $library.colorReferenceMarks) {
                Text(copy("Colour the ayah marker too", "لوّن رقم الآية أيضًا"))
                    .font(.yqSubheadMedium)
                    .foregroundStyle(Color.yqInk)
            }
            .tint(.yqAccentDeep)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .yqCard(cornerRadius: 14)
        }
    }

    // MARK: Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Save to", "احفظ في"))
            FlowLayout(spacing: 8, lineSpacing: 8) {
                if library.customCategories.isEmpty {
                    ForEach(CategorySuggestion.all) { suggestion in
                        Button {
                            Haptics.press()
                            let category = library.addCategory(name: suggestion.name(language), symbol: suggestion.symbol, color: suggestion.color)
                            library.toggle(category: category, for: key)
                        } label: {
                            CategoryChip(symbol: suggestion.symbol, title: suggestion.name(language), tint: suggestion.color.color, selected: false)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ForEach(library.customCategories) { category in
                        let selected = library.isInCategory(category, key: key)
                        Button {
                            Haptics.press()
                            library.toggle(category: category, for: key)
                        } label: {
                            CategoryChip(symbol: category.symbol, title: category.title(language), tint: category.color.color, selected: selected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                Button {
                    Haptics.press()
                    showCategoryEditor = true
                } label: {
                    CategoryChip(symbol: "plus", title: copy("New", "جديد"), tint: .yqAccentDeep, selected: false, dashed: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy("New category", "تصنيف جديد"))
            }
            if library.customCategories.isEmpty {
                Text(copy("Start with one of these, or make your own.", "ابدأ بأحدها، أو أنشئ تصنيفك."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
            }
            feelingsSection
        }
    }

    // MARK: Feelings

    /// The feelings this ayah already belongs to come first, then the rest
    /// in their usual order.
    private var orderedMoods: [DuaMood] {
        let all = DuaMood.allCases
        return all.filter { library.isInMood($0, key: key) } + all.filter { !library.isInMood($0, key: key) }
    }

    private var feelingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Add to a feeling", "أضف إلى شعور"))
                .padding(.top, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(orderedMoods) { mood in
                        let selected = library.isInMood(mood, key: key)
                        Button {
                            Haptics.press()
                            withAnimation(motion) { library.toggle(mood: mood, for: key) }
                        } label: {
                            FeelingChip(symbol: mood.symbol, title: mood.title(language), selected: selected, artwork: mood.artwork)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .animation(motion, value: orderedMoods)
            Text(copy("Your ayat show up on that feeling's screen.", "تظهر آياتك في شاشة ذلك الشعور."))
                .font(.yqCaption)
                .foregroundStyle(Color.yqTertiary)
        }
    }

    // MARK: Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Your note", "ملاحظتك")) {
                if noteFocused {
                    Button {
                        noteFocused = false
                        flushNote()
                    } label: {
                        TextAction(title: copy("Done", "تم"))
                    }
                }
            }
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text(copy("Why this ayah speaks to you…", "لماذا تلامسك هذه الآية…"))
                        .font(.yqBody)
                        .foregroundStyle(Color.yqTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $note)
                    .font(.yqBody)
                    .foregroundStyle(Color.yqInk)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90)
                    .focused($noteFocused)
            }
            .padding(12)
            .yqCard()
            .onTapGesture { noteFocused = true }
        }
    }

    // MARK: Tafsir

    private var tafsirSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(copy("Tafsir", "التفسير")) {
                Button {
                    withAnimation(motion) { showTafsir = false }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.yqTertiary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(copy("Hide tafsir", "إخفاء التفسير"))
            }
            HStack(spacing: 8) {
                ForEach(TafsirService.Edition.allCases) { candidate in
                    Button {
                        guard candidate != tafsirEdition else { return }
                        Haptics.selection()
                        tafsirEdition = candidate
                        loadTafsir()
                    } label: {
                        Tag(text: candidate.title(language), filled: candidate == tafsirEdition)
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(candidate == tafsirEdition ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            tafsirBody
                .padding(20)
                .yqCard(cornerRadius: 22)
        }
    }

    @ViewBuilder
    private var tafsirBody: some View {
        switch tafsir {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView().tint(.yqAccentDeep)
                Text(copy("Loading tafsir…", "جارٍ تحميل التفسير…"))
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
        case .failed(let message):
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.yqTertiary)
                Text(message)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    Haptics.tap()
                    loadTafsir()
                } label: {
                    Text(copy("Retry", "أعد المحاولة"))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqAccentDeep)
                        .frame(minHeight: 40)
                        .padding(.horizontal, 18)
                        .background(Color.yqAccentTint, in: Capsule(style: .continuous))
                }
                .buttonStyle(.yqPressSoft)
            }
            .frame(maxWidth: .infinity)
        case .loaded(let text):
            VStack(alignment: .leading, spacing: 14) {
                Text(text)
                    .font(tafsirEdition.isArabic ? .arabicProse(18) : .yqBody)
                    .lineSpacing(tafsirEdition.isArabic ? 8 : 6)
                    .foregroundStyle(Color.yqInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, tafsirEdition.isArabic ? .rightToLeft : .leftToRight)
                    .textSelection(.enabled)
                if let url = URL(string: "\(ayah.canonicalURL)/tafsirs/\(tafsirEdition.slug)") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text(copy("From Quran.com · \(tafsirEdition.resourceName)", "من Quran.com · \(tafsirEdition.resourceName)"))
                            Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .bold))
                        }
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                    }
                }
            }
        }
    }

    private func loadTafsir() {
        tafsirTask?.cancel()
        let edition = tafsirEdition
        if let cached = TafsirService.shared.cached(for: key, edition: edition) {
            tafsir = .loaded(cached)
            return
        }
        tafsir = .loading
        tafsirTask = Task {
            do {
                let text = try await TafsirService.shared.tafsir(for: key, edition: edition)
                guard !Task.isCancelled, self.tafsirEdition == edition else { return }
                withAnimation(motion) { tafsir = .loaded(text) }
            } catch let failure as TafsirService.Failure {
                guard !Task.isCancelled, self.tafsirEdition == edition else { return }
                tafsir = .failed(failure.message(language))
            } catch {
                guard !Task.isCancelled, self.tafsirEdition == edition else { return }
                tafsir = .failed(copy("Couldn't load the tafsir right now.", "تعذّر تحميل التفسير الآن."))
            }
        }
    }

    // MARK: Note saving

    private func scheduleNoteSave(_ text: String) {
        guard noteLoaded else { return }
        noteSaveTask?.cancel()
        noteSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            if library.note(key) != text { library.setNote(text, for: key) }
        }
    }

    private func flushNote() {
        noteSaveTask?.cancel()
        noteSaveTask = nil
        guard noteLoaded, library.note(key) != note else { return }
        library.setNote(note, for: key)
    }
}

// MARK: - Pieces

/// A round action with its label under it.
private struct ActionTile: View {
    let symbol: String
    let title: String
    var active = false
    var busy = false

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(active ? Color.yqAccent : Color.yqFill)
                if busy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(active ? Color.yqOnAccent : Color.yqAccentDeep)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(active ? Color.yqOnAccent : Color.yqInk)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(width: 48, height: 48)
            Text(title)
                .font(.yqCaption)
                .foregroundStyle(active ? Color.yqAccentDeep : Color.yqSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// A capsule category chip: outlined normally, filled in its colour when on.
private struct CategoryChip: View {
    let symbol: String
    let title: String
    let tint: Color
    let selected: Bool
    var dashed = false

    private var onTint: Color {
        // Yellow is the one highlight colour white cannot sit on.
        HighlightColor.allCases.first { $0.color == tint }?.onColor ?? .white
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.yqSubheadMedium)
                .lineLimit(1)
        }
        .foregroundStyle(selected ? onTint : (dashed ? Color.yqAccentDeep : Color.yqInk))
        .padding(.horizontal, 13)
        .frame(minHeight: 40)
        .background(selected ? tint : Color.yqSurface, in: Capsule(style: .continuous))
        .overlay {
            if !selected {
                Capsule(style: .continuous)
                    .strokeBorder(dashed ? Color.yqAccentDeep.opacity(0.6) : Color.yqHairline,
                                  style: StrokeStyle(lineWidth: 1, dash: dashed ? [4, 3] : []))
            }
        }
        .contentShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}

/// Starter categories offered until the reader makes their own.
private struct CategorySuggestion: Identifiable {
    let id: String
    let english: String
    let arabic: String
    let symbol: String
    let color: HighlightColor

    func name(_ language: AppLanguage) -> String { language.pick(english, arabic) }

    static let all = [
        CategorySuggestion(id: "sad", english: "Sad", arabic: "حزين", symbol: "cloud.rain.fill", color: .blue),
        CategorySuggestion(id: "hope", english: "Hope", arabic: "أمل", symbol: "sun.max.fill", color: .orange),
        CategorySuggestion(id: "gratitude", english: "Gratitude", arabic: "امتنان", symbol: "leaf.fill", color: .green)
    ]
}

/// A selection has visible feedback before a full sheet covers the text.
struct AyahSelectionBar: View {
    let ayah: QuranAyah
    let language: AppLanguage
    let onMore: () -> Void
    let onClose: () -> Void
    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared
    private var isPlaying: Bool { player.playingKey == ayah.key && player.isPlaying }
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(ayah.reference(language)).font(.yqSubheadBold)
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark").padding(8) }
                    .accessibilityLabel(language.pick("Clear selection", "إلغاء التحديد"))
            }
            HStack(spacing: 12) {
                action(isPlaying ? language.pick("Pause", "إيقاف مؤقت") : language.pick("Listen", "استماع"), icon: isPlaying ? "pause.fill" : "play.fill") {
                    if isPlaying { player.pause() } else { player.play(from: ayah.key) }
                }
                action(library.isBookmarked(ayah.key) ? language.pick("Saved", "محفوظة") : language.pick("Save", "حفظ"), icon: library.isBookmarked(ayah.key) ? "bookmark.fill" : "bookmark") {
                    library.toggleBookmark(ayah.key)
                }
                action(language.pick("More", "المزيد"), icon: "ellipsis", perform: onMore)
            }
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
        .foregroundStyle(Color.yqInk)
    }
    private func action(_ title: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button { Haptics.press(); perform() } label: {
            Label(title, systemImage: icon).font(.yqSubheadBold)
                .frame(maxWidth: .infinity).frame(minHeight: 44)
                .background(Color.yqAccentTint, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).foregroundStyle(Color.yqAccentDeep)
    }
}
