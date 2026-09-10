import SwiftUI
import UIKit

// MARK: - Proxy

/// A small handle MushafView keeps so it can ask the UIKit text renderer
/// where an ayah is on the page (for scrolling and the focus pulse).
final class MushafTextProxy {
    var rectForKey: ((String) -> CGRect?)?
    var scrollToKey: ((String, Bool) -> Bool)?
    /// Called with the text view's top edge relative to the scroll view's
    /// visible area whenever the enclosing UIScrollView moves.
    var onScroll: ((CGFloat) -> Void)?

    func rect(for key: String) -> CGRect? { rectForKey?(key) }

    /// Scrolls the enclosing UIScrollView so the ayah sits near the top.
    /// Returns false when layout is not ready yet.
    @discardableResult
    func scroll(to key: String, animated: Bool) -> Bool { scrollToKey?(key, animated) ?? false }
}

// MARK: - Text view

/// One continuous Uthmani text block for a surah, rendered by a TextKit 1
/// `UITextView`. Ayah markers sit inline; highlights and the playing ayah
/// are paragraph background attributes. The view never scrolls itself: the
/// surrounding SwiftUI `ScrollView` does, so `sizeThatFits` reports the full
/// laid-out height for the proposed width.
struct MushafTextView: UIViewRepresentable {
    static let fontName = "KFGQPC HAFS Uthmanic Script"
    static let inset: CGFloat = 16

    var ayat: [QuranAyah]
    var surahName: String
    var language: AppLanguage
    var fontSize: CGFloat
    var highlights: [String: HighlightColor]
    var colorMarkers: Bool
    var playingKey: String?
    var showTranslation: Bool
    var proxy: MushafTextProxy? = nil
    var onTap: (QuranAyah) -> Void
    /// Called (asynchronously, after layout) with the bounding rect of every
    /// ayah in the text view's coordinate space, keyed by ayah key.
    var onLayout: ([String: CGRect]) -> Void = { _ in }

    /// Everything that changes the attributed string.
    fileprivate struct Inputs: Equatable {
        var keys: [String]
        var fontSize: CGFloat
        var highlights: [String: HighlightColor]
        var colorMarkers: Bool
        var playingKey: String?
        var showTranslation: Bool
    }

    private var inputs: Inputs {
        Inputs(keys: ayat.map(\.key), fontSize: fontSize, highlights: highlights,
               colorMarkers: colorMarkers, playingKey: playingKey, showTranslation: showTranslation)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MushafUITextView {
        // Build the TextKit 1 stack by hand so the layout manager is ours.
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        layoutManager.allowsNonContiguousLayout = false
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.heightTracksTextView = false
        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)

        let view = MushafUITextView(frame: .zero, textContainer: container)
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: Self.inset, left: Self.inset, bottom: Self.inset, right: Self.inset)
        view.adjustsFontForContentSizeCategory = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.isAccessibilityElement = true
        view.accessibilityTraits = .staticText

        let coordinator = context.coordinator
        coordinator.textView = view
        coordinator.storage = storage

        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        let press = UILongPressGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePress(_:)))
        press.minimumPressDuration = 0.4
        view.addGestureRecognizer(press)

        view.onLayout = { [weak coordinator] in coordinator?.publishRects() }
        view.onScroll = { [weak coordinator] top in coordinator?.proxy?.onScroll?(top) }
        return view
    }

    func updateUIView(_ uiView: MushafUITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onTap = onTap
        coordinator.onLayout = onLayout
        coordinator.language = language
        proxy?.rectForKey = { [weak coordinator] key in coordinator?.rect(for: key) }
        proxy?.scrollToKey = { [weak coordinator] key, animated in coordinator?.scroll(to: key, animated: animated) ?? false }
        coordinator.proxy = proxy
        uiView.accessibilityLabel = surahName

        let inputs = inputs
        guard coordinator.lastInputs != inputs else { return }
        coordinator.lastInputs = inputs
        coordinator.rebuild(ayat: ayat, inputs: inputs)
        uiView.contentGeneration += 1
        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsLayout()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MushafUITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    // MARK: Coordinator

    final class Coordinator: NSObject {
        struct Entry {
            let ayah: QuranAyah
            /// The Arabic text and its marker: highlighted and measured.
            let range: NSRange
            /// Arabic plus any translation paragraph: what a tap lands on.
            let hitRange: NSRange
            let markerRange: NSRange
        }

        weak var textView: MushafUITextView?
        var storage: NSTextStorage?
        var onTap: ((QuranAyah) -> Void)?
        var onLayout: (([String: CGRect]) -> Void)?
        weak var proxy: MushafTextProxy?
        var language: AppLanguage = .english
        fileprivate var lastInputs: Inputs?

        private(set) var entries: [Entry] = []
        private var entryByKey: [String: Int] = [:]
        private var lastRects: [String: CGRect] = [:]

        // MARK: Building the string

        fileprivate func rebuild(ayat: [QuranAyah], inputs: Inputs) {
            let font = UIFont(name: MushafTextView.fontName, size: inputs.fontSize)
                ?? UIFont.systemFont(ofSize: inputs.fontSize)
            let ink = UIColor(Color.yqInk)
            let accent = UIColor(Color.yqAccentDeep)
            let playingTint = UIColor(Color.yqAccentTint)

            let arabicStyle = NSMutableParagraphStyle()
            arabicStyle.baseWritingDirection = .rightToLeft
            arabicStyle.alignment = .justified
            arabicStyle.lineSpacing = (inputs.fontSize * 0.55).rounded()
            arabicStyle.lineHeightMultiple = 1.0
            arabicStyle.paragraphSpacing = inputs.showTranslation ? 4 : 0

            let translationStyle = NSMutableParagraphStyle()
            translationStyle.baseWritingDirection = .leftToRight
            translationStyle.alignment = .natural
            translationStyle.lineSpacing = 3
            translationStyle.paragraphSpacing = 18
            let translationFont = UIFont.preferredFont(forTextStyle: .subheadline)
                .withSize(15)
            let secondary = UIColor(Color.yqSecondary)
            let smallZeroFont = UIFont.systemFont(ofSize: inputs.fontSize)

            let result = NSMutableAttributedString()
            var entries: [Entry] = []
            entries.reserveCapacity(ayat.count)

            for ayah in ayat {
                let start = result.length
                let body = ayah.displayArabic + " " + ayah.marker
                let bodyString = NSAttributedString(string: body, attributes: [
                    .font: font,
                    .foregroundColor: ink,
                    .paragraphStyle: arabicStyle,
                ])
                result.append(bodyString)
                let range = NSRange(location: start, length: result.length - start)
                let markerLength = (ayah.marker as NSString).length
                let markerRange = NSRange(location: result.length - markerLength, length: markerLength)
                result.append(NSAttributedString(string: " ", attributes: [
                    .font: font,
                    .foregroundColor: ink,
                    .paragraphStyle: arabicStyle,
                ]))

                let highlight = inputs.highlights[ayah.key]
                if let highlight {
                    result.addAttribute(.backgroundColor, value: highlight.uiColor.withAlphaComponent(0.22), range: range)
                }
                if inputs.playingKey == ayah.key {
                    result.addAttribute(.backgroundColor, value: playingTint, range: range)
                }

                let markerColor: UIColor
                if inputs.colorMarkers, let highlight {
                    markerColor = highlight.uiColor
                } else if inputs.colorMarkers {
                    markerColor = accent
                } else {
                    markerColor = ink
                }
                result.addAttribute(.foregroundColor, value: markerColor, range: markerRange)

                // The bundled font's U+06DF (small high rounded zero) is an
                // oversized composite that draws as a black dot; the system
                // Arabic font draws the correct small mark above the letter.
                let bodyNS = body as NSString
                var search = NSRange(location: 0, length: bodyNS.length)
                while true {
                    let found = bodyNS.range(of: "\u{06DF}", options: [], range: search)
                    guard found.location != NSNotFound else { break }
                    result.addAttribute(.font, value: smallZeroFont, range: NSRange(location: start + found.location, length: found.length))
                    let next = found.location + found.length
                    search = NSRange(location: next, length: bodyNS.length - next)
                }

                if inputs.showTranslation {
                    result.append(NSAttributedString(string: "\n", attributes: [
                        .font: font,
                        .paragraphStyle: arabicStyle,
                    ]))
                    result.append(NSAttributedString(string: ayah.translation + "\n", attributes: [
                        .font: translationFont,
                        .foregroundColor: secondary,
                        .paragraphStyle: translationStyle,
                    ]))
                }

                let hitRange = NSRange(location: start, length: result.length - start)
                entries.append(Entry(ayah: ayah, range: range, hitRange: hitRange, markerRange: markerRange))
            }

            self.entries = entries
            entryByKey = Dictionary(uniqueKeysWithValues: entries.enumerated().map { ($1.ayah.key, $0) })
            lastRects = [:]

            if let storage {
                storage.setAttributedString(result)
            } else {
                textView?.attributedText = result
            }
        }

        // MARK: Hit testing

        private func characterIndex(at point: CGPoint) -> Int? {
            guard let textView, let storage, storage.length > 0 else { return nil }
            let inset = textView.textContainerInset
            let inner = CGPoint(x: point.x - inset.left, y: point.y - inset.top)
            let layoutManager = textView.layoutManager
            let container = textView.textContainer
            var fraction: CGFloat = 0
            let index = layoutManager.characterIndex(for: inner, in: container, fractionOfDistanceBetweenInsertionPoints: &fraction)
            guard index >= 0, index < storage.length else { return nil }
            // Ignore taps in the empty band below the text or well outside a line.
            let glyph = layoutManager.glyphIndexForCharacter(at: index)
            let line = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            guard line.insetBy(dx: -12, dy: -6).contains(inner) else { return nil }
            return index
        }

        func ayah(at point: CGPoint) -> QuranAyah? {
            guard let index = characterIndex(at: point) else { return nil }
            return entries.first { NSLocationInRange(index, $0.hitRange) }?.ayah
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let textView else { return }
            select(at: recognizer.location(in: textView))
        }

        @objc func handlePress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began, let textView else { return }
            select(at: recognizer.location(in: textView))
        }

        private func select(at point: CGPoint) {
            guard let ayah = ayah(at: point) else { return }
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: ayah.reference(language))
            }
            onTap?(ayah)
        }

        // MARK: Geometry

        /// Drives the enclosing UIScrollView directly; SwiftUI's scrollTo is
        /// unreliable for content tens of thousands of points tall.
        func scroll(to key: String, animated: Bool) -> Bool {
            guard let textView, textView.bounds.width > 0, let rect = rect(for: key) else { return false }
            var view: UIView? = textView.superview
            while let candidate = view, !(candidate is UIScrollView) { view = candidate.superview }
            guard let scrollView = view as? UIScrollView else { return false }
            let target = textView.convert(rect, to: scrollView)
            let visible = scrollView.bounds.height - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom
            let maxY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - visible - scrollView.adjustedContentInset.top)
            let y = min(maxY, max(-scrollView.adjustedContentInset.top, target.minY - scrollView.adjustedContentInset.top - visible * 0.12))
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: y), animated: animated)
            return true
        }

        func rect(for key: String) -> CGRect? {
            guard let textView, let index = entryByKey[key] else { return nil }
            let layoutManager = textView.layoutManager
            let container = textView.textContainer
            layoutManager.ensureLayout(for: container)
            return rect(for: entries[index].range, layoutManager: layoutManager, container: container, inset: textView.textContainerInset)
        }

        private func rect(for range: NSRange, layoutManager: NSLayoutManager, container: NSTextContainer, inset: UIEdgeInsets) -> CGRect {
            let glyphs = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: glyphs, in: container)
            rect.origin.x += inset.left
            rect.origin.y += inset.top
            return rect
        }

        /// Measures every ayah after a layout pass and hands the rects to
        /// SwiftUI on the next run loop turn, only when they changed.
        func publishRects() {
            guard let textView, !entries.isEmpty, textView.bounds.width > 0 else { return }
            let layoutManager = textView.layoutManager
            let container = textView.textContainer
            layoutManager.ensureLayout(for: container)
            let inset = textView.textContainerInset
            var rects: [String: CGRect] = [:]
            rects.reserveCapacity(entries.count)
            for entry in entries {
                rects[entry.ayah.key] = rect(for: entry.range, layoutManager: layoutManager, container: container, inset: inset)
            }
            guard rects != lastRects else { return }
            lastRects = rects
            let callback = onLayout
            DispatchQueue.main.async { callback?(rects) }
        }
    }
}

// MARK: - UIKit view

/// A `UITextView` that reports when its layout settles so the SwiftUI side
/// can place scroll anchors.
final class MushafUITextView: UITextView {
    var onLayout: (() -> Void)?
    var contentGeneration = 0

    private var lastLayoutSize: CGSize = .zero
    private var lastGeneration = -1
    var onScroll: ((CGFloat) -> Void)?
    private var offsetObservation: NSKeyValueObservation?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        offsetObservation = nil
        guard window != nil else { return }
        var view: UIView? = superview
        while let candidate = view, !(candidate is UIScrollView) { view = candidate.superview }
        guard let scrollView = view as? UIScrollView else { return }
        offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self, weak scrollView] _, _ in
            guard let self, let scrollView else { return }
            let top = self.convert(CGPoint.zero, to: scrollView).y - scrollView.contentOffset.y
            self.onScroll?(top)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastLayoutSize || contentGeneration != lastGeneration {
            lastLayoutSize = bounds.size
            lastGeneration = contentGeneration
            onLayout?()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}
