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
    enum Tab: Hashable { case home, explore, duas, saved }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @State private var selection: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @State private var duaPath = NavigationPath()
    @State private var exploreQuery = ""
    @State private var showQibla = false
    @State private var prayerRequest = 0
    @StateObject private var router = NotificationRouter.shared
    @StateObject private var scholarStore = ScholarContentStore()
    @ObservedObject private var account = GoogleAccountManager.shared

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(path: $homePath, prayerRequest: prayerRequest, openSearch: { query in
                exploreQuery = query
                explorePath = NavigationPath()
                selection = .explore
            })
            .tabItem { tabLabel(copy("Home", "الرئيسية"), symbol: "house", tab: .home) }
            .tag(Tab.home)

            ExploreView(path: $explorePath, searchText: $exploreQuery)
                .tabItem { tabLabel(copy("Explore", "استكشف"), symbol: "square.grid.2x2", tab: .explore) }
                .tag(Tab.explore)

            NavigationStack(path: $duaPath) {
                DuasView()
            }
            .tabItem { tabLabel(copy("Du’as", "الأدعية"), symbol: "text.book.closed", tab: .duas) }
            .tag(Tab.duas)

            LibraryView()
                .tabItem { tabLabel(copy("Saved", "المحفوظات"), symbol: "bookmark", tab: .saved) }
                .tag(Tab.saved)
        }
        .tint(.yqAccent)
        .yaqeenLanguage(language)
        .environmentObject(scholarStore)
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $showQibla) {
            NavigationStack {
                QiblaView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(copy("Done", "تم")) { showQibla = false }
                        }
                    }
            }
        }
        .task {
            await Task.detached(priority: .utility) { GuidanceCatalog.prepareSearch() }.value
            await scholarStore.loadProfileAndPublishedInsights()
        }
        .onAppear {
            router.activate()
            ReminderScheduler.refresh()
            account.restorePreviousSignIn()
            handlePendingIntent()
            applyDebugRoute()
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
                prayerRequest += 1
                return
            }

            if url.host == "qibla" {
                showQibla = true
                return
            }

            if url.host == "duas" {
                selection = .duas
                duaPath = NavigationPath()
                if let id = url.pathComponents.dropFirst().first, let dua = DuaCollection.dua(id) {
                    duaPath.append(dua)
                }
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
            showQibla = true
        }
    }

    private func tabLabel(_ title: String, symbol: String, tab: Tab) -> some View {
        Label(title, systemImage: selection == tab ? "\(symbol).fill" : symbol)
    }

    /// Debug builds accept `-yqScreen <route>` so any screen can be opened
    /// directly for screenshots: explore, group:<id>, situation:<id>, duas,
    /// feelings, mood:<id>, practice:<id>, saved, prayers.
    private func applyDebugRoute() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-yqScreen"), index + 1 < args.count else { return }
        let parts = args[index + 1].split(separator: ":", maxSplits: 1).map(String.init)
        let argument = parts.count > 1 ? parts[1] : ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            switch parts[0] {
            case "explore":
                selection = .explore
            case "group":
                selection = .explore
                if let group = GuidanceCatalog.groups.first(where: { $0.id.rawValue == argument }) { explorePath.append(group) }
            case "situation":
                selection = .explore
                if let situation = SituationCatalog.by(id: argument) { explorePath.append(situation) }
            case "duas":
                selection = .duas
            case "feelings":
                selection = .duas
                duaPath.append(DuaRoute.feelings)
            case "mood":
                selection = .duas
                if let mood = DuaMood(rawValue: argument) { duaPath.append(mood) }
            case "practice":
                selection = .duas
                if let practice = DuaPractice(rawValue: argument) { duaPath.append(practice) }
            case "saved":
                selection = .saved
            case "prayers":
                prayerRequest += 1
            default:
                break
            }
        }
        #endif
    }
}
