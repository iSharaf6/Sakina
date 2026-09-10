import Foundation
import SwiftUI

// MARK: - Palette
//
// White canvas, one saturated green, one cool-neutral grey family. Every other
// illustration uses the shared cream, charcoal, moss, and ochre palette.
// Semantic UI colors adapt to light and dark appearances.

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

extension Color {
    // Surfaces
    static let yqCanvas = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x0B0F0D))
    static let yqSurface = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x151A17))
    static let yqFill = Color(uiColor: .dynamic(light: 0xF3F5F4, dark: 0x1D2320))
    static let yqFillStrong = Color(uiColor: .dynamic(light: 0xE9EDEB, dark: 0x262D29))
    static let yqHairline = Color(uiColor: .dynamic(light: 0xE6EAE8, dark: 0x2B332E))

    // Text
    static let yqInk = Color(uiColor: .dynamic(light: 0x101714, dark: 0xF2F5F3))
    static let yqSecondary = Color(uiColor: .dynamic(light: 0x616B66, dark: 0xA2ACA6))
    static let yqTertiary = Color(uiColor: .dynamic(light: 0x98A19C, dark: 0x6F7A73))

    // The accent
    static let yqAccent = Color(uiColor: .dynamic(light: 0x16A34A, dark: 0x22C55E))
    static let yqAccentDeep = Color(uiColor: .dynamic(light: 0x15803D, dark: 0x4ADE80))
    static let yqAccentTint = Color(uiColor: .dynamic(light: 0xE6F6EC, dark: 0x12301D))
    static let yqAccentTintStrong = Color(uiColor: .dynamic(light: 0xCDEEDA, dark: 0x1B4A2B))
    static let yqOnAccent = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x052E16))

    // The one dark surface: the "tonight / next prayer" card.
    static let yqNight = Color(uiColor: .dynamic(light: 0x0F2A1B, dark: 0x1A2B21))
    static let yqOnNight = Color(uiColor: .dynamic(light: 0xF1F7F3, dark: 0xF1F7F3))
    static let yqNightMuted = Color(uiColor: .dynamic(light: 0x9FC3AD, dark: 0x9FC3AD))

    // Compatibility aliases. Screens that were not part of this pass keep
    // compiling and inherit the new palette automatically.
    static let yaqeenForest = yqAccentDeep
    static let yaqeenIvory = yqCanvas
    static let yaqeenSurface = yqSurface
    static let yaqeenInk = yqInk
    static let yaqeenMuted = yqSecondary
    static let yaqeenSage = yqAccentTint
    static let yaqeenSand = yqFill
    static let yaqeenOnAccent = yqOnAccent
    static let sakinaCanvas = yqCanvas
    static let sakinaElevated = yqSurface
    static let sakinaInk = yqInk
    static let sakinaMuted = yqSecondary
    static let sakinaGold = yqAccentDeep
    static let sakinaHairline = yqHairline

    static func chapterHue(_ id: ChapterID) -> Color { yqAccent }
}

/// Badge tints. iOS system colours adapt to dark mode and are exactly what
/// Settings, Luna and Amy use for their icon badges.
enum BadgeTint: String, CaseIterable, Hashable {
    case green, blue, indigo, purple, pink, orange, teal, cyan, brown, red, slate, night

    var color: Color {
        switch self {
        case .green: return .yqAccent
        case .blue: return Color(uiColor: .systemBlue)
        case .indigo: return Color(uiColor: .systemIndigo)
        case .purple: return Color(uiColor: .systemPurple)
        case .pink: return Color(uiColor: .systemPink)
        case .orange: return Color(uiColor: .systemOrange)
        case .teal: return Color(uiColor: .systemTeal)
        case .cyan: return Color(uiColor: .systemCyan)
        case .brown: return Color(uiColor: .systemBrown)
        case .red: return Color(uiColor: .systemRed)
        case .slate: return Color(uiColor: .dynamic(light: 0x5B6670, dark: 0x8B959E))
        case .night: return .yqNight
        }
    }
}

// MARK: - Typography
//
// SF Pro, tight leading, strong weight contrast. One display size per screen.

extension Font {
    static var yqLargeTitle: Font { .system(.largeTitle, weight: .bold) }
    static var yqTitle: Font { .system(.title, weight: .bold) }
    static var yqTitle2: Font { .system(.title2, weight: .bold) }
    static var yqSection: Font { .system(.title3, weight: .bold) }
    static var yqHeadline: Font { .system(.headline, weight: .semibold) }
    static var yqBody: Font { .system(.body) }
    static var yqBodyMedium: Font { .system(.body, weight: .medium) }
    static var yqSubhead: Font { .system(.subheadline) }
    static var yqSubheadMedium: Font { .system(.subheadline, weight: .medium) }
    static var yqSubheadBold: Font { .system(.subheadline, weight: .semibold) }
    static var yqCaption: Font { .system(.caption) }
    static var yqCaptionBold: Font { .system(.caption, weight: .semibold) }
    static var yqNumber: Font { .system(.title2, weight: .bold).monospacedDigit() }

    /// Legacy hierarchy helper kept for screens outside this pass.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        switch size {
        case 40...: return .system(.largeTitle, weight: weight)
        case 32...: return .system(.title, weight: weight)
        case 25...: return .system(.title2, weight: weight)
        case 20...: return .system(.title3, weight: weight)
        case 17...: return .system(.headline, weight: weight)
        default: return .system(.subheadline, weight: weight)
        }
    }

    /// Legacy reading face for translations, notes and reflections.
    static func reading(_ size: CGFloat) -> Font {
        switch size {
        case 20...: return .system(.title3)
        case 16...: return .system(.body)
        case 14...: return .system(.callout)
        case 12...: return .system(.subheadline)
        default: return .system(.footnote)
        }
    }

    /// KFGQPC HAFS Uthmanic Script, scaled with Dynamic Type. Reserved for
    /// Qur'anic Arabic; prophetic du'a uses the system Arabic face.
    static func arabic(_ size: CGFloat) -> Font {
        .custom(QuranTextRenderer.uthmaniFontName, size: size, relativeTo: arabicStyle(for: size))
    }

    /// System Arabic for hadith and du'a text.
    static func arabicProse(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    private static func arabicStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 30...: return .title
        case 24...: return .title2
        case 20...: return .title3
        case 16...: return .body
        case 13...: return .subheadline
        default: return .footnote
        }
    }
}

/// A compact structural label. Latin text uses quiet, tracked capitals; Arabic
/// keeps its original casing and natural spacing.
struct CapsLabel: View {
    let text: String
    var color: Color = .yqSecondary
    var size: CGFloat = 11

    @Environment(\.locale) private var locale

    private var containsArabic: Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF, 0xFB50...0xFDFF, 0xFE70...0xFEFF:
                return true
            default:
                return false
            }
        }
    }

    var body: some View {
        Text(containsArabic ? text : text.uppercased(with: locale))
            .font(.system(size >= 11 ? .caption : .caption2, weight: .bold))
            .tracking(containsArabic ? 0 : 0.9)
            .foregroundStyle(color)
            .accessibilityLabel(Text(text))
    }
}

// MARK: - Yaqeen symbol

/// The Yaqeen open-book and upward-path mark. A pure vector `Shape`, so it
/// remains crisp in navigation, widgets and the app icon at any size.
struct YaqeenMark: Shape {
    func path(in rect: CGRect) -> Path {
        let markAspect: CGFloat = 0.70
        let width = min(rect.width, rect.height * markAspect)
        let height = min(rect.height, rect.width / markAspect)
        let origin = CGPoint(x: rect.midX - width / 2, y: rect.midY - height / 2)

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * width, y: origin.y + y * height)
        }

        var path = Path()

        path.move(to: point(0.50, 0.00))
        path.addLine(to: point(0.63, 0.10))
        path.addLine(to: point(0.50, 0.20))
        path.addLine(to: point(0.37, 0.10))
        path.closeSubpath()

        path.move(to: point(0.05, 0.20))
        path.addCurve(to: point(0.50, 0.43), control1: point(0.21, 0.22), control2: point(0.39, 0.32))
        path.addCurve(to: point(0.95, 0.20), control1: point(0.61, 0.32), control2: point(0.79, 0.22))
        path.addLine(to: point(0.95, 0.37))
        path.addCurve(to: point(0.50, 0.58), control1: point(0.78, 0.42), control2: point(0.62, 0.50))
        path.addCurve(to: point(0.05, 0.37), control1: point(0.38, 0.50), control2: point(0.22, 0.42))
        path.closeSubpath()

        path.move(to: point(0.05, 0.46))
        path.addCurve(to: point(0.50, 0.68), control1: point(0.20, 0.52), control2: point(0.39, 0.60))
        path.addCurve(to: point(0.33, 0.95), control1: point(0.40, 0.77), control2: point(0.33, 0.88))
        path.addLine(to: point(0.33, 1.00))
        path.addLine(to: point(0.05, 1.00))
        path.closeSubpath()

        path.move(to: point(0.95, 0.46))
        path.addCurve(to: point(0.50, 0.68), control1: point(0.80, 0.52), control2: point(0.61, 0.60))
        path.addCurve(to: point(0.67, 0.95), control1: point(0.60, 0.77), control2: point(0.67, 0.88))
        path.addLine(to: point(0.67, 1.00))
        path.addLine(to: point(0.95, 1.00))
        path.closeSubpath()

        return path
    }
}

/// A restrained eight-point star, used as a small structural ornament.
struct EightPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.38
        var path = Path()
        for index in 0..<16 {
            let angle = -.pi / 2 + CGFloat(index) * .pi / 8
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct StarDivider: View {
    var color: Color = .yqAccent
    var body: some View {
        HStack(spacing: 12) {
            line(reversed: false)
            EightPointStar().fill(color).frame(width: 7, height: 7)
            line(reversed: true)
        }
        .accessibilityHidden(true)
    }
    private func line(reversed: Bool) -> some View {
        LinearGradient(
            colors: reversed ? [color.opacity(0.48), color.opacity(0)] : [color.opacity(0), color.opacity(0.48)],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 0.75)
        .frame(maxWidth: 68)
    }
}

// MARK: - Backgrounds

/// The app canvas: white with the Ottoman field behind everything.
struct AtmosphereBackground: View {
    var hue: Color? = nil
    var body: some View { ScreenBackground() }
}

struct ScreenBackground: View {
    var pattern: GeometricPattern = .starAndCross
    var body: some View {
        ZStack {
            Color.yqCanvas
            GeometricField(pattern: pattern)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Applies the app canvas and pattern behind a screen.
    func yqScreen(pattern: GeometricPattern = .starAndCross) -> some View {
        background(ScreenBackground(pattern: pattern))
    }
}

// MARK: - Card chrome

struct CardBackground: ViewModifier {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(Color.yqSurface, in: shape)
            .overlay(shape.strokeBorder(Color.yqHairline, lineWidth: 1))
    }
}

extension View {
    func sakinaCard(tint: Color = .clear, cornerRadius: CGFloat = 18) -> some View {
        modifier(CardBackground(tint: tint, cornerRadius: cornerRadius))
    }

    /// The standard card: white, 18pt continuous corners, 1pt hairline. No shadow.
    func yqCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Press feedback

/// Press-in is immediate; release is a short spring with a little life in it.
struct YaqeenPressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? scale : 1))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.06)
                    : configuration.isPressed
                        ? .easeOut(duration: 0.09)
                        : .spring(response: 0.32, dampingFraction: 0.72),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { scale < 0.99 ? Haptics.tap() : Haptics.press() }
            }
    }
}

extension ButtonStyle where Self == YaqeenPressableButtonStyle {
    static var yaqeenPressable: YaqeenPressableButtonStyle { YaqeenPressableButtonStyle() }
    static var yqPress: YaqeenPressableButtonStyle { YaqeenPressableButtonStyle() }
    static var yqPressSoft: YaqeenPressableButtonStyle { YaqeenPressableButtonStyle(scale: 0.985) }
}

/// Legacy name used across older screens.
typealias YaqeenPressStyle = YaqeenPressableButtonStyle

// MARK: - Toast

struct Toast: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.yqAccent)
            Text(message)
                .font(.yqSubheadBold)
                .foregroundStyle(Color.yqInk)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.yqSurface, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).strokeBorder(Color.yqHairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }
}
