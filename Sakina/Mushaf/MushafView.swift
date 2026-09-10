import SwiftUI

/// The Qur'an reader: one surah at a time as a continuous Uthmani block,
/// with the surah and juz pickers in the top bar, an options menu, and a
/// slim recitation bar while audio plays.
struct MushafView: View {
    let language: AppLanguage
    private let initialKey: String?

    @State private var loaded = false
    @State private var surahNumber = 1
    @State private var currentJuz = 1
    @State private var selectedAyah: QuranAyah?
    @State private var focusKey: String?
    @State private var pulseKey: String?
    @State private var pulseVisible = false
    @State private var anchors: [String: CGRect] = [:]
    @State private var showTranslation = false
    @State private var showSurahPicker = false
    @State private var showJuzPicker = false
    @State private var textProxy = MushafTextProxy()
    @State private var tracker = ScrollTracker()

    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared

    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var baseArabicSize = 26.0

    private var copy: AppCopy { AppCopy(language: language) }

    init(language: AppLanguage, initialKey: String? = nil) {
        self.language = language
        self.initialKey = initialKey
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
    private var fontSize: CGFloat { baseArabicSize * arabicScale }

    private var highlights: [String: HighlightColor] {
        var result: [String: HighlightColor] = [:]
        for ayah in ayat {
            if let highlight = library.highlight(ayah.key) { result[ayah.key] = highlight }
        }
        return result
    }

    private var juzTitle: String {
        language == .arabic ? "الجزء \(QuranAyah.arabicDigits(currentJuz))" : "Juz \(currentJuz)"
    }

    // MARK: Body

    var body: some View {
        Group {
            if loaded {
                reader
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .yqScreen()
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { surahButton }
            ToolbarItemGroup(placement: .topBarTrailing) {
                juzButton
                optionsMenu
            }
        }
        .sheet(item: $selectedAyah) { ayah in
            AyahActionSheet(ayah: ayah, language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSurahPicker) {
            SurahPickerSheet(language: language, current: surahNumber) { number in
                open(surah: number)
            }
        }
        .sheet(isPresented: $showJuzPicker) {
            JuzPickerSheet(language: language, current: currentJuz) { key in
                open(key: key, pulse: false)
            }
        }
        .task { await load() }
        .onChange(of: player.playingKey) { _, key in
            guard let key, let ayah = store.ayah(key) else { return }
            if ayah.surah != surahNumber {
                open(key: key, pulse: false)
            } else {
                focusKey = key
            }
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
                    Text(surah?.nameArabic ?? "")
                        .font(.arabicProse(20))
                } else {
                    Text(surah?.nameSimple ?? "")
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
        .accessibilityValue(surah?.name(language) ?? "")
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
        }
        .accessibilityLabel(copy("Choose juz", "اختر الجزء"))
        .accessibilityValue(juzTitle)
    }

    private var optionsMenu: some View {
        Menu {
            Toggle(copy("Colour ayah markers", "تلوين أرقام الآيات"), isOn: $library.colorReferenceMarks)
            Toggle(copy("Show translation", "إظهار الترجمة"), isOn: $showTranslation)
            Section(copy("Arabic size", "حجم العربية")) {
                Button(copy("Smaller", "أصغر")) { arabicScale = max(0.8, arabicScale - 0.1) }
                Button(copy("Larger", "أكبر")) { arabicScale = min(1.6, arabicScale + 0.1) }
            }
            NavigationLink {
                AyahLibraryView(language: language)
            } label: {
                Label(copy("My ayat", "آياتي"), systemImage: "bookmark")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(copy("Reading options", "خيارات القراءة"))
    }

    // MARK: Reader

    private var reader: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 1).id("top")
                    surahHeader
                        .padding(.horizontal, 16)
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
                    .onEnded { value in handleSwipe(value) }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let key = player.playingKey, let ayah = store.ayah(key) {
                    playerBar(ayah: ayah)
                }
            }
            .onChange(of: anchors) { _, _ in performFocus(scroll) }
            .onChange(of: focusKey) { _, _ in performFocus(scroll) }
            .onChange(of: surahNumber) { _, _ in
                anchors = [:]
                scroll.scrollTo("top", anchor: .top)
            }
        }
    }

    private var surahHeader: some View {
        VStack(spacing: 10) {
            if let surah {
                Text(surah.nameArabic)
                    .font(.arabic(30))
                    .foregroundStyle(Color.yqInk)
                    .accessibilityAddTraits(.isHeader)
                Text(headerDetail(surah))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                if surah.bismillahPre {
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                        .font(.arabic(24))
                        .foregroundStyle(Color.yqInk)
                        .padding(.top, 6)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .yqCard()
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

    // MARK: Player bar

    private func playerBar(ayah: QuranAyah) -> some View {
        HStack(spacing: 12) {
            Button {
                focusKey = ayah.key
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(copy("Playing", "يُتلى الآن"))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                    Text(ayah.reference(language))
                        .font(.yqSubheadBold)
                        .foregroundStyle(Color.yqInk)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(copy("Scroll to the playing ayah", "الانتقال إلى الآية الجارية"))
            Spacer(minLength: 8)
            Button {
                Haptics.press()
                player.toggle(ayah.key)
            } label: {
                CircleButton(symbol: player.isPlaying ? "pause.fill" : "play.fill", size: 40, filled: true)
            }
            .buttonStyle(.yqPress)
            .accessibilityLabel(player.isPlaying ? copy("Pause", "إيقاف مؤقت") : copy("Play", "تشغيل"))
            Button {
                Haptics.press()
                player.stop()
            } label: {
                CircleButton(symbol: "stop.fill", size: 40)
            }
            .buttonStyle(.yqPress)
            .accessibilityLabel(copy("Stop", "إيقاف"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            Rectangle().fill(.regularMaterial).ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            Color.yqHairline.frame(height: 1)
        }
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
        loaded = true
        if let ayah, ayah.ayah > 1 || initialKey != nil {
            focusKey = ayah.key
            if initialKey != nil { pulseKey = ayah.key }
        }
    }

    private func open(surah number: Int) {
        guard store.surah(number) != nil, number != surahNumber else { return }
        rememberPlace()
        Haptics.selection()
        pulseKey = nil
        surahNumber = number
        currentJuz = store.ayat(in: number).first?.juz ?? currentJuz
        library.lastReadKey = "\(number):1"
    }

    private func open(key: String, pulse: Bool) {
        guard let ayah = store.ayah(key) else { return }
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
        // In Arabic layout the next surah is turned to from the left, like a
        // page in a bound mushaf; in Latin layout it lives on the right.
        let forward = layoutDirection == .rightToLeft ? dx > 0 : dx < 0
        open(surah: surahNumber + (forward ? 1 : -1))
    }

    // MARK: Reading position

    private func scheduleVisibleUpdate() {
        tracker.visibleTask?.cancel()
        tracker.visibleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
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
        guard loaded, let ayah = topmostVisibleAyah() else { return }
        library.lastReadKey = ayah.key
    }
}
