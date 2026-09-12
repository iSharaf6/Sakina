import SwiftUI
import UIKit

/// An optional, finite pause. The 4/6 rhythm is a UI guide, not a prescribed act of worship.
struct BreathingView: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = 0
    @State private var cycle = 0
    @State private var started = false
    private let paper = Color(red: 0.98, green: 0.97, blue: 0.94)
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ZStack {
            SanctuaryForest().ignoresSafeArea()
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Text(copy("A MOMENT FOR YOU", "لحظة لك")).font(.caption2.weight(.semibold)).tracking(language == .english ? 2 : 0)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).frame(width: 44, height: 44)
                    }
                        .accessibilityLabel(copy("Close breathing pause", "إغلاق استراحة التنفس"))
                }
                Spacer(minLength: 30)
                ZStack {
                    Circle().stroke(paper.opacity(0.12), lineWidth: 1).frame(width: 246, height: 246)
                    Circle().stroke(paper.opacity(0.65), lineWidth: 1)
                        .frame(width: 190, height: 190)
                        .scaleEffect(reduceMotion ? 1 : phase == 1 ? 1.27 : 0.84)
                        .animation(reduceMotion ? nil : .easeInOut(duration: phase == 1 ? 4 : 6), value: phase)
                    CompanionIllustration(artwork: .breathe, size: 108, onDarkSurface: true)
                }
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(!started ? copy("Just this moment.", "هذه اللحظة فقط.") : phase == 3 ? copy("A little more room.", "فسحة أوسع في قلبك.") : phase == 1 ? copy("Breathe in.", "خذ شهيقًا.") : copy("Let it go.", "أخرج الهواء بهدوء."))
                        .font(.system(.largeTitle, weight: .medium)).tracking(-1)
                        .contentTransition(.opacity)
                    Text(!started ? copy("Breathe gently, at your own pace.", "تنفس بهدوء، بالوتيرة التي تناسبك.") : phase == 3 ? copy("Take this softness with you.", "خذ هذا الهدوء معك.") : copy("Nothing else to do right now.", "لا شيء آخر عليك فعله الآن."))
                        .font(.subheadline).foregroundStyle(paper.opacity(0.8))
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)
                Spacer(minLength: 30)
                if !started {
                    Button { started = true } label: { Text(copy("Begin", "ابدأ")).font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 54) }
                        .foregroundStyle(Color(red: 0.08, green: 0.23, blue: 0.19))
                        .background(paper, in: Capsule())
                        .buttonStyle(YaqeenPressStyle())
                } else {
                    Button { dismiss() } label: {
                        Text(phase == 3 ? copy("Back to my day", "العودة إلى يومي") : copy("Finish here", "اكتفِ بهذا القدر"))
                            .font(.body.weight(.medium)).frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .background(paper.opacity(0.12), in: Capsule())
                    .buttonStyle(YaqeenPressStyle())
                }
                Text(started && phase != 3 ? copy("\(cycle + 1) of 3 breaths", "النَّفَس \(cycle + 1) من ٣") : copy("A pause, whenever you need one.", "استراحة كلما احتجت إليها."))
                    .font(.caption).foregroundStyle(paper.opacity(0.7))
            }
            .foregroundStyle(paper)
            .padding(.horizontal, 30).padding(.top, 18).padding(.bottom, 24)
        }
        .task(id: started && scenePhase == .active) {
            guard started, scenePhase == .active else { return }
            // A backgrounded session restarts its unfinished breath on return.
            do {
                while cycle < 3 {
                    phase = 1
                    try await Task.sleep(for: .seconds(4))
                    phase = 2
                    try await Task.sleep(for: .seconds(6))
                    cycle += 1
                }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) { phase = 3 }
            } catch { /* The view disappeared or the app became inactive. */ }
        }
        .preferredColorScheme(.dark)
        .onChange(of: phase) { _, value in
            guard UIAccessibility.isVoiceOverRunning else { return }
            let announcement = value == 1 ? copy("Breathe in", "خذ شهيقًا")
                : value == 2 ? copy("Breathe out", "أخرج الهواء بهدوء")
                : copy("Breathing pause complete", "اكتملت استراحة التنفس")
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
}
