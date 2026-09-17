import SwiftData
import SwiftUI

/// Resolve access before constructing RootView, so an old account's in-memory
/// SwiftData/defaults cannot briefly appear while the next library is loading.
enum AccountAccessState: Equatable {
    case signIn, preparing, importChoice, ready, unavailable

    static func resolve(signedIn: Bool, userID: UUID?, activeLibraryID: UUID?,
                        isPreparing: Bool, needsImportChoice: Bool, canUseLibrary: Bool,
                        activationFinished: Bool, hasPreparationError: Bool = false) -> Self {
        guard signedIn, let userID else { return .signIn }
        guard !isPreparing else { return activationFinished && hasPreparationError ? .unavailable : .preparing }
        guard activeLibraryID == userID else { return activationFinished ? .unavailable : .preparing }
        if needsImportChoice { return .importChoice }
        if canUseLibrary { return .ready }
        return activationFinished ? .unavailable : .preparing
    }
}

struct AccountAccessGate: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .light
    @ObservedObject private var account: CompanionAccount
    @ObservedObject private var sync: AccountLibrarySync
    @State private var activationFinishedID: UUID?
    @State private var waitingForWelcomeCompletion = false
    @State private var resolvingImport = false
    @State private var showSources = false

    @MainActor init(account: CompanionAccount? = nil, sync: AccountLibrarySync? = nil) {
        _account = ObservedObject(wrappedValue: account ?? .shared)
        _sync = ObservedObject(wrappedValue: sync ?? .shared)
    }

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var access: AccountAccessState {
        AccountAccessState.resolve(signedIn: account.signedIn, userID: account.userID,
            activeLibraryID: sync.currentUserID, isPreparing: sync.isPreparing,
            needsImportChoice: sync.needsImportChoice, canUseLibrary: sync.canUseLibrary,
            activationFinished: account.userID != nil && activationFinishedID == account.userID,
            hasPreparationError: sync.statusMessage != nil)
    }

    var body: some View {
        Group {
            if access == .signIn || waitingForWelcomeCompletion {
                CompanionOnboarding(account: account) { waitingForWelcomeCompletion = false }
                    .onAppear { if !account.signedIn { waitingForWelcomeCompletion = true } }
            } else {
                switch access {
                case .ready:
                    RootView().id(account.userID)
                case .importChoice:
                    if sync.hasPreviousDeviceLibrary {
                        preparationScreen(isImportChoice: true, isBusy: resolvingImport)
                    } else {
                        AccountWelcomeView(language: language, name: account.displayName, email: account.email,
                                           isBusy: resolvingImport || account.busy,
                                           onContinue: { resolveImport(include: false) },
                                           onSwitchAccount: { Task { await account.signOut() } },
                                           onSources: { showSources = true })
                    }
                case .preparing:
                    preparationScreen(isImportChoice: false, isBusy: true)
                case .unavailable:
                    preparationScreen(isImportChoice: false, isBusy: false)
                case .signIn:
                    EmptyView()
                }
            }
        }
        .yaqeenLanguage(language)
        .preferredColorScheme(theme.colorScheme)
        .task(id: account.userID) { await activate() }
        .onOpenURL { url in
            if url.scheme == "yaqeen", url.host == "auth-callback" {
                Task { await account.handle(url) }
            } else {
                _ = GoogleAccountManager.shared.handle(url)
            }
        }
        .sheet(isPresented: $showSources) { AboutSheet() }
    }

    private func activate() async {
        let requestedID = account.userID
        activationFinishedID = nil
        MushafPlayer.shared.stop()
        RecitationPlayer.shared.stop()
        AdhkarAudioPlayer.shared.stop()
        await sync.activate(account: account, context: context)
        guard !Task.isCancelled, requestedID == account.userID else { return }
        activationFinishedID = requestedID
    }

    private func preparationScreen(isImportChoice: Bool, isBusy: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CompanionIllustration(artwork: isImportChoice ? .saved : .backup, size: 100)
                    .frame(maxWidth: .infinity)
                Text(isImportChoice ? (sync.hasPreviousDeviceLibrary ? copy("Bring your library with you", "احتفظ بمحفوظاتك معك") : copy("Your library on this iPhone", "محفوظاتك على هذا الهاتف")) :
                     isBusy ? copy("Opening your library", "جارٍ فتح محفوظاتك") :
                     copy("Your library isn’t ready yet", "محفوظاتك ليست جاهزة بعد"))
                    .font(.yqTitle2).foregroundStyle(Color.yqInk)
                    .accessibilityAddTraits(.isHeader)
                if isImportChoice && sync.hasPreviousDeviceLibrary {
                    Text(copy("An earlier version saved items only on this iPhone. Would you like to add them to this account? Only include them if they belong to you.",
                              "كانت نسخة سابقة تحفظ العناصر على هذا الهاتف فقط. هل ترغب في إضافتها إلى هذا الحساب؟ أضفها فقط إذا كانت تخصّك."))
                        .font(.yqBody).foregroundStyle(Color.yqSecondary)
                    if let email = account.email {
                        Text(email).font(.yqSubheadBold).textSelection(.enabled)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    VStack(spacing: 12) {
                        Button { resolveImport(include: true) } label: {
                            Text(copy("Add this iPhone’s saved library", "إضافة محفوظات هذا الهاتف"))
                                .frame(maxWidth: .infinity).frame(minHeight: 44)
                        }.buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("account.import-legacy")
                        Button { resolveImport(include: false) } label: {
                            Text(copy("Start with my account’s library", "البدء بمحفوظات حسابي"))
                                .frame(maxWidth: .infinity).frame(minHeight: 44)
                        }.buttonStyle(.bordered)
                            .accessibilityIdentifier("account.skip-legacy")
                    }.disabled(isBusy || account.busy)
                    Text(copy("The older device library is kept in a separate backup on this iPhone either way. Your choice does not delete it.",
                              "تُحفظ المحفوظات القديمة في نسخة احتياطية منفصلة على هذا الهاتف في الحالتين. اختيارك لا يحذفها."))
                        .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                } else if isImportChoice {
                    Text(copy("Your saved ayat, du’as, notes, reflections and reading place will be backed up to this account and kept together across your devices. Daily goals, dhikr counts and prayer settings stay on this iPhone.",
                              "ستُنسخ آياتك وأدعيتك وملاحظاتك وتأملاتك وموضع قراءتك احتياطيًا في هذا الحساب، وتبقى معك عبر أجهزتك. وتبقى أهداف اليوم وعدّادات الذكر وإعدادات الصلاة على هذا الهاتف."))
                        .font(.yqBody).foregroundStyle(Color.yqSecondary)
                    if let email = account.email {
                        Text(email).font(.yqSubheadBold).textSelection(.enabled)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    Text(copy("Cloud backups are not end-to-end encrypted. You can delete your account and its cloud library from Your space.",
                              "النسخ السحابية ليست مشفّرة من طرف إلى طرف. يمكنك حذف حسابك ومحفوظاته السحابية من «مساحتك»."))
                        .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    Button { resolveImport(include: false) } label: {
                        Text(copy("Continue to my library", "المتابعة إلى محفوظاتي"))
                            .frame(maxWidth: .infinity).frame(minHeight: 44)
                    }.buttonStyle(.borderedProminent).disabled(isBusy || account.busy)
                        .accessibilityIdentifier("account.start-library")
                } else if isBusy {
                    Text(copy("Preparing the saved items for your account.", "نجهّز العناصر المحفوظة لحسابك."))
                        .font(.yqBody).foregroundStyle(Color.yqSecondary)
                } else {
                    Text(copy("Check your connection and try again. Your saved library has not been replaced.",
                              "تحقق من اتصالك وحاول مرة أخرى. لم يتم استبدال محفوظاتك."))
                        .font(.yqBody).foregroundStyle(Color.yqSecondary)
                    Button(copy("Try again", "حاول مرة أخرى")) { Task { await activate() } }
                        .buttonStyle(.borderedProminent).disabled(account.busy)
                        .accessibilityIdentifier("account.retry-prepare")
                }
                if isBusy { ProgressView().frame(maxWidth: .infinity).accessibilityLabel(copy("Preparing library", "جارٍ تجهيز المحفوظات")) }
                if let message = sync.statusMessage {
                    Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                }
                if let message = account.message {
                    Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                }
                Button(copy("Use another account", "استخدام حساب آخر")) { Task { await account.signOut() } }
                    .frame(minHeight: 44).disabled(isBusy || account.busy)
                HStack(spacing: 20) {
                    Link(copy("Privacy", "الخصوصية"), destination: URL(string: "https://isharaf6.github.io/Sakina/privacy.html")!)
                    Button(copy("Sources & help", "المصادر والمساعدة")) { showSources = true }
                }.font(.yqCaption).frame(minHeight: 44)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(26).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .background(Color.yqSurface.ignoresSafeArea()).tint(.yqAccentDeep)
        .accessibilityIdentifier(isImportChoice ? "account.import-choice" : "account.preparation")
    }

    private func resolveImport(include: Bool) {
        guard !resolvingImport else { return }
        resolvingImport = true
        Task {
            await sync.resolveLegacyImport(include: include)
            resolvingImport = false
        }
    }
}


/// The first screen after a new sign-in: a short animated welcome that also
/// carries the backup disclosure the account needs before its library opens.
struct AccountWelcomeView: View {
    let language: AppLanguage
    let name: String?
    let email: String?
    let isBusy: Bool
    let onContinue: () -> Void
    let onSwitchAccount: () -> Void
    let onSources: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage = 0
    @State private var floating = false

    private var copy: AppCopy { AppCopy(language: language) }
    private var firstName: String? {
        name?.split(separator: " ").first.map(String.init).flatMap { $0.isEmpty ? nil : $0 }
    }
    private var promises: [(CompanionArtwork, String)] {
        [(.saved, copy("Your ayat, du’as and notes stay with your account", "آياتك وأدعيتك وملاحظاتك محفوظة مع حسابك")),
         (.backup, copy("Synced across your devices", "تتزامن بين أجهزتك")),
         (.privacy, copy("No ads, no tracking", "بلا إعلانات ولا تتبّع"))]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            ZStack {
                Circle().fill(Color.yqAccentTint)
                    .frame(width: 190, height: 190)
                    .scaleEffect(stage >= 1 ? 1 : 0.4)
                    .opacity(stage >= 1 ? 1 : 0)
                CompanionIllustration(artwork: .happy, size: 168)
                    .scaleEffect(stage >= 1 ? 1 : 0.6)
                    .opacity(stage >= 1 ? 1 : 0)
                    .offset(y: floating ? -5 : 5)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(copy("Assalamu alaykum", "السلام عليكم") + (firstName.map { language == .arabic ? "، \($0)" : ", \($0)" } ?? ""))
                    .font(.yqTitle2).foregroundStyle(Color.yqInk)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(copy("Welcome to Haneen. Your library is ready.", "أهلًا بك في حنين. محفوظاتك جاهزة."))
                    .font(.yqBody).foregroundStyle(Color.yqSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 22)
            .opacity(stage >= 2 ? 1 : 0)
            .offset(y: stage >= 2 ? 0 : 14)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(promises.enumerated()), id: \.offset) { index, promise in
                    HStack(spacing: 10) {
                        CompanionIllustration(artwork: promise.0, size: 40)
                        Text(promise.1).font(.yqSubheadMedium).foregroundStyle(Color.yqInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .opacity(stage >= 3 + index ? 1 : 0)
                    .offset(x: stage >= 3 + index ? 0 : (language == .arabic ? -18 : 18))
                }
            }
            .padding(14)
            .yqCard(cornerRadius: 20)
            .padding(.top, 26)
            .opacity(stage >= 3 ? 1 : 0)

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                Button(action: onContinue) {
                    ZStack {
                        PrimaryButton(title: isBusy ? "" : copy("Begin", "ابدأ"),
                                      symbol: isBusy ? nil : (language == .arabic ? "arrow.left" : "arrow.right"))
                        if isBusy { ProgressView().tint(Color.yqOnAccent) }
                    }
                }
                .buttonStyle(.yqPress)
                .disabled(isBusy)
                .accessibilityIdentifier("account.start-library")

                Text(copy("Cloud backups are not end-to-end encrypted. You can delete your account and its library any time in Your space.",
                          "النسخ السحابية ليست مشفّرة من طرف إلى طرف. يمكنك حذف حسابك ومحفوظاته في أي وقت من «مساحتك»."))
                    .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 18) {
                    Button(email.map { copy("Not \($0)?", "لست \($0)؟") } ?? copy("Use another account", "استخدام حساب آخر"),
                           action: onSwitchAccount).disabled(isBusy)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Link(copy("Privacy", "الخصوصية"), destination: URL(string: "https://isharaf6.github.io/Sakina/privacy.html")!)
                    Button(copy("Sources", "المصادر"), action: onSources)
                }
                .font(.yqCaption).frame(minHeight: 44)
            }
            .opacity(stage >= 6 ? 1 : 0)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: 520).frame(maxWidth: .infinity, maxHeight: .infinity)
        .yqScreen()
        .tint(.yqAccentDeep)
        .accessibilityIdentifier("account.import-choice")
        .task { await reveal() }
    }

    private func reveal() async {
        guard !reduceMotion else { stage = 6; return }
        for step in 1...6 {
            withAnimation(.spring(response: 0.5, dampingFraction: step == 1 ? 0.62 : 0.85)) { stage = step }
            if step == 1 { Haptics.press() }
            try? await Task.sleep(for: .milliseconds(step == 1 ? 420 : 160))
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { floating = true }
    }
}
