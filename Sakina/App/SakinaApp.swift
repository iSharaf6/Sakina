import SwiftUI
import SwiftData

@main
struct SakinaApp: App {
    init() { MushafPreferences.migrate() }
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-yqWidgetGallery") {
                CompanionWidgetGallery()
            } else if ProcessInfo.processInfo.arguments.contains("-yqPrayerCards") {
                CompanionPrayerCardGallery()
            } else {
                RootView()
            }
            #else
            RootView()
            #endif
        }
        .modelContainer(for: [Bookmark.self, JournalEntry.self])
    }
}

/// Value routes inside the Qur'an tab.
enum MushafRoute: Hashable {
    case library
}

// MARK: Root

struct RootView: View {
    enum Tab: Hashable { case home, explore, quran, duas, saved }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .system
    @State private var selection: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @State private var duaPath = NavigationPath()
    @State private var quranPath = NavigationPath()
    @State private var quranKey: String?
    @State private var debugAyah: QuranAyah?
    @State private var exploreQuery = ""
    @State private var showQibla = false
    @State private var prayerRequest = 0
    @State private var settingsRequest = 0
    @StateObject private var router = NotificationRouter.shared
    @StateObject private var scholarStore = ScholarContentStore()
    @ObservedObject private var account = GoogleAccountManager.shared

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(path: $homePath, prayerRequest: prayerRequest, settingsRequest: settingsRequest, openSearch: { query in
                exploreQuery = query
                explorePath = NavigationPath()
                selection = .explore
            })
            .tabItem { tabLabel(copy("Home", "الرئيسية"), symbol: "house", tab: .home) }
            .tag(Tab.home)

            ExploreView(path: $explorePath, searchText: $exploreQuery)
                .tabItem { tabLabel(copy("Explore", "استكشف"), symbol: "square.grid.2x2", tab: .explore) }
                .tag(Tab.explore)

            NavigationStack(path: $quranPath) {
                MushafView(language: language, initialKey: quranKey)
                    .id(quranKey ?? "")
                    .navigationDestination(for: MushafRoute.self) { route in
                        switch route {
                        case .library: AyahLibraryView(language: language)
                        }
                    }
            }
            .tabItem { tabLabel(copy("Qur’an", "القرآن"), symbol: "book.closed", tab: .quran) }
            .tag(Tab.quran)

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
        .preferredColorScheme(theme.colorScheme)
        .environmentObject(scholarStore)
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(item: $debugAyah) { ayah in
            AyahActionSheet(ayah: ayah, language: language)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
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
            Haptics.prepare()
            QuranStore.warmUp()
            QuranScriptStore.warmUp()
            HafsSmartStore.warmUp()
            QuranTranslationStore.warmUp()
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
        Label {
            Text(title)
        } icon: {
            if let image = Self.tabArtwork[tab] {
                Image(uiImage: image).renderingMode(.original)
            } else {
                Image(systemName: symbol)
            }
        }
    }

    // Native tab bars use a UIImage's point size, rather than a SwiftUI frame.
    private static let tabArtwork: [Tab: UIImage] = [
        Tab.home: CompanionArtwork.morning, .explore: .ummah,
        .quran: .quran, .duas: .sunnah, .saved: .saved,
    ].compactMapValues { artwork in
        guard let image = UIImage(named: artwork.assetName) else { return nil }
        return UIGraphicsImageRenderer(size: CGSize(width: 29, height: 29)).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: 29, height: 29))
        }.withRenderingMode(.alwaysOriginal)
    }

    /// Debug builds accept `-yqScreen <route>` so any screen can be opened
    /// directly for screenshots: explore, group:<id>, situation:<id>, duas,
    /// feelings, mood:<id>, practice:<id>, saved, prayers, settings.
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
            case "settings":
                settingsRequest += 1
            case "counter", "ruqyah", "benefits", "goals":
                selection = .duas
                let routes: [String: DuaRoute] = ["counter": .counter, "ruqyah": .ruqyah, "benefits": .benefits, "goals": .goals]
                if let route = routes[parts[0]] { duaPath.append(route) }
                if parts[0] == "counter", let item = DhikrCatalog.item(id: argument) { duaPath.append(item) }
            case "mushaf":
                selection = .quran
                if !argument.isEmpty { quranKey = argument }
            case "ayah":
                selection = .quran
                debugAyah = QuranStore.shared.ayah(argument)
            case "myayat":
                selection = .quran
                quranPath.append(MushafRoute.library)
            case "mosques", "halal":
                selection = .explore
                explorePath.append(parts[0] == "mosques" ? NearbyPlaceKind.mosques : NearbyPlaceKind.halal)
            case "prayers":
                prayerRequest += 1
            default:
                break
            }
        }
        #endif
    }
}
