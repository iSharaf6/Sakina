import SwiftUI

// MARK: - Page
//
// One Madani mushaf page: exactly the ayat the printed page holds, inside a
// quiet book frame. A surah that begins on the page gets the cartouche
// banner and, where the mushaf prints it, the basmalah. The text itself is
// still `MushafTextView`, one per surah segment, so a page that ends one
// surah and opens the next shows the banner between two text blocks.

struct MushafPageView: View {
    let page: Int
    let language: AppLanguage
    let fontSize: CGFloat
    let script: QuranScript
    let translationEdition: Int
    let showTranslation: Bool
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

    private var segments: [Segment] {
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

    var body: some View {
        // Grouping the page's ayat walks the whole Qur'an once; do it once per body.
        let segments = self.segments
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
                textBlock(segment)
            }

            Spacer(minLength: 12)

            PageNumberBadge(page: page, language: language, action: onPageTap)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .background(PageFrame())
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .environment(\.layoutDirection, language.layoutDirection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language == .arabic ? "صفحة \(QuranAyah.arabicDigits(page))" : "Page \(page)")
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

    private func textBlock(_ segment: Segment) -> some View {
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
            onTap: onTap
        )
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 6)
    }
}

// MARK: - Book chrome

/// The page border: a hairline rounded rectangle, a second inset line, and
/// a small star at each corner. White paper over the patterned canvas.
struct PageFrame: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        let outer = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let inner = RoundedRectangle(cornerRadius: cornerRadius - 5, style: .continuous)
        ZStack {
            outer.fill(Color.yqSurface)
            outer.strokeBorder(Color.yqHairline, lineWidth: 1)
            inner.strokeBorder(Color.yqHairline, lineWidth: 1)
                .padding(5)
        }
        .overlay(alignment: .topLeading) { cornerStar }
        .overlay(alignment: .topTrailing) { cornerStar }
        .overlay(alignment: .bottomLeading) { cornerStar }
        .overlay(alignment: .bottomTrailing) { cornerStar }
        .accessibilityHidden(true)
    }

    private var cornerStar: some View {
        EightPointStar()
            .fill(Color.yqAccent)
            .frame(width: 9, height: 9)
            .padding(7)
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
            HStack(spacing: 5) {
                Image(systemName: "book.closed")
                    .font(.system(size: 11, weight: .semibold))
                Text(number)
                    .font(.yqCaptionBold)
                    .monospacedDigit()
            }
            .foregroundStyle(Color.yqInk)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Color.yqSurface, in: Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.yqHairline, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityLabel(language == .arabic ? "صفحة \(number)، الانتقال إلى صفحة" : "Page \(number), go to page")
    }
}

// MARK: - Surah banner

/// The Madani cartouche: a rounded band with a hairline, a second line
/// inside it, and a small circle overlapping each end, with the surah name
/// in the middle. Green is the only colour; there is no gold and no shadow.
struct SurahBanner: View {
    let surah: QuranSurah
    let language: AppLanguage

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.yqSurface)
            Capsule(style: .continuous)
                .strokeBorder(Color.yqHairline, lineWidth: 1)
            Capsule(style: .continuous)
                .strokeBorder(Color.yqHairline, lineWidth: 1)
                .padding(4)
            Text(surah.nameArabic)
                .font(.arabic(24))
                .foregroundStyle(Color.yqInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 40)
        }
        .frame(height: 50)
        .overlay(alignment: .leading) { endCircle.offset(x: -13) }
        .overlay(alignment: .trailing) { endCircle.offset(x: 13) }
        .padding(.horizontal, 13)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language == .arabic ? "سورة \(surah.nameArabic)" : "Surah \(surah.nameSimple)")
        .accessibilityAddTraits(.isHeader)
    }

    private var endCircle: some View {
        ZStack {
            Circle().fill(Color.yqSurface)
            Circle().strokeBorder(Color.yqHairline, lineWidth: 1)
            EightPointStar()
                .fill(Color.yqAccent)
                .frame(width: 9, height: 9)
        }
        .frame(width: 26, height: 26)
    }
}

/// The basmalah as the mushaf prints it under a surah banner.
struct BasmalahLine: View {
    var body: some View {
        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
            .font(.arabic(26))
            .foregroundStyle(Color.yqInk)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Bismillah ir-Rahman ir-Rahim")
    }
}

/// Banner plus basmalah: what the reader sees where a surah begins, in both
/// the page and the surah layouts.
struct SurahOpening: View {
    let surah: QuranSurah
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            SurahBanner(surah: surah, language: language)
            if surah.bismillahPre {
                BasmalahLine()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
