import Combine
import DeclaredAgeRange
import OSLog
import SwiftUI

/// Initial-release age assurance only. Apple handles permission for the initial
/// download and prevents launch after parental consent is revoked. Future
/// significant changes must separately implement PermissionKit approval.
@MainActor
final class AgeAssuranceCheck: ObservableObject {
    enum State: Equatable {
        case idle, deferredRequired, complete
        case checking(required: Bool)
        case retry(required: Bool)

        var blocksAccess: Bool {
            switch self {
            case .deferredRequired, .checking(required: true), .retry(required: true): return true
            default: return false
            }
        }
    }
    enum FlowError: Error { case presentationDeferred }

    @Published private(set) var state: State = .idle

    /// The framework's eligibility lookup comes before the feature-specific
    /// requirements. A device/account outside that scope must not be prompted.
    static func requiresSharing(eligibility: () async throws -> Bool,
                                regulatoryRequirement: () async throws -> Bool) async throws -> Bool {
        guard try await eligibility() else { return false }
        return try await regulatoryRequirement()
    }

    // Keep only the result of this check in memory, never an age, date of birth,
    // Apple account identifier or parental-control response.
    func run(retry: Bool = false,
             requirement: () async throws -> Bool,
             request: () async throws -> Bool) async {
        guard state == .idle || state == .deferredRequired || (retry && canRetry) else { return }
        var required = state.blocksAccess
        var stage = "regional requirements"
        state = .checking(required: required)
        do {
            required = try await requirement()
            if required {
                state = .checking(required: true)
                stage = "age range request"
                guard try await request() else {
                    state = .retry(required: true)
                    return
                }
            }
            state = .complete
        } catch FlowError.presentationDeferred {
            state = required ? .deferredRequired : .idle
        } catch {
            #if DEBUG
            let failure = error as NSError
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "Haneen", category: "AgeAssurance")
                .error("Age assurance \(stage, privacy: .public) failed: \(failure.domain, privacy: .public) code \(failure.code, privacy: .public)")
            #endif
            state = .retry(required: required)
        }
    }

    private var canRetry: Bool {
        if case .retry = state { return true }
        return false
    }
}

extension View {
    @ViewBuilder
    func haneenAgeAssurance(language: AppLanguage, canPresent: Bool) -> some View {
        if #available(iOS 26.2, *) {
            modifier(RegionalAgeAssurance(language: language, canPresent: canPresent))
        } else {
            self
        }
    }
}

@available(iOS 26.2, *)
private struct RegionalAgeAssurance: ViewModifier {
    let language: AppLanguage
    let canPresent: Bool
    @Environment(\.requestAgeRange) private var requestAgeRange
    @StateObject private var check = AgeAssuranceCheck()
    @State private var presentationAllowed = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if canPresent, check.state.blocksAccess {
                    ZStack {
                        Color(.systemBackground).ignoresSafeArea()
                        notice(required: true)
                            .padding(24)
                    }
                    .accessibilityAddTraits(.isModal)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if canPresent, case .retry(required: false) = check.state {
                    notice(required: false)
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .onChange(of: canPresent, initial: true) { _, allowed in
                presentationAllowed = allowed
                guard allowed else { return }
                Task { await run() }
            }
    }

    private func notice(required: Bool) -> some View {
        VStack(spacing: 12) {
            Text(language.pick("Check age settings", "التحقق من إعدادات العمر"))
                .font(.headline)
            Text(required
                 ? language.pick("Apple requires an age-range check for this account. Please try again to continue. Your age information is not saved or sent to Haneen’s servers.",
                                 "تتطلب Apple التحقق من الفئة العمرية لهذا الحساب. حاول مرة أخرى للمتابعة. لا تُحفظ معلومات عمرك ولا تُرسل إلى خوادم حنين.")
                 : language.pick("Apple’s age settings could not be checked. You can try again when the service is available.",
                                 "تعذّر التحقق من إعدادات العمر لدى Apple. يمكنك المحاولة مجددًا عند توفر الخدمة."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if case .checking = check.state {
                ProgressView()
            } else {
                Button(language.pick("Try again", "حاول مرة أخرى")) {
                    Task { await run(retry: true) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .multilineTextAlignment(.center)
    }

    @MainActor
    private func run(retry: Bool = false) async {
        await check.run(retry: retry) {
            try await AgeAssuranceCheck.requiresSharing {
                try await AgeRangeService.shared.isEligibleForAgeFeatures
            } regulatoryRequirement: {
                if #available(iOS 26.4, *) {
                    let features = try await AgeRangeService.shared.requiredRegulatoryFeatures
                    return features.contains(.declaredAgeRangeRequired)
                }
                return true
            }
        } request: {
            // Wait until onboarding and existing root presentations have closed.
            guard presentationAllowed else { throw AgeAssuranceCheck.FlowError.presentationDeferred }
            let response = try await requestAgeRange(ageGates: 13, 16, 18)
            switch response {
            case .sharing:
                // Haneen has no adult-only features. Do not turn its store
                // content rating into an age ban for a parent-approved child.
                return true
            case .declinedSharing:
                return false
            @unknown default:
                return false
            }
        }
    }
}
