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
    enum Tab: Hashable { case home, explore, qibla, saved, settings }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var selection: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @StateObject private var router = NotificationRouter.shared
    @StateObject private var scholarStore = ScholarContentStore()
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

            NavigationStack {
                QiblaView()
            }
            .tabItem { Label(copy("Qibla", "القبلة"), systemImage: "location.north.circle.fill") }
            .tag(Tab.qibla)

            LibraryView()
                .tabItem { Label(copy("Saved", "المحفوظات"), systemImage: "bookmark.fill") }
                .tag(Tab.saved)

            SettingsView()
                .tabItem { Label(copy("Settings", "الإعدادات"), systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(.sakinaInk)
        .yaqeenLanguage(language)
        .environmentObject(scholarStore)
        .task {
            await scholarStore.loadProfileAndPublishedInsights()
        }
        .onAppear {
            router.activate()
            ReminderScheduler.refresh()
            account.restorePreviousSignIn()
            handlePendingIntent()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { handlePendingIntent() }
        }
        .onOpenURL { url in
            if account.isConfigured, account.handle(url) { return }
            guard let scheme = url.scheme, ["sakina", "yaqeen"].contains(scheme) else { return }

            if url.host == "prayer-times" {
                selection = .home
                homePath = NavigationPath()
                return
            }

            if url.host == "qibla" {
                selection = .qibla
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

    private func handlePendingIntent() {
        guard let destination = YaqeenIntentDestination.consume() else { return }
        switch destination {
        case .today:
            open(SharedStore.situationOfTheDay())
        case .qibla:
            selection = .qibla
        }
    }
}
