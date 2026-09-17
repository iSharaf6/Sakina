import SwiftData
import SwiftUI
import UIKit
import XCTest
@testable import Sakina

@MainActor
final class AccountHubContentTests: XCTestCase {
    func testLibraryCountsDistinctOpenableContentAndKeepsOrphanReflections() throws {
        var annotated = AyahMark(key: "1:1")
        annotated.bookmarked = true
        annotated.highlight = .green
        annotated.note = "A reflection on this ayah"
        var duplicate = annotated
        duplicate.favourite = true
        var whitespace = AyahMark(key: "1:2")
        whitespace.note = " \n "
        var stale = AyahMark(key: "999:999")
        stale.bookmarked = true
        stale.note = "A removed reference"
        let duaID = try XCTUnwrap(DuaCollection.allEntries.first?.id)
        let situationID = try XCTUnwrap(SituationCatalog.all.first?.id)

        let summary = AccountLibrarySummary(
            marks: [annotated, duplicate, whitespace, stale],
            savedDuas: "\(duaID)|removed-dua|\(duaID)",
            situationIDs: [situationID, situationID, "removed-situation"],
            reflectionTexts: ["Saved words, even if the original reading is gone", " \n "]
        )

        XCTAssertEqual(summary.ayat, 1, "Multiple marks on the same ayah are one library item")
        XCTAssertEqual(summary.notes, 1)
        XCTAssertEqual(summary.duas, 1, "Stale saved IDs must not inflate a destination's count")
        XCTAssertEqual(summary.moments, 1)
        XCTAssertEqual(summary.reflections, 1, "Written reflections do not depend on a surviving catalog reference")
    }

    func testContinueReadingRequiresAValidSavedAyah() {
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: nil))
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: ""))
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: "999:999"))
        XCTAssertEqual(AccountLibrarySummary.readingAyah(for: "2:255")?.key, "2:255")
    }

    func testRoutineCountsOnlyChosenGoalsAndRollsOverToNewDay() throws {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let morningDone = GoalLog.toggling("morning", on: today, in: "")
        let includesDisabled = GoalLog.toggling("sleep", on: today, in: morningDone)
        let summary = AccountRoutineSummary(enabledRaw: "morning|quran", logRaw: includesDisabled, on: today)
        XCTAssertEqual(summary.completed, 1)
        XCTAssertEqual(summary.progress, 0.5)
        XCTAssertEqual(summary.nextGoal?.id, "quran")

        let newDay = AccountRoutineSummary(enabledRaw: "morning|quran", logRaw: includesDisabled, on: tomorrow)
        XCTAssertEqual(newDay.completed, 0)
        XCTAssertEqual(newDay.progress, 0)
        XCTAssertEqual(newDay.nextGoal?.id, "morning")

        let noGoals = AccountRoutineSummary(enabledRaw: GoalPreferences.none, logRaw: includesDisabled, on: today)
        XCTAssertTrue(noGoals.enabled.isEmpty)
        XCTAssertEqual(noGoals.completed, 0)
        XCTAssertEqual(noGoals.progress, 0)
        XCTAssertNil(noGoals.nextGoal)
    }

    /// Reproduce Settings → Your space → Sources → Privacy with the real
    /// destinations. An embedded About NavigationStack adds a second UIKit
    /// navigation controller and breaks retention of the outer account path.
    func testSourcesPrivacyUsesSingleRootStackAndPreservesAccountOnReturn() async throws {
        let state = SourcesNavigationState()
        let container = try ModelContainer(for: Bookmark.self, JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        try await withHosted(SourcesNavigationHarness(state: state).modelContainer(container)) { host in
            try await waitForNavigationDepth(1, in: host)
            state.path.append(AccountHubRoute.space)
            try await waitForNavigationDepth(2, in: host)
            state.path.append(AccountHubRoute.sources)
            try await waitForNavigationDepth(3, in: host)

            state.revision += 1
            try await Task.sleep(for: .milliseconds(150))
            try await waitForNavigationDepth(3, in: host)
            XCTAssertEqual(state.path.count, 2, "Sources must not pop back to Settings during a root update")

            for child in [AboutRoute.privacy, .support] {
                state.path.append(child)
                try await waitForNavigationDepth(4, in: host)
                state.revision += 1
                try await Task.sleep(for: .milliseconds(150))
                try await waitForNavigationDepth(4, in: host)
                XCTAssertEqual(state.path.count, 3)
                state.path.removeLast()
                try await waitForNavigationDepth(3, in: host)
            }
            state.path.removeLast()
            try await waitForNavigationDepth(2, in: host)
            XCTAssertEqual(state.path.count, 1, "Back from Sources must return to Your space")
            state.path.removeLast()
            try await waitForNavigationDepth(1, in: host)
        }
    }

    func testSourcesSheetOwnsExactlyOneNavigationStack() async throws {
        try await withHosted(AboutSheet()) { host in
            try await waitForNavigationDepth(1, in: host)
        }
    }

    private func withHosted<Content: View>(
        _ content: Content, perform: (UIHostingController<Content>) async throws -> Void
    ) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let host = UIHostingController(rootView: content)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKeyAndVisible()
        }
        try await perform(host)
    }

    private func waitForNavigationDepth(_ depth: Int, in host: UIViewController) async throws {
        for _ in 0..<100 {
            host.view.layoutIfNeeded()
            let stacks = navigationControllers(in: host)
            if stacks.count == 1, let navigation = stacks.first,
               navigation.viewControllers.count == depth,
               navigation.transitionCoordinator == nil { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        let stacks = navigationControllers(in: host)
        XCTAssertEqual(stacks.count, 1, "A pushed legal screen must reuse its containing stack")
        XCTAssertEqual(stacks.first?.viewControllers.count, depth, "The legal route must remain open")
        throw SourcesNavigationFailure.unexpectedStack
    }

    private func navigationControllers(in controller: UIViewController) -> [UINavigationController] {
        let current = (controller as? UINavigationController).map { [$0] } ?? []
        return current + controller.children.flatMap { navigationControllers(in: $0) }
    }

    @MainActor
    private final class SourcesNavigationState: ObservableObject {
        @Published var path = NavigationPath()
        @Published var revision = 0
        let account = CompanionAccount(client: nil, observeAuthState: false)
    }

    private struct SourcesNavigationHarness: View {
        @ObservedObject var state: SourcesNavigationState

        var body: some View {
            NavigationStack(path: $state.path) {
                Text("Settings \(state.revision)")
                    .navigationDestination(for: AccountHubRoute.self) { route in
                        if route == .space {
                            CompanionAccountView(account: state.account)
                        } else {
                            AccountHubDestination(route: route, language: .english)
                        }
                    }
                    .aboutDestinations(language: .english)
            }
            .transaction { $0.disablesAnimations = true }
        }
    }

    private enum SourcesNavigationFailure: Error { case unexpectedStack }
}
