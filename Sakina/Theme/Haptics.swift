import SwiftUI
import UIKit

/// One place for every haptic in the app, graded so that taps, counts and
/// completions each feel different. Generators are kept warm; the whole
/// system respects the Haptics switch in Settings.
enum Haptics {
    static let enabledKey = "hapticsEnabled"

    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Warm the generators so the first tap lands without latency.
    static func prepare() {
        guard isEnabled else { return }
        light.prepare()
        rigid.prepare()
        selectionGenerator.prepare()
    }

    /// A button or row was pressed.
    static func tap() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.85)
    }

    /// A gentle touch: chips, toggles, small controls.
    static func press() {
        guard isEnabled else { return }
        soft.impactOccurred(intensity: 0.7)
    }

    /// One bead of dhikr. Crisp, so fast counting feels like a tasbih.
    static func count() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 0.95)
        rigid.prepare()
    }

    /// A stronger click for a marked step: a goal ticked, a page finished.
    static func thud() {
        guard isEnabled else { return }
        medium.impactOccurred(intensity: 1)
    }

    /// Picker or tab changed.
    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    static func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    /// A two-beat pulse for reaching 33, 66, 99, 100 or a target.
    static func milestone() {
        guard isEnabled else { return }
        medium.impactOccurred(intensity: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            heavy.impactOccurred(intensity: 1)
        }
    }

    /// A rising three-beat flourish for finishing something whole.
    static func celebrate() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { medium.impactOccurred(intensity: 0.9) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { notification.notificationOccurred(.success) }
    }
}

extension View {
    /// Fires a haptic whenever `value` changes.
    func haptic<T: Equatable>(_ kind: HapticKind, on value: T) -> some View {
        onChange(of: value) { _, _ in kind.fire() }
    }
}

enum HapticKind {
    case tap, press, count, thud, selection, success, warning, milestone, celebrate

    func fire() {
        switch self {
        case .tap: Haptics.tap()
        case .press: Haptics.press()
        case .count: Haptics.count()
        case .thud: Haptics.thud()
        case .selection: Haptics.selection()
        case .success: Haptics.success()
        case .warning: Haptics.warning()
        case .milestone: Haptics.milestone()
        case .celebrate: Haptics.celebrate()
        }
    }
}
