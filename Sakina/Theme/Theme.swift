import SwiftUI

// MARK: - Palette
// Refined editorial: deep ink night / warm cream paper, antique gold accent,
// four muted jewel hues — one per chapter.

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func dynamic(dark: UInt32, light: UInt32) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    static let sakinaCanvas   = Color(uiColor: .dynamic(dark: 0x0C111C, light: 0xF7F2E8))
    static let sakinaElevated = Color(uiColor: .dynamic(dark: 0x141B2B, light: 0xFDFAF2))
    static let sakinaInk      = Color(uiColor: .dynamic(dark: 0xF2EBDD, light: 0x1C2333))
    static let sakinaMuted    = Color(uiColor: .dynamic(dark: 0x8A93A6, light: 0x6E7686))
    static let sakinaGold     = Color(uiColor: .dynamic(dark: 0xD9B36C, light: 0xA0762B))
    static let sakinaHairline = Color(uiColor: .dynamic(dark: 0x28324A, light: 0xE2D9C6))

    static func chapterHue(_ id: ChapterID) -> Color {
        switch id {
        case .search: return Color(uiColor: .dynamic(dark: 0x8FBBA0, light: 0x3F7257))
        case .bond:   return Color(uiColor: .dynamic(dark: 0xD49A94, light: 0x9C4F47))
        case .storm:  return Color(uiColor: .dynamic(dark: 0x8CA2CC, light: 0x44598A))
        case .family: return Color(uiColor: .dynamic(dark: 0xD9A05B, light: 0x9C6B22))
        case .heart: return Color(uiColor: .dynamic(dark: 0xA795D1, light: 0x5F4A8F))
        case .trials: return Color(uiColor: .dynamic(dark: 0x8FB8C6, light: 0x40707F))
        case .provision: return Color(uiColor: .dynamic(dark: 0xC2B368, light: 0x7A6A25))
        }
    }
}

// MARK: - Typography

extension Font {
    /// New York serif for display headings — the editorial voice of the app.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// New York serif for reading (translations, notes, reflections).
    static func reading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// KFGQPC HAFS Uthmanic Script, the King Fahd Complex mushaf typeface,
    /// bundled in both targets. Falls back to the system font if unavailable.
    static func arabic(_ size: CGFloat) -> Font {
        .custom("KFGQPC HAFS Uthmanic Script", size: size)
    }
}

/// Small tracked-out uppercase label — the app's structural voice.
struct CapsLabel: View {
    let text: String
    var color: Color = .sakinaMuted
    var size: CGFloat = 11

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .semibold))
            .tracking(2.4)
            .foregroundStyle(color)
    }
}

// MARK: - Ornaments

/// Classic khatam — two overlapping rotated squares forming an 8-pointed star.
struct EightPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<2 {
            let rotation = CGFloat(i) * .pi / 4
            var square = Path()
            for j in 0..<4 {
                let angle = rotation + CGFloat(j) * .pi / 2
                let point = CGPoint(x: center.x + radius * cos(angle),
                                    y: center.y + radius * sin(angle))
                if j == 0 { square.move(to: point) } else { square.addLine(to: point) }
            }
            square.closeSubpath()
            path.addPath(square)
        }
        return path
    }
}

/// hairline — ✦ — hairline
struct StarDivider: View {
    var color: Color = .sakinaGold

    var body: some View {
        HStack(spacing: 14) {
            line(reversed: false)
            EightPointStar()
                .fill(color)
                .frame(width: 9, height: 9)
            line(reversed: true)
        }
    }

    private func line(reversed: Bool) -> some View {
        LinearGradient(colors: reversed ? [color.opacity(0.55), .clear] : [.clear, color.opacity(0.55)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 1)
            .frame(maxWidth: 72)
    }
}

// MARK: - Atmosphere

/// Layered ambient background: ink canvas, a warm gold breath in one corner,
/// and an optional chapter-hue glow rising from the opposite edge.
struct AtmosphereBackground: View {
    var hue: Color? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Color.sakinaCanvas

            RadialGradient(
                colors: [Color.sakinaGold.opacity(scheme == .dark ? 0.13 : 0.20), .clear],
                center: UnitPoint(x: 0.92, y: -0.08),
                startRadius: 10, endRadius: 460
            )

            if let hue {
                RadialGradient(
                    colors: [hue.opacity(scheme == .dark ? 0.16 : 0.14), .clear],
                    center: UnitPoint(x: 0.02, y: 1.08),
                    startRadius: 10, endRadius: 520
                )
            }

            LinearGradient(
                colors: [.clear, Color.black.opacity(scheme == .dark ? 0.35 : 0.04)],
                startPoint: .center, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card chrome

struct CardBackground: ViewModifier {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.sakinaElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [tint.opacity(0.38), Color.sakinaHairline.opacity(0.9)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
            )
    }
}

extension View {
    func sakinaCard(tint: Color = .clear, cornerRadius: CGFloat = 22) -> some View {
        modifier(CardBackground(tint: tint, cornerRadius: cornerRadius))
    }
}

// MARK: - Toast

struct Toast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            EightPointStar().fill(Color.sakinaGold).frame(width: 10, height: 10)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.sakinaInk)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(Color.sakinaElevated))
        .overlay(Capsule().strokeBorder(Color.sakinaGold.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
}
