import SwiftUI

// MARK: - Icon badge
//
// Content and settings badges use the shared pencil illustration family.

struct IconBadge: View {
    enum Style { case solid, tinted, outline }

    let symbol: String
    var tint: Color = .yqAccent
    var size: CGFloat = 40
    var style: Style = .tinted

    private var radius: CGFloat { size * 0.27 }

    var body: some View {
        Group {
            if let artwork = CompanionArtwork.badge(for: symbol) {
                CompanionIllustration(artwork: artwork, size: size)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(fill)
                    if style == .outline {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Color.yqHairline, lineWidth: 1)
                    }
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.46, weight: .semibold))
                        .foregroundStyle(glyph)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var fill: Color {
        switch style {
        case .solid: return .yqFill
        case .tinted: return tint.opacity(0.08)
        case .outline: return .yqSurface
        }
    }

    private var glyph: Color {
        switch style {
        case .solid: return .yqInk
        case .tinted, .outline: return tint
        }
    }
}

// MARK: - Page and section headers

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.yqLargeTitle)
                .tracking(-0.4)
                .foregroundStyle(Color.yqInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Legacy name.
struct YaqeenPageTitle: View {
    let title: String
    var detail: String? = nil
    var body: some View { PageHeader(title: title, subtitle: detail) }
}

struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.yqSection)
                .foregroundStyle(Color.yqInk)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            trailing()
        }
    }
}

/// A quiet text action for section trailing slots.
struct TextAction: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.yqSubheadBold)
            .foregroundStyle(Color.yqAccentDeep)
            .frame(minHeight: 36)
    }
}

/// Legacy name kept for scholar screens.
struct SectionEyebrow: View {
    let title: String
    var detail: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.yqHeadline).foregroundStyle(Color.yqInk)
            Spacer()
            if let detail {
                Text(detail).font(.yqCaption).foregroundStyle(Color.yqSecondary).multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - Rows

/// A Settings-style row: badge, title, optional subtitle, trailing content.
struct BadgeRow<Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let symbol: String
    var tint: Color = .yqAccent
    let title: String
    var subtitle: String? = nil
    var artwork: CompanionArtwork? = nil
    var badgeStyle: IconBadge.Style = .solid
    var subtitleLines: Int? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(symbol: String, tint: Color = .yqAccent, title: String, subtitle: String? = nil,
         artwork: CompanionArtwork? = nil, badgeStyle: IconBadge.Style = .solid, subtitleLines: Int? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing = { Chevron() }) {
        self.symbol = symbol
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork
        self.badgeStyle = badgeStyle
        self.subtitleLines = subtitleLines
        self.trailing = trailing
    }

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 14))
        layout {
            if let artwork = artwork ?? CompanionArtwork.badge(for: symbol) {
                CompanionIllustration(artwork: artwork, size: 44)
            } else {
                IconBadge(symbol: symbol, tint: tint, size: 36, style: badgeStyle)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.yqBodyMedium)
                    .foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.yqSubhead)
                        .foregroundStyle(Color.yqSecondary)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : subtitleLines)
                        .fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize || subtitleLines == nil)
                }
            }
            if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
            trailing()
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 14)
        .padding(.vertical, typeSize.isAccessibilitySize ? 12 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }
}

struct Chevron: View {
    @Environment(\.layoutDirection) private var direction
    var body: some View {
        Image(systemName: direction == .rightToLeft ? "chevron.left" : "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.yqTertiary)
    }
}

/// Groups rows into one card with inset hairlines between them.
struct RowGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .yqCard()
    }
}

struct RowDivider: View {
    var inset: CGFloat = 64
    var body: some View {
        Color.yqHairline.frame(height: 1).padding(.leading, inset)
    }
}

// MARK: - Tiles and chips

/// A compact grid tile: badge on the left, title and detail on the right.
struct BadgeTile: View {
    let symbol: String
    var tint: Color = .yqAccent
    let title: String
    var detail: String? = nil
    var progress: Double? = nil
    var artwork: CompanionArtwork? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let artwork {
                    CompanionIllustration(artwork: artwork, size: 50)
                } else {
                    IconBadge(symbol: symbol, tint: tint, size: 40)
                }
                if let progress, progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 50)
                }
            }
            .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let detail {
                    Text(detail)
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .yqCard(cornerRadius: 18)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// A quiet paper pill with an expressive companion and a readable label.
struct FeelingChip: View {
    let symbol: String
    let title: String
    var tint: Color = .yqAccent
    var selected = false
    var artwork: CompanionArtwork? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let artwork {
                CompanionIllustration(artwork: artwork, size: 34)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title)
                .font(.yqSubheadMedium)
                .lineLimit(1)
        }
        .foregroundStyle(selected ? Color.white : Color.yqInk)
        .padding(.leading, artwork == nil ? 13 : 5)
        .padding(.trailing, 13)
        .frame(minHeight: 44)
        .background(selected ? Color.yqAccentDeep : Color.yqSurface, in: Capsule(style: .continuous))
        .overlay(Capsule().strokeBorder(Color.yqHairline, lineWidth: 0.75))
        .contentShape(Capsule())
    }
}

/// A small status tag: "3×", "Sahih", "Excerpt".
struct Tag: View {
    let text: String
    var tint: Color = .yqAccentDeep
    var filled = false

    var body: some View {
        Text(text)
            .font(.yqCaptionBold)
            .foregroundStyle(filled ? Color.white : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(filled ? tint : tint.opacity(0.13), in: Capsule(style: .continuous))
            .lineLimit(1)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = .yqAccent
    var foreground: Color = .yqOnAccent

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.yqHeadline)
            if let symbol {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold))
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SecondaryButton: View {
    let title: String
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.yqHeadline)
            if let symbol {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold))
            }
        }
        .foregroundStyle(Color.yqInk)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Round icon-only button used in toolbars and headers.
struct CircleButton: View {
    let symbol: String
    var size: CGFloat = 40
    var filled = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(filled ? Color.yqOnAccent : Color.yqInk)
            .frame(width: size, height: size)
            .background(filled ? Color.yqAccent : Color.yqFill, in: Circle())
            .contentShape(Circle())
    }
}

/// Legacy full-width action used by older screens.
struct YaqeenAction: View {
    let title: String
    var isPrimary = true
    @Environment(\.layoutDirection) private var direction
    var body: some View {
        if isPrimary {
            PrimaryButton(title: title, symbol: direction == .rightToLeft ? "arrow.left" : "arrow.right")
        } else {
            SecondaryButton(title: title, symbol: direction == .rightToLeft ? "arrow.left" : "arrow.right")
        }
    }
}

// MARK: - Search field

struct SearchField: View {
    let prompt: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding? = nil
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.yqTertiary)
            Group {
                if let focus {
                    TextField(prompt, text: $text).focused(focus)
                } else {
                    TextField(prompt, text: $text)
                }
            }
            .font(.yqBody)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .onSubmit(onSubmit)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.yqTertiary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 46)
        .background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Empty state

struct EmptyGuidanceState: View {
    let title: String
    let detail: String
    let symbol: String
    var artwork: CompanionArtwork? = nil

    var body: some View {
        VStack(spacing: 12) {
            if let artwork {
                CompanionIllustration(artwork: artwork, size: 112)
            } else {
                IconBadge(symbol: symbol, tint: .yqAccent, size: 48, style: .tinted)
            }
            Text(title).font(.yqHeadline).foregroundStyle(Color.yqInk)
            Text(detail)
                .font(.yqSubhead)
                .foregroundStyle(Color.yqSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
    }
}

// MARK: - Motion helpers

/// Staggered reveal for lists of cards on first appearance.
struct Revealed: ViewModifier {
    let order: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 10)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.15)
                    : .spring(response: 0.42, dampingFraction: 0.86).delay(Double(order) * 0.045),
                value: appeared
            )
    }
}

extension View {
    func revealed(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        modifier(Revealed(order: order, appeared: appeared, reduceMotion: reduceMotion))
    }
}

/// The forest photo used by the breathing pause.
struct SanctuaryForest: View {
    var body: some View {
        GeometryReader { proxy in
            Image("SanctuaryForest")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Flow layout

/// Wraps chips onto as many lines as needed. Used for the feelings cloud.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
