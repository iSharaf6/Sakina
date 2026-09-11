import SwiftUI
import CoreText

/// Display-only QPC text and its published line placement. Canonical ayat remain
/// the source for sharing, search, translation, audio and accessibility.
final class MushafLineStore {
    static let shared = MushafLineStore()
    struct Word: Decodable {
        let k: String
        let p: Int
        let l: Int
        let t: String
        let e: Bool
    }
    private struct File: Decodable { let pages: [[Word]] }
    let pages: [[Word]]
    private var firstPages: [String: Int] = [:]
    private var texts: [String: String] = [:]
    private init() {
        if let url = Bundle.main.url(forResource: "mushaf-lines", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data), file.pages.count == 604 {
            pages = file.pages
        } else { pages = [] }
        var parts: [String: [String]] = [:]
        for (index, words) in pages.enumerated() {
            for word in words {
                if firstPages[word.k] == nil { firstPages[word.k] = index + 1 }
                if !word.e { parts[word.k, default: []].append(word.t) }
            }
        }
        texts = parts.mapValues { $0.joined(separator: " ") }
    }
    func page(for key: String) -> Int? { firstPages[key] }
    func text(for key: String) -> String? { texts[key] }
    func words(on page: Int) -> [Word] { pages.indices.contains(page - 1) ? pages[page - 1] : [] }
}

/// A separate paper palette keeps the reader calm without changing the app.
enum MushafPaper {
    static let background = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.105, green: 0.115, blue: 0.105, alpha: 1)
        : UIColor(red: 0.993, green: 0.979, blue: 0.950, alpha: 1) })
    static let ink = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1)
        : UIColor(red: 0.12, green: 0.115, blue: 0.10, alpha: 1) }
    static let gold = Color(uiColor: ornament)
    static let ornament = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.72, green: 0.62, blue: 0.45, alpha: 1)
        : UIColor(red: 0.61, green: 0.48, blue: 0.32, alpha: 1) }
}

struct PrintedMushafPage: View {
    let page: Int
    let language: AppLanguage
    let onTap: (QuranAyah) -> Void
    let onPageTap: () -> Void
    var onSurahTap: () -> Void = {}
    var onJuzTap: () -> Void = {}
    var selectedKey: String? = nil
    @ObservedObject private var library = AyahLibrary.shared
    @ObservedObject private var player = MushafPlayer.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                cartouche("الجزء \(QuranAyah.arabicDigits(firstAyah?.juz ?? 1))", isJuz: true)
                cartouche("سورة \(QuranStore.shared.surah(firstAyah?.surah ?? 1)?.nameArabic ?? "")")
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 28)
            .frame(height: 34)
            .padding(.top, 5)

            PrintedMushafText(page: page, highlights: highlights, playingKey: player.playingKey,
                             colorMarkers: library.colorReferenceMarks, dark: colorScheme == .dark, selectedKey: selectedKey, onTap: onTap)
                .padding(.horizontal, 31)
                .padding(.vertical, 5)

            PageNumberBadge(page: page, language: language, action: onPageTap)
                .frame(height: 34)
                .padding(.bottom, 3)
        }
        .background(PageFrame(fit: true))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }

    private var firstAyah: QuranAyah? {
        MushafLineStore.shared.words(on: page).first.flatMap { QuranStore.shared.ayah($0.k) }
    }
    private var highlights: [String: HighlightColor] {
        var result: [String: HighlightColor] = [:]
        for key in Set(MushafLineStore.shared.words(on: page).map(\.k)) {
            if let highlight = library.highlight(key) { result[key] = highlight }
        }
        return result
    }

    private func cartouche(_ title: String, isJuz: Bool = false) -> some View {
        Button(action: isJuz ? onJuzTap : onSurahTap) {
        HStack(spacing: 5) {
            Text(title)
            Image(systemName: "chevron.down").font(.system(size: 8, weight: .semibold)).foregroundStyle(MushafPaper.gold)
        }
            .font(isJuz ? .system(size: 13, design: .serif) : .custom(QuranTextRenderer.uthmaniFontName, fixedSize: 15))
            .foregroundStyle(Color(uiColor: MushafPaper.ink))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 1)
            .background(MushafPaper.background)
            .overlay(Capsule().stroke(MushafPaper.gold.opacity(0.65), lineWidth: 0.65))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.pick(isJuz ? "Choose juz" : "Choose surah", isJuz ? "اختر الجزء" : "اختر السورة"))
        .accessibilityValue(title)
    }
}

private struct PrintedMushafText: UIViewRepresentable {
    let page: Int
    let highlights: [String: HighlightColor]
    let playingKey: String?
    let colorMarkers: Bool
    let dark: Bool
    let selectedKey: String?
    let onTap: (QuranAyah) -> Void

    func makeUIView(context: Context) -> PrintedMushafCanvas { PrintedMushafCanvas() }
    func updateUIView(_ view: PrintedMushafCanvas, context: Context) {
        view.onTap = onTap
        view.configure(page: page, highlights: highlights, playingKey: playingKey,
                       colorMarkers: colorMarkers, dark: dark, selectedKey: selectedKey)
    }
}

/// Each word is shaped as a complete cluster in the matching QPC font. The
/// published rows are justified by adjusting spaces only: letters and marks
/// are never stretched, split into different fonts, clipped or rewritten.
final class PrintedMushafCanvas: UIView {
    struct PositionedWord {
        let word: MushafLineStore.Word
        let line: CTLine
        let origin: CGPoint // baseline in UIKit's top-down coordinates
        let rect: CGRect
    }
    private(set) var positioned: [PositionedWord] = []
    private(set) var renderedFontSize: CGFloat = 0
    private var page = 0
    private var words: [MushafLineStore.Word] = []
    private var highlights: [String: HighlightColor] = [:]
    private var playingKey: String?
    private var colorMarkers = true
    private var dark = false
    private var selectedKey: String?
    private var previousSize = CGSize.zero
    private var headers: [(surah: QuranSurah, row: Int)] = []
    private var rowHeight: CGFloat = 0
    private var rowOffset: CGFloat = 0
    var onTap: ((QuranAyah) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressed(_:)))
        addGestureRecognizer(press)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(page: Int, highlights: [String: HighlightColor], playingKey: String?, colorMarkers: Bool, dark: Bool, selectedKey: String? = nil) {
        guard self.page != page || self.highlights != highlights || self.playingKey != playingKey
                || self.colorMarkers != colorMarkers || self.dark != dark || self.selectedKey != selectedKey else { return }
        self.page = page
        self.words = MushafLineStore.shared.words(on: page)
        self.highlights = highlights
        self.playingKey = playingKey
        self.colorMarkers = colorMarkers
        self.dark = dark
        self.selectedKey = selectedKey
        previousSize = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != previousSize, bounds.width > 0, bounds.height > 0 else { return }
        previousSize = bounds.size
        typeset()
        setNeedsDisplay()
    }

    private func textLine(_ word: MushafLineStore.Word, size: CGFloat) -> CTLine {
        let ink = (word.e && colorMarkers ? MushafPaper.ornament : MushafPaper.ink).resolvedColor(with: traitCollection)
        let paragraph = NSMutableParagraphStyle()
        paragraph.baseWritingDirection = .rightToLeft
        return CTLineCreateWithAttributedString(NSAttributedString(string: word.t, attributes: [
            .font: QuranTextRenderer.uthmaniFont(size: size), .foregroundColor: ink,
            .paragraphStyle: paragraph
        ]))
    }

    private func typeset() {
        positioned = []
        headers = []
        guard !words.isEmpty else { return }
        let grouped = Dictionary(grouping: words, by: \.l)
        let rowCount = page <= 2 ? 8 : 15
        // The two opening pages form a centred frontispiece, as in print.
        let availableHeight = page <= 2 ? min(bounds.height * 0.82, bounds.width * 1.5) : bounds.height
        rowHeight = availableHeight / CGFloat(rowCount)
        rowOffset = (bounds.height - availableHeight) / 2
        let referenceSize: CGFloat = 24
        var fittingScale: CGFloat = 2
        var tallestInk: CGFloat = 0
        for row in grouped.values {
            var width: CGFloat = 0
            var top: CGFloat = 0
            var bottom: CGFloat = 0
            for word in row {
                let line = textLine(word, size: referenceSize)
                let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
                width += max(CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)), ink.maxX) - min(0, ink.minX)
                top = max(top, ink.maxY)
                bottom = min(bottom, ink.minY)
            }
            tallestInk = max(tallestInk, top - bottom)
            width += CGFloat(max(0, row.count - 1)) * (page <= 2 ? referenceSize * 0.19 : 3)
            fittingScale = min(fittingScale, bounds.width / max(1, width))
        }
        fittingScale = min(fittingScale, rowHeight * 0.9 / max(1, tallestInk))
        renderedFontSize = referenceSize * fittingScale
        for rowNumber in grouped.keys.sorted() {
            guard let row = grouped[rowNumber] else { continue }
            let lines = row.map { textLine($0, size: renderedFontSize) }
            let widths = lines.map { line -> CGFloat in
                let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
                return max(CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)), ink.maxX) - min(0, ink.minX)
            }
            let total = widths.reduce(0, +)
            // Short closing lines keep natural spacing instead of stretching a few words across the page.
            let isCentred = page <= 2 || row.count <= 2 || total < bounds.width * 0.65
            let spacing = isCentred ? renderedFontSize * 0.19 : max(0, (bounds.width - total) / CGFloat(max(1, row.count - 1)))
            let lineWidth = total + spacing * CGFloat(max(0, row.count - 1))
            var right = isCentred ? (bounds.width + lineWidth) / 2 : bounds.width
            // A common baseline aligns all words, including small ayah markers.
            let inkRects = lines.map { CTLineGetBoundsWithOptions($0, .useGlyphPathBounds) }
            let ascent = inkRects.map(\.maxY).max() ?? 0
            let descent = -(inkRects.map(\.minY).min() ?? 0)
            let baseline = rowOffset + CGFloat(rowNumber - 1) * rowHeight + (rowHeight + ascent - descent) / 2
            for index in row.indices {
                right -= widths[index]
                let rect = CGRect(x: right, y: baseline - ascent, width: widths[index], height: ascent + descent)
                positioned.append(PositionedWord(word: row[index], line: lines[index], origin: CGPoint(x: right - min(0, inkRects[index].minX), y: baseline), rect: rect))
                right -= spacing
            }
        }
        for word in words where word.p == 1 {
            guard let ayah = QuranStore.shared.ayah(word.k), ayah.ayah == 1,
                  let surah = QuranStore.shared.surah(ayah.surah) else { continue }
            let headerRow = word.l - (surah.bismillahPre ? 2 : 1)
            if headerRow >= 1 { headers.append((surah, headerRow)) }
        }
        rebuildAccessibility()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        for item in positioned {
            let tint: UIColor?
            if selectedKey == item.word.k { tint = UIColor.systemGreen.withAlphaComponent(dark ? 0.32 : 0.20) }
            else if playingKey == item.word.k { tint = UIColor.systemGreen.withAlphaComponent(dark ? 0.24 : 0.12) }
            else { tint = highlights[item.word.k]?.uiColor.withAlphaComponent(0.2) }
            if let tint {
                tint.setFill()
                UIBezierPath(roundedRect: item.rect.insetBy(dx: -1, dy: -3), cornerRadius: 3).fill()
            }
        }
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        for item in positioned {
            context.textPosition = CGPoint(x: item.origin.x, y: bounds.height - item.origin.y)
            CTLineDraw(item.line, context)
        }
        context.restoreGState()
        for header in headers {
            let y = rowOffset + CGFloat(header.row - 1) * rowHeight
            let box = CGRect(x: 6, y: y + 3, width: bounds.width - 12, height: rowHeight - 6)
            MushafPaper.ornament.resolvedColor(with: traitCollection).withAlphaComponent(0.65).setStroke()
            let frame = UIBezierPath(roundedRect: box, cornerRadius: box.height / 2)
            frame.lineWidth = 0.65
            frame.stroke()
            let inner = UIBezierPath(roundedRect: box.insetBy(dx: 3, dy: 3), cornerRadius: max(0, box.height / 2 - 3))
            inner.lineWidth = 0.4
            inner.stroke()
            drawCentred("سُورَةُ \(header.surah.nameArabic)", in: box, size: min(24, rowHeight * 0.58), context: context)
            if header.surah.bismillahPre {
                drawCentred("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", in: box.offsetBy(dx: 0, dy: rowHeight),
                            size: min(renderedFontSize, rowHeight * 0.6), context: context)
            }
        }
    }

    private func drawCentred(_ text: String, in box: CGRect, size: CGFloat, context: CGContext) {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
            .font: QuranTextRenderer.uthmaniFont(size: size),
            .foregroundColor: MushafPaper.ink.resolvedColor(with: traitCollection)
        ]))
        let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: box.midX - ink.midX, y: box.midY + ink.midY)
        context.scaleBy(x: 1, y: -1)
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }

    func ayah(at point: CGPoint) -> QuranAyah? {
        positioned.first { $0.rect.insetBy(dx: -3, dy: -5).contains(point) }
            .flatMap { QuranStore.shared.ayah($0.word.k) }
    }
    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        if let ayah = ayah(at: recognizer.location(in: self)) { onTap?(ayah) }
    }
    @objc private func pressed(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began, let ayah = ayah(at: recognizer.location(in: self)) { onTap?(ayah) }
    }
    private func rebuildAccessibility() {
        var order: [String] = []
        var rects: [String: CGRect] = [:]
        for item in positioned {
            if rects[item.word.k] == nil { order.append(item.word.k) }
            rects[item.word.k] = rects[item.word.k]?.union(item.rect) ?? item.rect
        }
        accessibilityElements = order.compactMap { key -> UIAccessibilityElement? in
            guard let ayah = QuranStore.shared.ayah(key), let rect = rects[key] else { return nil }
            let element = VerseAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = ayah.displayArabic
            element.accessibilityLanguage = "ar"
            element.accessibilityValue = ayah.arabicNumber
            element.accessibilityTraits = [.button]
            element.accessibilityFrameInContainerSpace = rect
            element.activate = { [weak self] in self?.onTap?(ayah) }
            return element
        }
    }
}

final class VerseAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool { activate?(); return true }
}
