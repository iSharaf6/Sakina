import SwiftUI

extension MushafPreferences {
    /// Page layout only: fit the whole page onto one screen, as printed.
    static let fitKey = "yaqeen.mushaf.fitPage"
}

/// The Qur'an reader. Two layouts: Madani pages (604 of them, each holding
/// exactly the ayat of the printed page) or one surah as flowing text.
/// Pages turn sideways or scroll down according to the Direction setting.
/// The compact toolbar offers surah navigation, focus mode and a reading
/// menu. Focus mode gives the page the space otherwise occupied by tabs.
struct MushafView: View {
    let language: AppLanguage
    private let initialKey: String?
    private let showsTabBar: Bool

    @State private var loaded = false
    @State private var page = 1
    @State private var scrolledPage: Int?
    @State private var surahNumber = 1
    @State private var currentJuz = 1
    @State private var selectedAyah: QuranAyah?
    @State private var activeAyah: QuranAyah?
    @State private var focusKey: String?
    @State private var pulseKey: String?
    @State private var pulseVisible = false
    @State private var anchors: [String: CGRect] = [:]
    @State private var showSurahPicker = false
    @State private var showJuzPicker = false
    @State private var showPagePicker = false
    @State private var showDisplay = false
    @State private var focusedReading = false
    @State private var showReciter = false
    @State private var showSettings = false
    @State private var textProxy = MushafTextProxy()
    @State private var tracker = ScrollTracker()

    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared

    @AppStorage(MushafPreferences.presentationKey) private var presentation: MushafPreferences.Presentation = .traditional
    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .system
    @AppStorage(SettingsKeys.transliterationVisible) private var showTransliteration = true
    @AppStorage("yaqeen.mushaf.didSelectAyah") private var didSelectAyah = false
    @AppStorage(MushafPreferences.layoutKey) private var layout: MushafPreferences.Layout = .page
    @AppStorage(MushafPreferences.directionKey) private var direction: MushafPreferences.Direction = .horizontal
    @AppStorage(MushafPreferences.scriptKey) private var script: QuranScript = .uthmani
    @AppStorage(MushafPreferences.translationKey) private var translationEdition = QuranTranslationEdition.saheehInternational.id
    @AppStorage(MushafPreferences.showTranslationKey) private var showTranslation = true
    @AppStorage(MushafPreferences.fontScaleKey) private var fontScale = 1.0
    @AppStorage("yaqeen.mushaf.printedPage") private var lastPrintedPage = 1
    @AppStorage("yaqeen.mushaf.printedKey") private var lastPrintedKey = ""

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var baseArabicSize = 28.0

    private var copy: AppCopy { AppCopy(language: language) }

    /// - Parameters:
    ///   - initialKey: an ayah to open on, e.g. "3:14"; otherwise the last read place.
    ///   - showsTabBar: true for the Qur'an tab root; pushed readers pass false.
    init(language: AppLanguage, initialKey: String? = nil, showsTabBar: Bool = true) {
        self.language = language
        self.initialKey = initialKey
        self.showsTabBar = showsTabBar
    }

    /// Non-state scroll bookkeeping: mutated every frame without re-rendering.
    final class ScrollTracker {
        var textTop: CGFloat = 0
        var visibleTask: Task<Void, Never>?
    }

    /// Snaps page by page when the pages are one screen tall; otherwise
    /// scrolls freely. One type, so the modifier needs no `AnyView`.
    private struct PageSnapping: ScrollTargetBehavior {
        var enabled: Bool
        func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
            guard enabled else { return }
            PagingScrollTargetBehavior().updateTarget(&target, context: context)
        }
    }

    private struct TextTopKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    // MARK: Derived

    private var store: QuranStore { QuranStore.shared }
    private var surah: QuranSurah? { store.surah(surahNumber) }
    private var ayat: [QuranAyah] { store.ayat(in: surahNumber) }
    private var printedLayout: Bool { presentation == .traditional && !MushafLineStore.shared.pages.isEmpty }
    private func readingPage(for ayah: QuranAyah) -> Int {
        printedLayout ? (MushafLineStore.shared.page(for: ayah.key) ?? ayah.page) : ayah.page
    }
    private func firstReadingAyah(on number: Int) -> QuranAyah? {
        if printedLayout, let key = MushafLineStore.shared.words(on: number).first?.k { return store.ayah(key) }
        return store.firstAyah(onPage: number)
    }
    private var readerBackground: Color { presentation == .traditional ? MushafPaper.background : Color.yqSurface }
    private var readerAccent: Color { presentation == .traditional ? MushafPaper.gold : .yqAccentDeep }
    private var fontSize: CGFloat { baseArabicSize * fontScale }

    private var highlights: [String: HighlightColor] {
        var result: [String: HighlightColor] = [:]
        for ayah in ayat {
            if let highlight = library.highlight(ayah.key) { result[ayah.key] = highlight }
        }
        return result
    }

    /// The surah shown in the bar: the page's first ayah in page mode.
    private var visibleSurah: QuranSurah? {
        switch layout {
        case .page: return firstReadingAyah(on: page).flatMap { store.surah($0.surah) }
        case .surah: return surah
        }
    }

    private var juzTitle: String {
        language == .arabic ? "الجزء \(QuranAyah.arabicDigits(currentJuz))" : "Juz \(currentJuz)"
    }

    private var pageNumberText: String {
        language == .arabic ? QuranAyah.arabicDigits(page) : String(page)
    }

    private var pageTitle: String {
        language == .arabic ? "صفحة \(pageNumberText)" : "Page \(page)"
    }

    // MARK: Body

    var body: some View {
        Group {
            if loaded {
                switch layout {
                case .page: pageReader
                case .surah: surahReader
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(readerBackground.ignoresSafeArea())
        .preferredColorScheme(theme.colorScheme)
        .tint(readerAccent)
        .toolbarBackground(readerBackground, for: .navigationBar)
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(showsTabBar && !focusedReading ? .visible : .hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { surahButton }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Haptics.press()
                    focusedReading.toggle()
                } label: {
                    Image(systemName: focusedReading ? "viewfinder.circle.fill" : "viewfinder")
                        .foregroundStyle(readerAccent)
                }
                .accessibilityLabel(copy(focusedReading ? "Show app tabs" : "Focus reading", focusedReading ? "إظهار التبويبات" : "القراءة بتركيز"))
                moreMenu
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { selectionDock }
        .sheet(item: $selectedAyah) { ayah in
            AyahActionSheet(ayah: ayah, language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSurahPicker) {
            SurahPickerSheet(language: language, current: visibleSurah?.number ?? surahNumber) { number in
                open(surah: number)
            }
        }
        .sheet(isPresented: $showJuzPicker) {
            JuzPickerSheet(language: language, current: currentJuz) { key in
                open(key: key, pulse: false)
            }
        }
        .sheet(isPresented: $showPagePicker) {
            PagePickerSheet(language: language, current: page) { number in
                open(page: number)
            }
        }
        .sheet(isPresented: $showDisplay) {
            MushafDisplaySheet(language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showReciter) {
            ReciterPickerSheet(language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(showsDismissButton: true)
        }
        .task { await load() }
        .onChange(of: player.playingKey) { _, key in
            guard let key, let ayah = store.ayah(key) else { return }
            followAlong(ayah)
        }
        .onChange(of: presentation) { _, new in
            activeAyah = nil
            if new == .traditional { layout = .page }
            restorePageAfterDisplayChange()
        }
        .onChange(of: script) { _, _ in restorePageAfterDisplayChange() }
        .onChange(of: layout) { old, new in
            switchLayout(from: old, to: new)
        }
        .onChange(of: page) { _, new in
            activeAyah = nil
            pageDidChange(new)
        }
        .onDisappear {
            tracker.visibleTask?.cancel()
            rememberPlace()
        }
    }

    // MARK: Top bar

    private var surahButton: some View {
        Button {
            Haptics.press()
            showSurahPicker = true
        } label: {
            HStack(spacing: 5) {
                if language == .arabic {
                    Text(visibleSurah?.nameArabic ?? "")
                        .font(.arabicProse(20))
                } else {
                    Text(visibleSurah?.nameSimple ?? "")
                        .font(.yqHeadline)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.yqSecondary)
            }
            .foregroundStyle(Color.yqInk)
            .lineLimit(1)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(copy("Choose surah", "اختر السورة"))
        .accessibilityValue(visibleSurah?.name(language) ?? "")
    }

    private var moreMenu: some View {
        Menu {
            Button { showDisplay = true } label: {
                Label(copy("Reading appearance", "مظهر القراءة"), systemImage: "textformat.size")
            }
            Button { showSurahPicker = true } label: {
                Label(copy("Choose surah", "اختر السورة"), systemImage: "list.bullet")
            }
            Button { showJuzPicker = true } label: {
                Label(copy("Choose juz", "اختر الجزء"), systemImage: "book")
            }
            Button { showPagePicker = true } label: {
                Label(copy("Go to page", "الانتقال إلى صفحة"), systemImage: "number")
            }
            Divider()
            NavigationLink {
                AyahLibraryView(language: language)
            } label: {
                Label(copy("My ayat", "آياتي"), systemImage: "bookmark")
            }
            Button {
                showReciter = true
            } label: {
                Label(copy("Reciter…", "القارئ…"), systemImage: "waveform")
            }
            Divider()
            Button {
                showSettings = true
            } label: {
                Label(copy("Settings", "الإعدادات"), systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(readerAccent)
        }
        .accessibilityLabel(copy("More", "المزيد"))
    }

    // MARK: Page layout

    @ViewBuilder
    private var pageReader: some View {
        switch direction {
        case .horizontal: horizontalPages
        case .vertical: verticalPages
        }
    }

    /// Pages turn like a bound mushaf: the next page lies to the left, so a
    /// finger moving right turns forward, in both app languages. Rather than
    /// trusting how a paged TabView treats right-to-left layout, the TabView
    /// is pinned left-to-right and its tags run backwards: tag 604 is page 1
    /// at the right end, tag 1 is page 604 at the left end. Moving to the
    /// tag on the left (tag − 1) is therefore page + 1. See `tag(forPage:)`.
    private var horizontalPages: some View {
        GeometryReader { geometry in
            TabView(selection: pageTag) {
                ForEach(1...QuranStore.pageCount, id: \.self) { tag in
                    let number = Self.page(forTag: tag)
                    if printedLayout {
                        // One screen, no scrolling: the page is fitted to it.
                        pageView(number, windowed: true, size: geometry.size)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .tag(tag)
                    } else {
                        ScrollView {
                            pageView(number, windowed: true, size: geometry.size)
                                .frame(minHeight: geometry.size.height)
                        }
                        .scrollIndicators(.hidden)
                        .tag(tag)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .leftToRight)
        }

    }

    /// The TabView tag for a page: pages count down from the right.
    static func tag(forPage page: Int) -> Int { QuranStore.pageCount + 1 - page }

    /// The page shown under a TabView tag; the inverse of `tag(forPage:)`.
    static func page(forTag tag: Int) -> Int { QuranStore.pageCount + 1 - tag }

    private var pageTag: Binding<Int> {
        Binding(
            get: { Self.tag(forPage: page) },
            set: { page = Self.page(forTag: $0) }
        )
    }

    /// Pages stacked top to bottom. Fitted pages are each one screen tall
    /// and the scroll snaps page by page; otherwise a Madani page is usually
    /// taller than a phone screen, so the scroll is continuous and snapping
    /// would hide the bottom of every page. `scrolledPage` follows the page
    /// at the top of the visible region and drives jumps.
    private var verticalPages: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(1...QuranStore.pageCount, id: \.self) { number in
                        if printedLayout {
                            pageView(number, windowed: false, size: geometry.size)
                                .frame(height: geometry.size.height)
                                .id(number)
                        } else {
                            pageView(number, windowed: false, size: geometry.size)
                                .frame(minHeight: geometry.size.height)
                                .id(number)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(PageSnapping(enabled: printedLayout))
            .scrollPosition(id: $scrolledPage)
            .scrollIndicators(.hidden)
            .onAppear { scrolledPage = page }
            .onChange(of: scrolledPage) { _, new in
                if let new, new != page { page = new }
            }
            .onChange(of: page) { _, new in
                if scrolledPage != new { scrolledPage = new }
            }
        }

    }

    /// One page of the mushaf. A paged TabView keeps every child alive, so
    /// in the horizontal layout only the current page and its neighbours
    /// carry text; the rest are blank frames of the same shape.
    @ViewBuilder
    private func pageView(_ number: Int, windowed: Bool, size: CGSize) -> some View {
        if windowed, abs(number - page) > 1 {
            readerBackground.accessibilityHidden(true)
        } else if printedLayout {
            PrintedMushafPage(page: number, language: language, onTap: selectAyah,
                             onPageTap: { showPagePicker = true }, onSurahTap: { showSurahPicker = true },
                             onJuzTap: { showJuzPicker = true }, selectedKey: activeAyah?.key)
        } else {
            VStack(spacing: 16) {
                digitalNavigation(number)
                ForEach(MushafPageView.segments(for: number)) { segment in
                    if segment.opensSurah { digitalOpening(segment.surah) }
                    MushafTextView(ayat: segment.ayat, surahName: segment.surah.name(language), language: language,
                                   fontSize: fontSize, highlights: digitalHighlights(segment.ayat),
                                   colorMarkers: library.colorReferenceMarks, playingKey: player.playingKey,
                                   showTranslation: showTranslation, showTransliteration: showTransliteration,
                                   selectedKey: activeAyah?.key, script: script, translationEdition: translationEdition,
                                   onTap: selectAyah)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Button(copy("Page \(number) · Go to page", "صفحة \(QuranAyah.arabicDigits(number)) · الانتقال لصفحة")) { showPagePicker = true }
                    .font(.yqCaption).padding(.vertical, 16)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24)
        }
    }

    private func digitalHighlights(_ ayat: [QuranAyah]) -> [String: HighlightColor] {
        Dictionary(uniqueKeysWithValues: ayat.compactMap { ayah in library.highlight(ayah.key).map { (ayah.key, $0) } })
    }
    private func digitalNavigation(_ number: Int) -> some View {
        HStack {
            Button { showJuzPicker = true } label: {
                HStack(spacing: 4) { Text(copy("Juz \(store.firstAyah(onPage: number)?.juz ?? 1)", "الجزء \(QuranAyah.arabicDigits(store.firstAyah(onPage: number)?.juz ?? 1))")); Image(systemName: "chevron.down") }
            }
            Spacer()
            Button { showDisplay = true } label: {
                HStack(spacing: 5) { Text(presentation.title(language)); Image(systemName: "textformat.size") }
            }
            Spacer()
            Button { showPagePicker = true } label: {
                HStack(spacing: 4) { Text(copy("Page \(number)", "صفحة \(QuranAyah.arabicDigits(number))")); Image(systemName: "chevron.down") }
            }
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.yqHairline).frame(height: 0.5).padding(.horizontal, 16) }
    }
    private func digitalOpening(_ surah: QuranSurah) -> some View {
        VStack(spacing: 10) {
            Button { showSurahPicker = true } label: {
                HStack { Text("سورة \(surah.nameArabic)").font(.arabicProse(25)); Image(systemName: "chevron.down").font(.caption) }
            }
            if surah.bismillahPre { BasmalahLine() }
        }
        .padding(.top, 12)
    }
    private func selectAyah(_ ayah: QuranAyah) {
        Haptics.tap()
        library.lastReadKey = ayah.key
        if activeAyah?.key == ayah.key {
            selectedAyah = ayah
            return
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            activeAyah = ayah
        }
        didSelectAyah = true
    }

    // A fixed dock keeps printed pages and Arabic line layout still during selection.
    // Only the controls animate; selecting an ayah never resizes the Qur’an text.
    @ScaledMetric(relativeTo: .subheadline) private var selectionDockHeight = 108.0

    private var selectionDock: some View {
        ZStack {
            if let activeAyah {
                AyahSelectionBar(ayah: activeAyah, language: language,
                                 onMore: { selectedAyah = activeAyah },
                                 onClose: {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { self.activeAyah = nil }
                })
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
            } else if player.playingKey != nil {
                MushafPlayerBar(language: language) { key in open(key: key, pulse: true) }
                    .transition(.opacity)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap").font(.title3).foregroundStyle(readerAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy("Tap an ayah", "اضغط على آية")).font(.yqSubheadBold)
                        Text(copy("Listen, save, or explore its meaning", "استمع أو احفظ أو اكتشف المعنى"))
                            .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .foregroundStyle(Color.yqInk)
                .transition(.opacity)
            }
        }
        .frame(height: selectionDockHeight)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: Surah layout

    private var surahReader: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 1).id("top")
                    if let surah {
                        digitalOpening(surah)
                            .padding(.top, 8)
                        Text(headerDetail(surah))
                            .font(.yqCaption)
                            .foregroundStyle(Color.yqSecondary)
                    }
                    textBlock
                    surahNavigation
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .coordinateSpace(name: "mushaf")
            .onPreferenceChange(TextTopKey.self) { value in
                tracker.textTop = value
                scheduleVisibleUpdate()
            }
            .onAppear {
                textProxy.onScroll = { top in
                    tracker.textTop = top
                    scheduleVisibleUpdate()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if direction == .horizontal { handleSwipe(value) }
                    }
            )
            .onChange(of: anchors) { _, _ in performFocus(scroll) }
            .onChange(of: focusKey) { _, _ in performFocus(scroll) }
            .onChange(of: surahNumber) { _, _ in
                anchors = [:]
                scroll.scrollTo("top", anchor: .top)
            }
        }
    }

    private func headerDetail(_ surah: QuranSurah) -> String {
        if language == .arabic {
            return "\(surah.placeName(language)) · \(QuranAyah.arabicDigits(surah.versesCount)) آية"
        }
        return "\(surah.nameSimple) · \(surah.placeName(language)) · \(surah.versesCount) ayat"
    }

    private var textBlock: some View {
        // Overlays never contribute to the parent's size, so the pulse and the
        // scroll anchors can sit at UIKit coordinates without re-wrapping the text.
        MushafTextView(
            ayat: ayat,
            surahName: surah?.name(language) ?? "",
            language: language,
            fontSize: fontSize,
            highlights: highlights,
            colorMarkers: library.colorReferenceMarks,
            playingKey: player.playingKey,
            showTranslation: showTranslation,
            showTransliteration: showTransliteration,
            selectedKey: activeAyah?.key,
            script: script,
            translationEdition: translationEdition,
            proxy: textProxy,
            onTap: selectAyah,
            onLayout: { rects in
                if rects != anchors { anchors = rects }
            }
        )
            .overlay(alignment: .topLeading) {
                if let pulseKey, let rect = anchors[pulseKey] {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.yqAccentTintStrong)
                        .frame(width: rect.width, height: rect.height)
                        .padding(.leading, rect.minX)
                        .padding(.top, rect.minY)
                        .opacity(pulseVisible ? 1 : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .topLeading) {
                ForEach(Array(anchors.keys), id: \.self) { key in
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id(key)
                        .padding(.top, anchors[key]?.minY ?? 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: TextTopKey.self, value: proxy.frame(in: .named("mushaf")).minY)
                }
            )
    }

    private var surahNavigation: some View {
        HStack(spacing: 12) {
            if let previous = store.surah(surahNumber - 1) {
                navigationButton(previous, forward: false)
            }
            if let next = store.surah(surahNumber + 1) {
                navigationButton(next, forward: true)
            }
        }
    }

    private func navigationButton(_ target: QuranSurah, forward: Bool) -> some View {
        let chevron = forward ? "chevron.forward" : "chevron.backward"
        let label = forward ? copy("Next surah", "السورة التالية") : copy("Previous surah", "السورة السابقة")
        return Button {
            open(surah: target.number)
        } label: {
            HStack(spacing: 8) {
                if !forward { Image(systemName: chevron).font(.system(size: 13, weight: .semibold)) }
                VStack(alignment: forward ? .trailing : .leading, spacing: 2) {
                    Text(label)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                    Text(target.name(language))
                        .font(language == .arabic ? .arabicProse(17) : .yqSubheadBold)
                        .foregroundStyle(Color.yqInk)
                }
                if forward { Image(systemName: chevron).font(.system(size: 13, weight: .semibold)) }
            }
            .foregroundStyle(Color.yqInk)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: forward ? .trailing : .leading)
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .yqCard(cornerRadius: 16)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.yqPress)
        .accessibilityLabel("\(label): \(target.name(language))")
    }

    // MARK: Loading and navigation

    private func load() async {
        if !loaded {
            // Decode off the main thread the first time; the store is a lazy singleton.
            await Task.detached(priority: .userInitiated) { _ = QuranStore.shared.isLoaded; _ = MushafLineStore.shared.pages.count }.value
        }
        guard QuranStore.shared.isLoaded else { return }
        let key = initialKey ?? library.lastReadKey ?? "1:1"
        let ayah = store.ayah(key) ?? store.ayat.first
        surahNumber = ayah?.surah ?? 1
        currentJuz = ayah?.juz ?? 1
        page = ayah.map { readingPage(for: $0) } ?? 1
        if initialKey == nil, printedLayout, key == lastPrintedKey,
           MushafLineStore.shared.words(on: lastPrintedPage).contains(where: { $0.k == key }) {
            page = lastPrintedPage
        }
        scrolledPage = page
        loaded = true
        if let ayah {
            library.lastReadKey = ayah.key
            if layout == .surah, ayah.ayah > 1 || initialKey != nil {
                focusKey = ayah.key
                if initialKey != nil { pulseKey = ayah.key }
            }
        }
    }

    /// Jump to a surah: its first page in page mode, its text in surah mode.
    private func open(surah number: Int) {
        guard let first = store.ayat(in: number).first else { return }
        switch layout {
        case .page:
            open(page: readingPage(for: first))
        case .surah:
            guard number != surahNumber else { return }
            rememberPlace()
            Haptics.selection()
            pulseKey = nil
            surahNumber = number
            currentJuz = first.juz
            library.lastReadKey = first.key
        }
    }

    /// Jump to an ayah: its page in page mode, scrolled into view in surah mode.
    private func open(key: String, pulse: Bool) {
        guard let ayah = store.ayah(key) else { return }
        switch layout {
        case .page:
            open(page: readingPage(for: ayah))
        case .surah:
            if ayah.surah != surahNumber {
                rememberPlace()
                Haptics.selection()
                surahNumber = ayah.surah
            }
            currentJuz = ayah.juz
            library.lastReadKey = key
            pulseKey = pulse ? key : nil
            focusKey = key
        }
    }

    private func restorePageAfterDisplayChange() {
        guard loaded, let key = library.lastReadKey, let ayah = store.ayah(key) else { return }
        page = readingPage(for: ayah)
        scrolledPage = page
    }

    private func open(page number: Int) {
        let target = min(max(number, 1), QuranStore.pageCount)
        guard target != page else { return }
        Haptics.selection()
        page = target
    }

    /// Runs whenever the page changes, by swipe, scroll or a picker.
    private func pageDidChange(_ number: Int) {
        guard loaded, layout == .page, let first = firstReadingAyah(on: number) else { return }
        currentJuz = first.juz
        if !printedLayout || !MushafLineStore.shared.words(on: number).contains(where: { $0.k == library.lastReadKey }) {
            library.lastReadKey = first.key
        }
        if printedLayout {
            lastPrintedPage = number
            lastPrintedKey = library.lastReadKey ?? first.key
        }
    }

    private func followAlong(_ ayah: QuranAyah) {
        switch layout {
        case .page:
            if printedLayout, MushafLineStore.shared.words(on: page).contains(where: { $0.k == ayah.key }) { return }
            if readingPage(for: ayah) != page { page = readingPage(for: ayah) }
        case .surah:
            if ayah.surah != surahNumber {
                open(key: ayah.key, pulse: false)
            } else {
                focusKey = ayah.key
            }
        }
    }

    /// Keeps the reading place when the Display sheet changes the layout.
    private func switchLayout(from old: MushafPreferences.Layout, to new: MushafPreferences.Layout) {
        guard loaded, old != new else { return }
        switch new {
        case .page:
            let ayah = topmostVisibleAyah() ?? store.ayat(in: surahNumber).first
            if let ayah {
                page = readingPage(for: ayah)
                scrolledPage = readingPage(for: ayah)
                currentJuz = ayah.juz
            }
        case .surah:
            guard let first = firstReadingAyah(on: page) else { return }
            anchors = [:]
            surahNumber = first.surah
            currentJuz = first.juz
            pulseKey = nil
            focusKey = first.ayah > 1 ? first.key : nil
        }
    }

    private func performFocus(_ scroll: ScrollViewProxy) {
        guard let key = focusKey, anchors[key] != nil else { return }
        guard textProxy.scroll(to: key, animated: false) else { return }
        focusKey = nil
        // Settle once more after SwiftUI finishes its own layout pass.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            textProxy.scroll(to: key, animated: !reduceMotion)
            if pulseKey == key { runPulse() }
        }
    }

    private func runPulse() {
        pulseVisible = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(reduceMotion ? .linear(duration: 0.2) : .easeOut(duration: 1.1)) {
                pulseVisible = false
            }
            try? await Task.sleep(for: .milliseconds(1200))
            pulseKey = nil
        }
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) > 80, abs(dx) > abs(dy) * 2 else { return }
        // Same convention as the page layout in both app languages: the next
        // surah lies to the left, like the next page of a bound mushaf, so a
        // finger moving right turns forward.
        let forward = dx > 0
        open(surah: surahNumber + (forward ? 1 : -1))
    }

    // MARK: Reading position (surah layout)

    private func scheduleVisibleUpdate() {
        tracker.visibleTask?.cancel()
        tracker.visibleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled, layout == .surah else { return }
            if let ayah = topmostVisibleAyah(), ayah.juz != currentJuz {
                currentJuz = ayah.juz
            }
        }
    }

    /// The first ayah whose block is still at least partly on screen, using
    /// the text view's position inside the scroll view.
    private func topmostVisibleAyah() -> QuranAyah? {
        guard !anchors.isEmpty else { return ayat.first }
        let top = -tracker.textTop
        var best: (ayah: QuranAyah, minY: CGFloat)?
        for ayah in ayat {
            guard let rect = anchors[ayah.key], rect.maxY > top else { continue }
            if best == nil || rect.minY < best!.minY { best = (ayah, rect.minY) }
        }
        return best?.ayah ?? ayat.first
    }

    private func rememberPlace() {
        guard loaded else { return }
        switch layout {
        case .page:
            if printedLayout {
                if !MushafLineStore.shared.words(on: page).contains(where: { $0.k == library.lastReadKey }),
                   let first = firstReadingAyah(on: page) { library.lastReadKey = first.key }
                lastPrintedPage = page
                lastPrintedKey = library.lastReadKey ?? ""
            } else if let key = library.lastReadKey, let ayah = store.ayah(key), readingPage(for: ayah) == page {
                return
            } else if let first = firstReadingAyah(on: page) {
                library.lastReadKey = first.key
            }
        case .surah:
            if let ayah = topmostVisibleAyah() { library.lastReadKey = ayah.key }
        }
    }
}
