import SwiftData
import SwiftUI
import UIKit
import XCTest
@testable import Sakina

final class GuidanceNavigationTests: XCTestCase {
    func testEveryLifeTopicHasAResolvableStableRoute() throws {
        XCTAssertEqual(Set(GuidanceCatalog.groups.map(\.id)), Set(LifeGroupID.allCases))
        for group in GuidanceCatalog.groups {
            let groupRoute = GuidanceRoute.group(group.id)
            XCTAssertEqual(groupRoute.group?.id, group.id)
            XCTAssertFalse(group.stages.isEmpty)
            for stage in group.stages {
                XCTAssertEqual(stage.situations.count, stage.situationIDs.count,
                               "A life topic must never silently disappear: \(stage.id)")
                for id in stage.situationIDs {
                    let route = GuidanceRoute.situation(id)
                    let situation = try XCTUnwrap(route.situation, "\(group.id)/\(stage.id)/\(id)")
                    XCTAssertFalse(situation.verses.isEmpty, "\(id) must open a real reading")
                    let restored = try JSONDecoder().decode(GuidanceRoute.self,
                        from: JSONEncoder().encode(route))
                    XCTAssertEqual(restored, route)
                    XCTAssertEqual(restored.situation?.id, id)
                }
            }
        }
        XCTAssertNil(GuidanceRoute.situation("unavailable-topic").situation)
    }

    /// Exercise SwiftUI's actual stack, not only catalog lookup. Opening a
    /// child must survive a re-render of Explore's conditional root rows and
    /// popping must return to the same group, instead of replacing its route.
    @MainActor
    func testLifeGroupDrillDownSurvivesRootUpdatesAndBackNavigation() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.windows.first { $0.isKeyWindow }
        let state = NavigationState()
        let container = try ModelContainer(for: Bookmark.self, JournalEntry.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let scholar = ScholarContentStore(client: nil, cache: ScholarContentCache(fileURL: nil))
        let host = UIHostingController(rootView: NavigationHarness(state: state)
            .modelContainer(container)
            .environmentObject(scholar))
        let window = UIWindow(windowScene: scene)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        try await waitForDepth(1, in: host)
        for group in GuidanceCatalog.groups {
            state.path = NavigationPath([GuidanceRoute.group(group.id)])
            try await waitForDepth(2, in: host)
            for situation in [group.situations.first, group.situations.last].compactMap({ $0 }) {
                state.path.append(GuidanceRoute.situation(situation.id))
                try await waitForDepth(3, in: host)
                state.query = "faith"
                try await Task.sleep(for: .milliseconds(100))
                try await waitForDepth(3, in: host)
                XCTAssertEqual(state.path.count, 2, "Root update popped \(situation.id)")

                state.path.removeLast()
                try await waitForDepth(2, in: host)
                XCTAssertEqual(state.path.count, 1, "Back must preserve \(group.id)")
                state.query = ""
            }
            state.path = NavigationPath()
            try await waitForDepth(1, in: host)
        }
    }

    @MainActor
    private func waitForDepth(_ depth: Int, in host: UIViewController) async throws {
        for _ in 0..<100 {
            host.view.layoutIfNeeded()
            if let navigation = navigationController(in: host),
               navigation.viewControllers.count == depth,
               navigation.transitionCoordinator == nil { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(navigationController(in: host)?.viewControllers.count, depth,
                       "Guidance route was not retained by the stack")
        throw NavigationFailure.unexpectedDepth
    }

    @MainActor
    private func navigationController(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController { return navigation }
        return controller.children.lazy.compactMap { self.navigationController(in: $0) }.first
    }

    @MainActor
    private final class NavigationState: ObservableObject {
        @Published var path = NavigationPath()
        @Published var query = ""
    }

    private struct NavigationHarness: View {
        @ObservedObject var state: NavigationState

        var body: some View {
            ExploreView(path: $state.path, searchText: $state.query)
                .transaction { $0.disablesAnimations = true }
        }
    }

    private enum NavigationFailure: Error { case unexpectedDepth }
}
