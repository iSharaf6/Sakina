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
    enum Tab: Hashable { case home, explore, saved, settings }

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var selection: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @StateObject private var router = NotificationRouter.shared
    @ObservedObject private var account = GoogleAccountManager.shared

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(path: $homePath)
                .tabItem { Label(copy("Home", "الرئيسية"), systemImage: "house.fill") }
                .tag(Tab.home)

            ExploreView(path: $explorePath)
                .tabItem { Label(copy("Explore", "استكشف"), systemImage: "square.grid.2x2.fill") }
                .tag(Tab.explore)

            LibraryView()
                .tabItem { Label(copy("Saved", "المحفوظات"), systemImage: "bookmark.fill") }
                .tag(Tab.saved)

            SettingsView()
                .tabItem { Label(copy("Settings", "الإعدادات"), systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(.sakinaInk)
        .yaqeenLanguage(language)
        .onAppear {
            router.activate()
            ReminderScheduler.refresh()
            account.restorePreviousSignIn()
        }
        .onOpenURL { url in
            if account.handle(url) { return }
            guard let scheme = url.scheme, ["sakina", "yaqeen"].contains(scheme) else { return }

            if url.host == "prayer-times" {
                selection = .home
                homePath = NavigationPath()
                return
            }

            // Guidance widget deep link: sakina://situation/<id>
            guard url.host == "situation",
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
        selection = .explore
        explorePath = NavigationPath()
        explorePath.append(situation)
    }
}
