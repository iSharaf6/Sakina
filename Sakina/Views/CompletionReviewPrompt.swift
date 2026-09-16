import StoreKit
import SwiftUI

private struct CompletionReviewPrompt: ViewModifier {
    let completionID: String
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: completionID) { @MainActor in
            let policy = ReviewPromptPolicy.shared
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            policy.recordCompletion(id: completionID)
            guard policy.isEligible(version: version) else { return }

            // Let the completion settle. Leaving this screen cancels the task.
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            guard !Task.isCancelled, scenePhase == .active,
                  policy.isEligible(version: version) else { return }
            policy.recordRequest(version: version)
            requestReview()
        }
    }
}

extension View {
    /// Attach only to a visible completed-session view, never launch or onboarding.
    func haneenReviewAfterCompletion(id: String) -> some View {
        modifier(CompletionReviewPrompt(completionID: id))
    }
}
