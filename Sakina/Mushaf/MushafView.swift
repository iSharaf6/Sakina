import SwiftUI

/// The Qur'an reader. Two layouts: Madani pages (604 of them, each holding
/// exactly the ayat of the printed page) or one surah as flowing text.
/// Pages turn sideways or scroll down according to the Direction setting.
/// The navigation bar stays: surah in the middle, juz, Display and More on
/// the trailing side; the tab bar stays too when this is the Qur'an tab.
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
    @State private var focusKey: String?
    @State private var pulseKey: String?
    @State private var pulseVisible = false
    @State private var anchors: [String: CGRect] = [:]
    @State private var showSurahPicker = false
    @State private var showJuzPicker = false
    @State private var showPagePicker = false
    @State private var showDisplay = false
    @State private var showReciter = false
    @State private var textProxy = MushafTextProxy()
    @State private var tracker = ScrollTracker()

    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared

    @AppStorage(MushafPreferences.layoutKey) private var layout: MushafPreferences.Layout = .page
    @AppStorage(MushafPreferences.directionKey) private var direction: MushafPreferences.Direction = .horizontal
    @AppStorage(MushafPreferences.scriptKey) private var script: QuranScript = .uthmani
    @AppStorage(MushafPreferences.translationKey) private var translationEdition = QuranTranslationEdition.saheehInternational.id
    @AppStorage(MushafPreferences.showTranslationKey) private var showTranslation = false
    @AppStorage(MushafPreferences.fontScaleKey) private var fontScale = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var baseArabicSize = 24.0

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

    private struct TextTopKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    // MARK: Derived

    private var store: QuranStore { QuranStore.shared }
    private var surah: QuranSurah? { store.surah(surahNumber) }
    private var ayat: [QuranAyah] { store.ayat(in: surahNumber) }
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
        case .page: return store.firstAyah(onPage: page).flatMap { store.surah($0.surah) }
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
        .yqScreen()
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(showsTabBar ? .visible : .hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { surahButton }
            ToolbarItemGroup(placement: .topBarTrailing) {
                juzButton
                if layout == .page { pageBadge }
                displayButton
                moreMenu
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.playingKey != nil {
                MushafPlayerBar(language: language) { key in
                    open(key: key, pulse: true)
                }
            }
        }
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
        .task { await load() }
        .onChange(of: player.playingKey) { _, key in
            guard let key, let ayah = store.ayah(key) else { return }
            followAlong(ayah)
        }
        .onChange(of: layout) { old, new in
            switchLayout(from: old, to: new)
        }
        .onChange(of: page) { _, new in
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

    private var juzButton: some View {
        Button {
            Haptics.press()
            showJuzPicker = true
        } label: {
            Text(juzTitle)
                .font(.yqSubheadBold)
                .foregroundStyle(Color.yqInk)
                .lineLimit(1)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(copy("Choose juz", "اختر الجزء"))
        .accessibilityValue(juzTitle)
    }

    /// The page number as a small badge; tapping it opens the page picker.
    private var pageBadge: some View {
        Button {
            Haptics.press()
            showPagePicker = true
        } label: {
            Text(pageNumberText)
                .font(.yqCaptionBold)
                .monospacedDigit()
                .foregroundStyle(Color.yqInk)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yqFill, in: Capsule(style: .continuous))
                .overlay(Capsule(style: .continuous).strokeBorder(Color.yqHairline, lineWidth: 1))
                .contentShape(Capsule())
        }
        .accessibilityLabel(copy("Go to page", "الانتقال إلى صفحة"))
        .accessibilityValue(pageTitle)
    }

    private var displayButton: some View {
        Button {
            Haptics.press()
            showDisplay = true
        } label: {
            Image(systemName: "textformat.size")
        }
        .accessibilityLabel(copy("Display options", "خيارات العرض"))
    }

    private var moreMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "ellipsis.circle")
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
                    ScrollView {
                        pageView(number, windowed: true)
                            .frame(minHeight: geometry.size.height)
                    }
                    .scrollIndicators(.hidden)
                    .tag(tag)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .leftToRight)
        }
        .accessibilityLabel(copy("Mushaf pages", "صفحات المصحف"))
        .accessibilityValue(pageTitle)
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

    /// Pages stacked top to bottom and scrolled continuously: a Madani page
    /// is usually taller than a phone screen, so snapping to page edges
    /// would hide the bottom of every page. `scrolledPage` follows the page
    /// at the top of the visible region and drives jumps.
    private var verticalPages: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(1...QuranStore.pageCount, id: \.self) { number in
                        pageView(number, windowed: false)
                            .frame(minHeight: geometry.size.height)
                            .id(number)
                    }
                }
                .scrollTargetLayout()
            }
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
        .accessibilityLabel(copy("Mushaf pages", "صفحات المصحف"))
    }

    /// One page of the mushaf. A paged TabView keeps every child alive, so
    /// in the horizontal layout only the current page and its neighbours
    /// carry text; the rest are blank frames of the same shape.
    @ViewBuilder
    private func pageView(_ number: Int, windowed: Bool) -> some View {
        if windowed, abs(number - page) > 1 {
            PageFrame()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .accessibilityHidden(true)
        } else {
            MushafPageView(
                page: number,
                language: language,
                fontSize: fontSize,
                script: script,
                translationEdition: translationEdition,
                showTranslation: showTranslation,
                onTap: { ayah in
                    Haptics.tap()
                    selectedAyah = ayah
                },
                onPageTap: { showPagePicker = true }
            )
        }
    }

    // MARK: Surah layout

    private var surahReader: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 1).id("top")
                    if let surah {
                        SurahOpening(surah: surah, language: language)
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
            script: script,
            translationEdition: translationEdition,
            proxy: textProxy,
            onTap: { ayah in
                Haptics.tap()
                selectedAyah = ayah
            },
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
            await Task.detached(priority: .userInitiated) { _ = QuranStore.shared.isLoaded }.value
        }
        guard QuranStore.shared.isLoaded else { return }
        let key = initialKey ?? library.lastReadKey ?? "1:1"
        let ayah = store.ayah(key) ?? store.ayat.first
        surahNumber = ayah?.surah ?? 1
        currentJuz = ayah?.juz ?? 1
        page = ayah?.page ?? 1
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
            open(page: first.page)
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
            open(page: ayah.page)
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

    private func open(page number: Int) {
        let target = min(max(number, 1), QuranStore.pageCount)
        guard target != page else { return }
        Haptics.selection()
        page = target
    }

    /// Runs whenever the page changes, by swipe, scroll or a picker.
    private func pageDidChange(_ number: Int) {
        guard loaded, layout == .page, let first = store.firstAyah(onPage: number) else { return }
        currentJuz = first.juz
        library.lastReadKey = first.key
    }

    private func followAlong(_ ayah: QuranAyah) {
        switch layout {
        case .page:
            if ayah.page != page { page = ayah.page }
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
                page = ayah.page
                scrolledPage = ayah.page
                currentJuz = ayah.juz
            }
        case .surah:
            guard let first = store.firstAyah(onPage: page) else { return }
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
            if let first = store.firstAyah(onPage: page) { library.lastReadKey = first.key }
        case .surah:
            if let ayah = topmostVisibleAyah() { library.lastReadKey = ayah.key }
        }
    }
}
