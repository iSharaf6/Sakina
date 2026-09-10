import SwiftUI

// MARK: - Page
//
// One Madani mushaf page: exactly the ayat the printed page holds, inside a
// quiet book frame. A surah that begins on the page gets the cartouche
// banner and, where the mushaf prints it, the basmalah. The text itself is
// still `MushafTextView`, one per surah segment, so a page that ends one
// surah and opens the next shows the banner between two text blocks.
//
// With a `Fit`, the page fills one screen exactly, as a printed page does:
// the text is set at the largest size at which the whole page fits (see
// `fittedFontSize`), so a memoriser sees every page as one shape.

struct MushafPageView: View {
    /// How a page is fitted to one screen.
    struct Fit: Equatable {
        /// The area the page, outer padding included, fills exactly.
        let size: CGSize
        /// The largest font size at which the page's text fits, from
        /// `MushafPageView.fittedFontSize`.
        let fontSize: CGFloat
    }

    let page: Int
    let language: AppLanguage
    let fontSize: CGFloat
    let script: QuranScript
    let translationEdition: Int
    let showTranslation: Bool
    /// When set, the page is fitted to one screen and never scrolls;
    /// the translation is not shown.
    var fit: Fit? = nil
    var onTap: (QuranAyah) -> Void
    var onPageTap: () -> Void = {}

    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared

    /// A run of ayat from one surah on this page.
    struct Segment: Identifiable {
        let surah: QuranSurah
        let ayat: [QuranAyah]
        var id: Int { surah.number }
        /// The surah opens on this page, so it gets its banner.
        var opensSurah: Bool { ayat.first?.ayah == 1 }
    }

    private var store: QuranStore { QuranStore.shared }

    /// The page's ayat grouped by surah, in mushaf order.
    static func segments(for page: Int) -> [Segment] {
        let store = QuranStore.shared
        var result: [Segment] = []
        for ayah in store.ayat(onPage: page) {
            if let last = result.last, last.surah.number == ayah.surah {
                result[result.count - 1] = Segment(surah: last.surah, ayat: last.ayat + [ayah])
            } else if let surah = store.surah(ayah.surah) {
                result.append(Segment(surah: surah, ayat: [ayah]))
            }
        }
        return result
    }

    private var juzTitle: String {
        let juz = store.firstAyah(onPage: page)?.juz ?? 1
        return language == .arabic ? "الجزء \(QuranAyah.arabicDigits(juz))" : "Juz \(juz)"
    }

    private func highlights(for ayat: [QuranAyah]) -> [String: HighlightColor] {
        var result: [String: HighlightColor] = [:]
        for ayah in ayat {
            if let highlight = library.highlight(ayah.key) { result[ayah.key] = highlight }
        }
        return result
    }

    // MARK: Fitting

    /// Every dimension that goes into fitting a page, so the measurement in
    /// `fittedFontSize` and the fitted body agree to the point.
    enum Metrics {
        /// Around the frame: the outer padding of every page view.
        static let outerHorizontal: CGFloat = 10
        static let outerVertical: CGFloat = 8
        /// Between the frame and each text block.
        static let textHorizontal: CGFloat = 6

        static let headerHeight: CGFloat = 22
        static let headerTop: CGFloat = 10
        static let headerBottom: CGFloat = 2
        static let bannerHeight: CGFloat = 42
        static let openingTop: CGFloat = 4
        static let openingSpacing: CGFloat = 4
        static let badgeHeight: CGFloat = 26
        static let badgeTop: CGFloat = 4
        static let badgeBottom: CGFloat = 10

        /// Tighter than the reading layout's 0.55: a page is a block.
        static let lineSpacingFactor: CGFloat = 0.42
        static let minimumFontSize: CGFloat = 13

        static func basmalahSize(for fontSize: CGFloat) -> CGFloat { min(26, fontSize + 4) }
        /// KFGQPC HAFS sets its line at 1.75 × the point size.
        static func basmalahHeight(for fontSize: CGFloat) -> CGFloat { ceil(basmalahSize(for: fontSize) * 1.75) }

        static func textWidth(for size: CGSize) -> CGFloat { size.width - 2 * (outerHorizontal + textHorizontal) }
        static func frameHeight(for size: CGSize) -> CGFloat { size.height - 2 * outerVertical }
    }

    /// The largest font size in `minimumFontSize...maxFontSize` at which the
    /// whole page fits inside `size`: header, banners, basmalah, every text
    /// block and the page badge. A binary search over six steps, measured
    /// with `MushafTextView.measureHeight`; the answer is on a half-point.
    /// Deterministic for (page, size, maxFontSize, script), so callers cache it.
    static func fittedFontSize(page: Int, size: CGSize, maxFontSize: CGFloat, script: QuranScript) -> CGFloat {
        let segments = segments(for: page)
        let width = Metrics.textWidth(for: size)
        let available = Metrics.frameHeight(for: size)
        let minimum = Metrics.minimumFontSize
        let maximum = max(minimum, maxFontSize)

        func height(at fontSize: CGFloat) -> CGFloat {
            var total = Metrics.headerTop + Metrics.headerHeight + Metrics.headerBottom
                + Metrics.badgeTop + Metrics.badgeHeight + Metrics.badgeBottom
            for segment in segments {
                if segment.opensSurah {
                    total += Metrics.openingTop + Metrics.bannerHeight
                    if segment.surah.bismillahPre {
                        total += Metrics.openingSpacing + Metrics.basmalahHeight(for: fontSize)
                    }
                }
                total += MushafTextView.measureHeight(
                    ayat: segment.ayat, width: width, fontSize: fontSize, script: script,
                    colorMarkers: false, lineSpacingFactor: Metrics.lineSpacingFactor
                )
            }
            return total
        }
        func fits(_ fontSize: CGFloat) -> Bool { height(at: fontSize) <= available }

        guard width > 0, available > 0, !segments.isEmpty else { return maximum }
        if fits(maximum) { return maximum }
        guard fits(minimum) else { return minimum }
        var low = minimum
        var high = maximum
        for _ in 0..<6 {
            let mid = ((low + high) / 2 * 2).rounded() / 2
            guard mid > low, mid < high else { break }
            if fits(mid) { low = mid } else { high = mid }
        }
        return low
    }

    // MARK: Body

    var body: some View {
        // Grouping the page's ayat walks the whole Qur'an once; do it once per body.
        let segments = Self.segments(for: page)
        Group {
            if let fit {
                fittedBody(segments, fit: fit)
            } else {
                flowingBody(segments)
            }
        }
        .background(PageFrame(fit: fit != nil))
        .padding(.horizontal, Metrics.outerHorizontal)
        .padding(.vertical, Metrics.outerVertical)
        .environment(\.layoutDirection, language.layoutDirection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language == .arabic ? "صفحة \(QuranAyah.arabicDigits(page))" : "Page \(page)")
    }

    /// The reading layout: the page takes the height its text needs and
    /// the enclosing scroll view does the rest.
    private func flowingBody(_ segments: [Segment]) -> some View {
        VStack(spacing: 0) {
            header(surahName: segments.first?.surah.name(language) ?? "")
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 6)

            ForEach(segments) { segment in
                if segment.opensSurah {
                    SurahOpening(surah: segment.surah, language: language)
                        .padding(.top, 10)
                        .padding(.bottom, 2)
                }
                textBlock(segment, fontSize: fontSize, showTranslation: showTranslation,
                          lineSpacingFactor: MushafTextView.defaultLineSpacingFactor)
            }

            Spacer(minLength: 12)

            PageNumberBadge(page: page, language: language, action: onPageTap)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
    }

    /// One screen, as a printed page: every height here is a `Metrics`
    /// value so the fitted font size measured in advance holds.
    private func fittedBody(_ segments: [Segment], fit: Fit) -> some View {
        VStack(spacing: 0) {
            fittedHeader(surahName: segments.first?.surah.name(language) ?? "")
                .frame(height: Metrics.headerHeight)
                .padding(.horizontal, 22)
                .padding(.top, Metrics.headerTop)
                .padding(.bottom, Metrics.headerBottom)

            ForEach(segments) { segment in
                if segment.opensSurah {
                    SurahOpening(surah: segment.surah, language: language,
                                 compact: true, basmalahSize: Metrics.basmalahSize(for: fit.fontSize))
                        .padding(.top, Metrics.openingTop)
                }
                textBlock(segment, fontSize: fit.fontSize, showTranslation: false,
                          lineSpacingFactor: Metrics.lineSpacingFactor)
            }

            Spacer(minLength: 0)

            PageNumberBadge(page: page, language: language, action: onPageTap)
                .frame(height: Metrics.badgeHeight)
                .padding(.top, Metrics.badgeTop)
                .padding(.bottom, Metrics.badgeBottom)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.frameHeight(for: fit.size))
        .clipped()
    }

    private func header(surahName: String) -> some View {
        HStack {
            Text(juzTitle)
            Spacer(minLength: 8)
            Text(surahName)
        }
        .font(.yqCaption)
        .foregroundStyle(Color.yqSecondary)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }

    /// As the Madani page prints it: the surah on the leading side, the
    /// juz on the trailing side. Fixed sizes, so the row's height is known.
    private func fittedHeader(surahName: String) -> some View {
        HStack(alignment: .center) {
            Text(surahName)
                .font(language == .arabic ? Font.custom(MushafTextView.fontName, fixedSize: 15) : .system(size: 12, weight: .semibold))
                .foregroundStyle(Color.yqInk)
            Spacer(minLength: 8)
            Text(juzTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.yqSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }

    private func textBlock(_ segment: Segment, fontSize: CGFloat, showTranslation: Bool,
                           lineSpacingFactor: CGFloat) -> some View {
        MushafTextView(
            ayat: segment.ayat,
            surahName: segment.surah.name(language),
            language: language,
            fontSize: fontSize,
            highlights: highlights(for: segment.ayat),
            colorMarkers: library.colorReferenceMarks,
            playingKey: player.playingKey,
            showTranslation: showTranslation,
            script: script,
            translationEdition: translationEdition,
            lineSpacingFactor: lineSpacingFactor,
            onTap: onTap
        )
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, Metrics.textHorizontal)
    }
}

// MARK: - Book chrome

/// A quiet printed border; its white image background becomes transparent
/// through a luminance mask, so the same engraving works on both paper tones.
struct PageFrame: View {
    var cornerRadius: CGFloat = 0
    var fit = false
    var body: some View {
        ZStack {
            MushafPaper.background
            MushafPaper.gold.mask {
                Image("MushafOrnament")
                    .resizable()
                    .colorInvert()
                    .luminanceToAlpha()
            }
        }
        .accessibilityHidden(true)
    }
}

/// The page number in a small open-book badge, as printed at the foot of a
/// mushaf page. Tapping it opens the page picker.
struct PageNumberBadge: View {
    let page: Int
    let language: AppLanguage
    var action: () -> Void = {}

    private var number: String {
        language == .arabic ? QuranAyah.arabicDigits(page) : String(page)
    }

    var body: some View {
        Button {
            Haptics.press()
            action()
        } label: {
            Text(QuranAyah.arabicDigits(page))
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(Color(uiColor: MushafPaper.ink))
                .frame(minWidth: 54, minHeight: 34)
                .background(MushafPaper.background)
                .contentShape(Rectangle())
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityLabel(language == .arabic ? "صفحة \(number)، الانتقال إلى صفحة" : "Page \(number), go to page")
    }
}

// MARK: - Surah banner

/// The Madani cartouche: a rounded band with a hairline, a second line
/// inside it and a small ornament overlapping each end, with the surah
/// name in the middle. It shares the printed reader's muted ink palette.
/// `compact` is the fitted page's shorter band with a fixed-size name.
struct SurahBanner: View {
    let surah: QuranSurah
    let language: AppLanguage
    var compact = false

    private var height: CGFloat { compact ? MushafPageView.Metrics.bannerHeight : 50 }

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(MushafPaper.background)
            Capsule(style: .continuous)
                .strokeBorder(MushafPaper.gold.opacity(0.35), lineWidth: 1)
            Capsule(style: .continuous)
                .strokeBorder(MushafPaper.gold.opacity(0.35), lineWidth: 1)
                .padding(4)
            Text(surah.nameArabic)
                .font(compact ? Font.custom(MushafTextView.fontName, fixedSize: 20) : .arabic(24))
                .foregroundStyle(Color.yqInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 40)
        }
        .frame(height: height)
        .overlay(alignment: .leading) { endCircle.offset(x: -13) }
        .overlay(alignment: .trailing) { endCircle.offset(x: 13) }
        .padding(.horizontal, 13)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language == .arabic ? "سورة \(surah.nameArabic)" : "Surah \(surah.nameSimple)")
        .accessibilityAddTraits(.isHeader)
    }

    private var endCircle: some View {
        ZStack {
            Circle().fill(MushafPaper.background)
            Circle().strokeBorder(MushafPaper.gold.opacity(0.35), lineWidth: 1)
            EightPointStar()
                .fill(MushafPaper.gold)
                .frame(width: 9, height: 9)
        }
        .frame(width: 26, height: 26)
    }
}

/// The basmalah as the mushaf prints it under a surah banner. With
/// `fixedSize` the line ignores Dynamic Type and takes a known height, so
/// a fitted page can account for it.
struct BasmalahLine: View {
    var fixedSize: CGFloat? = nil

    var body: some View {
        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
            .font(fixedSize.map { Font.custom(MushafTextView.fontName, fixedSize: $0) } ?? .arabic(26))
            .foregroundStyle(Color.yqInk)
            .lineLimit(fixedSize == nil ? nil : 1)
            .minimumScaleFactor(fixedSize == nil ? 1 : 0.6)
            .multilineTextAlignment(.center)
            .frame(height: fixedSize.map { ceil($0 * 1.75) })
            .accessibilityLabel("Bismillah ir-Rahman ir-Rahim")
    }
}

/// Banner plus basmalah: what the reader sees where a surah begins, in both
/// the page and the surah layouts.
struct SurahOpening: View {
    let surah: QuranSurah
    let language: AppLanguage
    var compact = false
    var basmalahSize: CGFloat = 26

    var body: some View {
        VStack(spacing: compact ? MushafPageView.Metrics.openingSpacing : 12) {
            SurahBanner(surah: surah, language: language, compact: compact)
            if surah.bismillahPre {
                BasmalahLine(fixedSize: compact ? basmalahSize : nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
