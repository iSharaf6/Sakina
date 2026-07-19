import SwiftUI
import SwiftData

@main
struct SakinaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Bookmark.self, JournalEntry.self])
    }
}

// MARK: Root

struct RootView: View {
    enum Tab: Hashable { case verses, library }

    @State private var selection: Tab = .verses
    @State private var path = NavigationPath()
    @StateObject private var router = NotificationRouter.shared

    var body: some View {
        TabView(selection: $selection) {
            HomeView(path: $path)
                .tabItem { Label("Verses", systemImage: "book.closed.fill") }
                .tag(Tab.verses)

            LibraryView()
                .tabItem { Label("Library", systemImage: "bookmark.fill") }
                .tag(Tab.library)
        }
        .tint(.sakinaGold)
        .onAppear {
            router.activate()
            ReminderScheduler.refresh()
        }
        .onOpenURL { url in
            // Widget deep link: sakina://situation/<id>
            guard url.scheme == "sakina", url.host == "situation",
                  let id = url.pathComponents.dropFirst().first,
                  let situation = SituationCatalog.by(id: id) else { return }
            open(situation)
        }
        .onChange(of: router.pendingSituationID) { _, newValue in
            guard let newValue,
                  let situation = SituationCatalog.by(id: newValue) else { return }
            router.pendingSituationID = nil
            open(situation)
        }
    }

    private func open(_ situation: Situation) {
        selection = .verses
        path = NavigationPath()
        path.append(situation)
    }
}
