import Foundation
import SwiftUI

// MARK: - Palette

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func dynamic(
        dark: UInt32,
        light: UInt32,
        highContrastDark: UInt32? = nil,
        highContrastLight: UInt32? = nil
    ) -> UIColor {
        UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHighContrast = traits.accessibilityContrast == .high

            switch (isDark, isHighContrast) {
            case (true, true):
                return UIColor(hex: highContrastDark ?? dark)
            case (false, true):
                return UIColor(hex: highContrastLight ?? light)
            case (true, false):
                return UIColor(hex: dark)
            case (false, false):
                return UIColor(hex: light)
            }
        }
    }
}

extension Color {
    // The supplied Yaqeen identity is deliberately narrow: forest, ivory,
    // eucalyptus and sand. These semantic names are the preferred API.
    static let yaqeenForest = Color(
        uiColor: .dynamic(
            dark: 0xA9C9BD,
            light: 0x2B5148,
            highContrastDark: 0xC5DED5,
            highContrastLight: 0x173F37
        )
    )
    static let yaqeenIvory = Color(
        uiColor: .dynamic(
            dark: 0x0B1714,
            light: 0xF8F5ED,
            highContrastDark: 0x06100D,
            highContrastLight: 0xFFFCF5
        )
    )
    static let yaqeenSurface = Color(
        uiColor: .dynamic(
            dark: 0x14251F,
            light: 0xFFFCF5,
            highContrastDark: 0x12211C,
            highContrastLight: 0xFFFFFF
        )
    )
    static let yaqeenInk = Color(
        uiColor: .dynamic(
            dark: 0xF7F3EA,
            light: 0x173F37,
            highContrastDark: 0xFFFFFF,
            highContrastLight: 0x0D2B24
        )
    )
    static let yaqeenMuted = Color(
        uiColor: .dynamic(
            dark: 0xA6B5AF,
            light: 0x65766F,
            highContrastDark: 0xC4CFCA,
            highContrastLight: 0x4D5C57
        )
    )
    static let yaqeenSage = Color(
        uiColor: .dynamic(dark: 0x73988D, light: 0xDCE7E1)
    )
    static let yaqeenSand = Color(
        uiColor: .dynamic(dark: 0x34453E, light: 0xE5DED1)
    )

    // Compatibility aliases. The public names remain intact so the existing
    // app can adopt the new brand without a wide, risky source migration.
    static let sakinaCanvas = yaqeenIvory
    static let sakinaElevated = yaqeenSurface
    static let sakinaInk = yaqeenInk
    static let sakinaMuted = yaqeenMuted
    static let sakinaGold = yaqeenForest
    static let sakinaHairline = Color(
        uiColor: .dynamic(
            dark: 0x2B433B,
            light: 0xDDD7CB,
            highContrastDark: 0x587269,
            highContrastLight: 0xC5BCAE
        )
    )

    /// Legacy chapter accents, harmonised into the Yaqeen botanical family.
    /// They distinguish content without reintroducing a rainbow palette.
    static func chapterHue(_ id: ChapterID) -> Color {
        switch id {
        case .search:
            return Color(uiColor: .dynamic(dark: 0x91BBAE, light: 0x35695E))
        case .bond:
            return Color(uiColor: .dynamic(dark: 0xA5C4B2, light: 0x45695A))
        case .storm:
            return Color(uiColor: .dynamic(dark: 0x83AAA3, light: 0x3D655D))
        case .family:
            return Color(uiColor: .dynamic(dark: 0xB2C09D, light: 0x586748))
        case .heart:
            return Color(uiColor: .dynamic(dark: 0xA3CBBE, light: 0x397466))
        case .trials:
            return Color(uiColor: .dynamic(dark: 0x91AFB1, light: 0x49686A))
        case .provision:
            return Color(uiColor: .dynamic(dark: 0xBCBD98, light: 0x626447))
        }
    }
}

// MARK: - Typography

extension Font {
    /// A semantic SF Pro display face. The legacy size remains a hierarchy hint,
    /// while Dynamic Type controls the rendered size.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(displayStyle(for: size), design: .default, weight: weight)
            .leading(.tight)
    }

    /// A semantic SF Pro reading face for translations, notes and reflections.
    static func reading(_ size: CGFloat) -> Font {
        .system(readingStyle(for: size), design: .default, weight: .regular)
    }

    /// KFGQPC HAFS Uthmanic Script, scaled with the user's Dynamic Type setting.
    /// This face is reserved for Qur'anic Arabic rather than general Arabic UI.
    static func arabic(_ size: CGFloat) -> Font {
        .custom(
            "KFGQPC HAFS Uthmanic Script",
            size: size,
            relativeTo: arabicStyle(for: size)
        )
    }

    fileprivate static func structuralLabel(_ size: CGFloat) -> Font {
        .system(structuralStyle(for: size), design: .default, weight: .semibold)
    }

    private static func displayStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 40...: return .largeTitle
        case 32...: return .title
        case 25...: return .title2
        case 20...: return .title3
        case 17...: return .headline
        default: return .subheadline
        }
    }

    private static func readingStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 20...: return .title3
        case 16...: return .body
        case 14...: return .callout
        case 12...: return .subheadline
        default: return .footnote
        }
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

    private static func structuralStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 13...: return .subheadline
        case 11...: return .caption
        default: return .caption2
        }
    }
}

/// A compact structural label. Latin text uses quiet, tracked capitals; Arabic
/// keeps its original casing and natural spacing.
struct CapsLabel: View {
    let text: String
    var color: Color = .sakinaMuted
    var size: CGFloat = 11

    @Environment(\.locale) private var locale

    private var containsArabic: Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0600...0x06FF,
                 0x0750...0x077F,
                 0x08A0...0x08FF,
                 0xFB50...0xFDFF,
                 0xFE70...0xFEFF:
                return true
            default:
                return false
            }
        }
    }

    private var presentedText: String {
        containsArabic ? text : text.uppercased(with: locale)
    }

    private var letterSpacing: CGFloat {
        guard !containsArabic else { return 0 }
        return size >= 11 ? 1.35 : 1.05
    }

    var body: some View {
        Text(presentedText)
            .font(.structuralLabel(size))
            .tracking(letterSpacing)
            .foregroundStyle(color)
            .accessibilityLabel(Text(text))
    }
}

// MARK: - Yaqeen symbol

/// The Yaqeen open-book and upward-path mark from the supplied identity.
/// It is a pure vector `Shape`, so it remains crisp in navigation, widgets and
/// the app icon at any size. The drawing preserves its intended 0.70:1 aspect.
struct YaqeenMark: Shape {
    func path(in rect: CGRect) -> Path {
        let markAspect: CGFloat = 0.70
        let width = min(rect.width, rect.height * markAspect)
        let height = min(rect.height, rect.width / markAspect)
        let origin = CGPoint(
            x: rect.midX - width / 2,
            y: rect.midY - height / 2
        )

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * width, y: origin.y + y * height)
        }

        var path = Path()

        // The certainty diamond.
        path.move(to: point(0.50, 0.00))
        path.addLine(to: point(0.63, 0.10))
        path.addLine(to: point(0.50, 0.20))
        path.addLine(to: point(0.37, 0.10))
        path.closeSubpath()

        // Open pages. The lower edge becomes the first step of the path.
        path.move(to: point(0.05, 0.20))
        path.addCurve(
            to: point(0.50, 0.43),
            control1: point(0.21, 0.22),
            control2: point(0.39, 0.32)
        )
        path.addCurve(
            to: point(0.95, 0.20),
            control1: point(0.61, 0.32),
            control2: point(0.79, 0.22)
        )
        path.addLine(to: point(0.95, 0.37))
        path.addCurve(
            to: point(0.50, 0.58),
            control1: point(0.78, 0.42),
            control2: point(0.62, 0.50)
        )
        path.addCurve(
            to: point(0.05, 0.37),
            control1: point(0.38, 0.50),
            control2: point(0.22, 0.42)
        )
        path.closeSubpath()

        // Mirrored lower ribbons form the crossing path and quiet arch.
        path.move(to: point(0.05, 0.46))
        path.addCurve(
            to: point(0.50, 0.68),
            control1: point(0.20, 0.52),
            control2: point(0.39, 0.60)
        )
        path.addCurve(
            to: point(0.33, 0.95),
            control1: point(0.40, 0.77),
            control2: point(0.33, 0.88)
        )
        path.addLine(to: point(0.33, 1.00))
        path.addLine(to: point(0.05, 1.00))
        path.closeSubpath()

        path.move(to: point(0.95, 0.46))
        path.addCurve(
            to: point(0.50, 0.68),
            control1: point(0.80, 0.52),
            control2: point(0.61, 0.60)
        )
        path.addCurve(
            to: point(0.67, 0.95),
            control1: point(0.60, 0.77),
            control2: point(0.67, 0.88)
        )
        path.addLine(to: point(0.67, 1.00))
        path.addLine(to: point(0.95, 1.00))
        path.closeSubpath()

        return path
    }
}

// MARK: - Legacy ornaments

/// A restrained geometric sparkle retained for compatibility with existing UI.
struct EightPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.38
        var path = Path()

        for index in 0..<16 {
            let angle = -.pi / 2 + CGFloat(index) * .pi / 8
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

struct StarDivider: View {
    var color: Color = .sakinaGold

    var body: some View {
        HStack(spacing: 12) {
            line(reversed: false)
            EightPointStar()
                .fill(color)
                .frame(width: 7, height: 7)
            line(reversed: true)
        }
        .accessibilityHidden(true)
    }

    private func line(reversed: Bool) -> some View {
        LinearGradient(
            colors: reversed
                ? [color.opacity(0.48), color.opacity(0)]
                : [color.opacity(0), color.opacity(0.48)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.75)
        .frame(maxWidth: 68)
    }
}

// MARK: - Atmosphere

/// A calm ivory/forest field. The glows are intentionally low contrast and are
/// removed when the user asks iOS to reduce transparency.
struct AtmosphereBackground: View {
    var hue: Color? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            Color.sakinaCanvas

            if !reduceTransparency {
                LinearGradient(
                    colors: [
                        Color.sakinaElevated.opacity(colorScheme == .dark ? 0.14 : 0.50),
                        Color.sakinaCanvas.opacity(0),
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.46)
                )

                RadialGradient(
                    colors: [
                        Color.yaqeenForest.opacity(colorScheme == .dark ? 0.075 : 0.045),
                        Color.yaqeenForest.opacity(0),
                    ],
                    center: UnitPoint(x: 0.94, y: 0.02),
                    startRadius: 8,
                    endRadius: 440
                )

                if let hue {
                    RadialGradient(
                        colors: [
                            hue.opacity(colorScheme == .dark ? 0.09 : 0.06),
                            hue.opacity(0),
                        ],
                        center: UnitPoint(x: 0.02, y: 0.92),
                        startRadius: 8,
                        endRadius: 500
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card chrome

struct CardBackground: ViewModifier {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 22

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    if reduceTransparency {
                        shape.fill(Color.sakinaElevated)
                    } else {
                        shape.fill(.thinMaterial)
                        shape.fill(
                            Color.sakinaElevated.opacity(colorScheme == .dark ? 0.82 : 0.88)
                        )
                    }

                    shape.fill(tint.opacity(colorScheme == .dark ? 0.065 : 0.045))
                }
                .overlay {
                    shape.strokeBorder(
                        Color.sakinaHairline.opacity(contrast == .increased ? 1 : 0.82),
                        lineWidth: contrast == .increased ? 1 : 0.75
                    )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.055),
                    radius: colorScheme == .dark ? 7 : 10,
                    y: colorScheme == .dark ? 3 : 4
                )
            }
    }
}

extension View {
    func sakinaCard(tint: Color = .clear, cornerRadius: CGFloat = 22) -> some View {
        modifier(CardBackground(tint: tint, cornerRadius: cornerRadius))
    }
}

// MARK: - Press feedback

/// Immediate touch-down feedback with a critically damped release. There is no
/// bounce because a tap carries no momentum.
struct YaqeenPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.985 : 1))
            .opacity(configuration.isPressed ? 0.88 : 1)
            .brightness(configuration.isPressed ? -0.015 : 0)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.06)
                    : configuration.isPressed
                        ? .easeOut(duration: 0.07)
                        : .spring(response: 0.22, dampingFraction: 1, blendDuration: 0.06),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == YaqeenPressableButtonStyle {
    static var yaqeenPressable: YaqeenPressableButtonStyle {
        YaqeenPressableButtonStyle()
    }
}

// MARK: - Toast

struct Toast: View {
    let message: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 10) {
            YaqeenMark()
                .fill(Color.sakinaGold)
                .frame(width: 10, height: 15)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(.callout, design: .default, weight: .semibold))
                .foregroundStyle(Color.sakinaInk)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 12)
        .background {
            let capsule = Capsule(style: .continuous)
            ZStack {
                if reduceTransparency {
                    capsule.fill(Color.sakinaElevated)
                } else {
                    capsule.fill(.regularMaterial)
                    capsule.fill(
                        Color.sakinaElevated.opacity(colorScheme == .dark ? 0.84 : 0.90)
                    )
                }
            }
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 0.75)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10),
            radius: 12,
            y: 6
        )
        .accessibilityElement(children: .combine)
    }
}
