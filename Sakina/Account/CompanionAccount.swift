import SwiftUI
import SwiftData
import Supabase
import AuthenticationServices
import CryptoKit
import Security
import GoogleSignIn

@MainActor
final class CompanionAccount: ObservableObject {
    static let shared = CompanionAccount(client: configuredClient())
    @Published private(set) var email: String?
    @Published private(set) var displayName: String?
    @Published private(set) var userID: UUID?
    @Published private(set) var signedIn = false
    @Published private(set) var busy = false
    @Published var message: String?
    private(set) var client: SupabaseClient?
    private var nonce: String?
    private var stateTask: Task<Void, Never>?
    private enum Operation { case email, verification, google, apple, callback, signOut, deletion }
    private var operation: Operation?
    private var pendingEmailCallback: URL?
    private var completedEmailCallback: URL?
    var configured: Bool { client != nil }
    private var copy: AppCopy {
        AppCopy(language: AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english)
    }

    private static func configuredClient() -> SupabaseClient? {
        func value(_ name: String) -> String? {
            guard let value = Bundle.main.object(forInfoDictionaryKey: name) as? String,
                  !value.isEmpty, !value.contains("$(") else { return nil }
            return value
        }
        if let urlString = value("YaqeenAuthSupabaseURL"), let key = value("YaqeenAuthSupabaseKey"),
           let url = URL(string: urlString), url.scheme == "https" {
            return SupabaseClient(supabaseURL: url, supabaseKey: key)
        }
        return nil
    }

    // An isolated client also lets tests exercise real Auth responses without using production.
    init(client: SupabaseClient?, observeAuthState: Bool = true) {
        self.client = client
        synchronizeSession()
        if let client, observeAuthState {
            stateTask = Task { [weak self] in
                for await _ in client.auth.authStateChanges {
                    guard !Task.isCancelled else { break }
                    // An initial/refresh event can arrive after a newer sign-in or sign-out.
                    // Read the SDK's current session rather than replaying stale event payloads.
                    self?.synchronizeSession()
                }
            }
        }
    }

    deinit { stateTask?.cancel() }

    private func synchronizeSession() {
        let session = client?.auth.currentSession
        email = session?.user.email
        let metadata = session?.user.userMetadata ?? [:]
        displayName = ["full_name", "name", "given_name"]
            .compactMap { metadata[$0]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        userID = session?.user.id
        signedIn = session != nil
    }

    private func begin(_ next: Operation) -> SupabaseClient? {
        guard !busy else { return nil }
        guard let client else {
            message = copy("Sign-in is temporarily unavailable. Please try again shortly.", "تسجيل الدخول غير متاح مؤقتًا. حاول مرة أخرى بعد قليل.")
            return nil
        }
        operation = next
        busy = true
        message = nil
        return client
    }

    private func finishOperation() {
        operation = nil
        busy = false
        if let url = pendingEmailCallback {
            pendingEmailCallback = nil
            if !signedIn { Task { await handle(url) } }
        }
    }

    nonisolated static func validEmail(_ value: String) -> Bool {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    /// Accept pasted separators and Arabic decimal digits without silently discarding other text.
    nonisolated static func normalizedEmailCode(_ value: String) -> String? {
        let compact = value.filter { !$0.isWhitespace && $0 != "-" }
        guard (6...10).contains(compact.count) else { return nil }
        var digits = ""
        for character in compact {
            guard character.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
                  let digit = character.wholeNumberValue, (0...9).contains(digit) else { return nil }
            digits.append(String(digit))
        }
        return digits
    }

    /// One path for new and returning people: Supabase creates the account on first use, so
    /// nobody has to know whether they already have one.
    func sendCode(email: String) async -> Bool {
        guard let client = begin(.email) else { return false }
        defer { finishOperation() }
        guard Self.validEmail(email) else { message = copy("Enter a valid email address.", "أدخل عنوان بريد إلكتروني صحيحًا."); return false }
        do {
            try await client.auth.signInWithOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), redirectTo: URL(string: "yaqeen://auth-callback"), shouldCreateUser: true)
            message = copy("Check your email for your sign-in link or code.", "افتح بريدك الإلكتروني للاطلاع على رابط أو رمز تسجيل الدخول.")
            return true
        } catch {
            message = authMessage(error, emailFlow: true, fallback: copy("The sign-in email couldn’t be sent. Please try again.", "تعذّر إرسال رسالة تسجيل الدخول. حاول مرة أخرى."))
            return false
        }
    }

    func verify(email: String, code: String) async {
        guard let client = begin(.verification) else { return }
        defer { finishOperation() }
        guard Self.validEmail(email) else { message = copy("Enter a valid email address.", "أدخل عنوان بريد إلكتروني صحيحًا."); return }
        guard let code = Self.normalizedEmailCode(code) else {
            message = copy("Enter the complete code from your latest sign-in email.", "أدخل الرمز كاملًا من أحدث رسالة لتسجيل الدخول."); return
        }
        do {
            let response = try await client.auth.verifyOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), token: code, type: .email)
            guard response.session != nil else {
                message = copy("Sign-in isn’t complete yet. Open the link in your latest email, or request a new one.", "لم يكتمل تسجيل الدخول بعد. افتح الرابط في أحدث رسالة، أو اطلب رسالة جديدة."); return
            }
            synchronizeSession()
        } catch { message = authMessage(error, emailFlow: true, fallback: copy("That code didn’t work. Check it and try again, or send another email.", "لم يعمل هذا الرمز. تحقق منه وحاول مرة أخرى، أو أرسل رسالة جديدة.")) }
    }

    func google() async {
        guard let client = begin(.google) else { return }
        defer { finishOperation() }
        do {
            guard let presenter = Self.topViewController() else {
                message = copy("Google’s sign-in screen couldn’t open. Please try again.", "تعذّر فتح شاشة تسجيل الدخول عبر Google. حاول مرة أخرى."); return
            }
            // Google echoes the nonce it is given inside the ID token, and Supabase compares that claim
            // with the SHA-256 of the raw value it receives. Without both, Supabase rejects the token.
            let raw = Self.randomNonce()
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter, hint: nil, additionalScopes: nil, nonce: Self.sha256(raw))
            guard let token = result.user.idToken?.tokenString else {
                message = copy("Google couldn’t complete sign-in. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Google. حاول مرة أخرى."); return
            }
            _ = try await client.auth.signInWithIdToken(credentials: .init(provider: .google, idToken: token, accessToken: result.user.accessToken.tokenString, nonce: raw))
            synchronizeSession()
        } catch {
            let nsError = error as NSError
            if nsError.domain == kGIDSignInErrorDomain, nsError.code == GIDSignInError.canceled.rawValue { return }
            message = authMessage(error, fallback: copy("Google sign-in couldn’t finish. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Google. حاول مرة أخرى."))
        }
    }

    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        guard begin(.apple) != nil else { return }
        let raw = Self.randomNonce()
        nonce = raw
        request.requestedScopes = [.email, .fullName]
        request.nonce = Self.sha256(raw)
    }

    private static func randomNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
            bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func topViewController() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }

    func completeApple(_ result: Result<ASAuthorization, Error>) async {
        guard operation == .apple, let client, let rawNonce = nonce else { return }
        // Consume the challenge once, before the first suspension point.
        nonce = nil
        defer { finishOperation() }
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
                message = copy("Apple couldn’t complete sign-in. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Apple. حاول مرة أخرى."); return
            }
            _ = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: token, nonce: rawNonce))
            synchronizeSession()
        } catch {
            if Self.isAppleCancellation(error) { return }
            message = authMessage(error, fallback: copy("Apple sign-in couldn’t finish. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Apple. حاول مرة أخرى."))
        }
    }

    func handle(_ url: URL) async {
        guard url.scheme == "yaqeen", url.host == "auth-callback", completedEmailCallback != url else { return }
        if busy {
            if operation == .email || operation == .verification || operation == .callback {
                pendingEmailCallback = url
            } else {
                message = copy("Finish the current account action, then open the sign-in link again.", "أكمل الإجراء الحالي للحساب، ثم افتح رابط تسجيل الدخول مرة أخرى.")
            }
            return
        }
        guard let client = begin(.callback) else { return }
        defer { finishOperation() }
        do {
            _ = try await client.auth.session(from: url)
            completedEmailCallback = url
            synchronizeSession()
        } catch {
            message = authMessage(error, emailFlow: true, fallback: copy("That sign-in link couldn’t be used. Request a new email and open its link on this iPhone, or enter its code.", "تعذّر استخدام رابط تسجيل الدخول. اطلب رسالة جديدة وافتح رابطها على هذا الهاتف، أو أدخل رمزها."))
        }
    }

    func signOut() async {
        guard let client = begin(.signOut) else { return }
        defer { finishOperation() }
        // Persist this account's latest edits before credentials disappear. A
        // different account must never inherit the live, device-wide library.
        if let userID, AccountLibrarySync.shared.currentUserID == userID {
            do { try AccountLibrarySync.shared.checkpoint() }
            catch {
                message = copy("Your latest changes couldn’t be saved, so you’re still signed in. Please try again.", "تعذّر حفظ أحدث تغييراتك، لذلك لم يتم تسجيل الخروج. حاول مرة أخرى.")
                return
            }
        }
        do { try await client.auth.signOut(scope: .local) }
        catch {
            // The SDK clears local credentials before asking the server to revoke the session.
            if client.auth.currentSession != nil {
                message = copy("Sign-out couldn’t finish. Please try again.", "تعذّر إكمال تسجيل الخروج. حاول مرة أخرى.")
            }
        }
        synchronizeSession()
        if !signedIn { clearGoogleSession(); completedEmailCallback = nil }
    }

    /// The optional Drive backup shares Google's SDK session; only drop it when backup is not connected,
    /// so the next tap on "Continue with Google" shows the account chooser instead of a stale account.
    private func clearGoogleSession() {
        if !GoogleAccountManager.shared.isSignedIn { GIDSignIn.sharedInstance.signOut() }
    }

    @discardableResult
    func deleteAccount(reason: String = "", feedback: String = "") async -> Bool {
        guard let client = begin(.deletion) else { return false }
        defer { finishOperation() }
        do {
            guard let user = (try? await client.auth.user()) ?? client.auth.currentUser else {
                try? await client.auth.signOut(scope: .local)
                synchronizeSession()
                message = copy("Please sign in again, then delete your account.", "سجّل الدخول مرة أخرى، ثم احذف حسابك."); return false
            }
            var body: [String: String] = ["reason": reason, "feedback": String(feedback.prefix(1000))]
            if user.identities?.contains(where: { $0.provider == "apple" }) == true {
                body["appleAuthorizationCode"] = try await AppleDeletionAuthorization().authorize()
            }
            let response: DeletionResponse = try await client.functions.invoke("delete-account", options: .init(body: body))
            guard response.deleted else {
                message = copy("Account deletion wasn’t confirmed. Please try again.", "لم يُؤكَّد حذف الحساب. حاول مرة أخرى."); return false
            }
            await AccountLibrarySync.shared.eraseDeletedAccount(user.id)
            clearGoogleSession()
            // The server already removed the account; the logout call is only for the local session.
            try? await client.auth.signOut(scope: .local)
            synchronizeSession()
            completedEmailCallback = nil
            return true
        } catch {
            if Self.isAppleCancellation(error) { return false }
            if case let FunctionsError.httpError(code, data) = error {
                let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? ""
                switch (code, reason) {
                case (401, _):
                    try? await client.auth.signOut(scope: .local)
                    synchronizeSession()
                    message = copy("Your session had expired, so nothing was deleted. Sign in again, then delete your account.", "انتهت جلستك، ولم يُحذف شيء. سجّل الدخول مرة أخرى، ثم احذف حسابك.")
                case (_, "apple_authorization_required"), (_, "apple_revocation_failed"), (_, "apple_identity_unavailable"):
                    message = copy("Apple’s connection couldn’t be removed, so nothing was deleted. Try again with the same Apple ID. If this continues, contact support from Settings.", "تعذّر إلغاء الاتصال بحساب Apple، ولم يُحذف شيء. حاول مرة أخرى باستخدام حساب Apple نفسه. إذا استمرت المشكلة، تواصل مع الدعم من الإعدادات.")
                case (503, _):
                    message = copy("Account deletion is temporarily unavailable. Please try again shortly.", "حذف الحساب غير متاح مؤقتًا. حاول مرة أخرى بعد قليل.")
                default:
                    message = copy("Account deletion couldn’t finish. Please try again.", "تعذّر إكمال حذف الحساب. حاول مرة أخرى.")
                }
                return false
            }
            message = copy("Account deletion couldn’t finish. Check your connection and try again.", "تعذّر إكمال حذف الحساب. تحقق من الاتصال وحاول مرة أخرى.")
            return false
        }
    }

    private struct DeletionResponse: Decodable { let deleted: Bool }

    private static func isAppleCancellation(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == ASAuthorizationError.errorDomain && error.code == ASAuthorizationError.canceled.rawValue
    }

    /// Keep provider diagnostics out of the UI, including callback URLs carrying tokens or codes.
    private func authMessage(_ error: Error, emailFlow: Bool = false, fallback: String) -> String {
        if let error = error as? URLError,
           [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost].contains(error.code) {
            return copy("Check your connection and try again.", "تحقق من الاتصال وحاول مرة أخرى.")
        }
        guard case let AuthError.api(_, code, _, _) = error else { return fallback }
        switch code.rawValue {
        case "over_email_send_rate_limit", "over_request_rate_limit":
            return copy("Too many attempts for now. Wait a few minutes, then try again.", "محاولات كثيرة في الوقت الحالي. انتظر بضع دقائق ثم حاول مرة أخرى.")
        case "otp_expired":
            return copy("That code or link has expired. Send a new email and try again.", "انتهت صلاحية هذا الرمز أو الرابط. أرسل رسالة جديدة وحاول مرة أخرى.")
        case "email_address_invalid":
            return copy("Enter a valid email address.", "أدخل عنوان بريد إلكتروني صحيحًا.")
        case "signup_disabled", "email_provider_disabled", "otp_disabled":
            return emailFlow ? copy("Email sign-in isn’t available right now. Please continue with Apple or Google.", "تسجيل الدخول بالبريد الإلكتروني غير متاح حاليًا. تابع باستخدام Apple أو Google.") : fallback
        default:
            return fallback
        }
    }
}

struct CompanionAccountView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    @ObservedObject private var account: CompanionAccount
    @ObservedObject private var sync = AccountLibrarySync.shared
    @ObservedObject private var library = AyahLibrary.shared
    @AppStorage(DuaCollection.savedKey) private var savedDuasRaw = ""
    @AppStorage(GoalLog.key) private var goalLogRaw = ""
    @AppStorage(GoalPreferences.key) private var enabledGoalsRaw = ""
    @Query private var bookmarks: [Bookmark]
    @Query private var reflections: [JournalEntry]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var email = ""
    @State private var code = ""
    @State private var sent = false
    @State private var showDelete = false
    @State private var showSignIn = false

    @MainActor init(account: CompanionAccount? = nil) {
        _account = ObservedObject(wrappedValue: account ?? .shared)
    }

    private var summary: AccountLibrarySummary {
        AccountLibrarySummary(marks: Array(library.marks.values), savedDuas: savedDuasRaw,
                              situationIDs: bookmarks.map(\.situationID), reflectionTexts: reflections.map(\.text))
    }
    private var readingAyah: QuranAyah? { AccountLibrarySummary.readingAyah(for: library.lastReadKey) }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2)
    }
    private func number(_ value: Int) -> String { value.formatted(.number.locale(language.locale)) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                identity
                VStack(spacing: 12) {
                    continueReading
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        dailyGoals(on: context.date)
                    }
                }
                personalLibrary
                if account.signedIn { syncStatus }
                accountControls
                NavigationLink(value: AccountHubRoute.sources) {
                    BadgeRow(symbol: "hand.raised", title: copy("Sources & privacy", "المصادر والخصوصية"), artwork: .privacy)
                        .yqCard(cornerRadius: 20)
                }.buttonStyle(.yqPressSoft)
                    .accessibilityIdentifier("account-hub.sources")
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28).font(.yqBody)
        }
        .yqScreen()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(copy("Your space", "مساحتك")).navigationBarTitleDisplayMode(.inline)
        .onChange(of: email) { _, _ in sent = false; code = "" }
        .onChange(of: account.signedIn) { _, _ in sent = false; code = ""; showSignIn = false }
        .sheet(isPresented: $showDelete) { AccountDeletionSheet(account: account) }
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: 14) {
            CompanionIllustration(artwork: .privacy, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(account.signedIn ? (account.displayName ?? copy("Your Haneen", "حنين، مساحتك")) : copy("Make yourself at home", "أهلًا بك في مساحتك"))
                    .font(.yqTitle2).foregroundStyle(Color.yqInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("account.identity-name")
                if account.signedIn, let email = account.email {
                    Text(email).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        .textSelection(.enabled).environment(\.layoutDirection, .leftToRight)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("account.identity-email")
                } else {
                    Text(copy("A little reading. A moment of remembrance.", "قراءة يسيرة ولحظة ذكر."))
                        .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var continueReading: some View {
        NavigationLink {
            MushafView(language: language, initialKey: readingAyah?.key, showsTabBar: false)
        } label: {
            BadgeRow(symbol: "book.closed", title: readingAyah == nil ? copy("Open the Qur’an", "افتح القرآن") : copy("Continue reading", "تابع القراءة"),
                     subtitle: readingAyah?.reference(language) ?? copy("Begin wherever you feel ready.", "ابدأ من حيث تشاء."), artwork: .quran)
                .padding(.vertical, 6).yqCard(cornerRadius: 24)
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityIdentifier("account-hub.continue-reading")
    }

    private func dailyGoals(on date: Date) -> some View {
        let routine = AccountRoutineSummary(enabledRaw: enabledGoalsRaw, logRaw: goalLogRaw, on: date)
        let progressText = routine.enabled.isEmpty
            ? copy("Choose what fits your day", "اختر ما يناسب يومك")
            : copy("\(number(routine.completed)) of \(number(routine.enabled.count)) complete", "أنجزت \(number(routine.completed)) من \(number(routine.enabled.count))")
        return NavigationLink(value: AccountHubRoute.dailyGoals) {
            HStack(spacing: 16) {
                GoalRing(progress: routine.progress, size: 54, lineWidth: 5, reduceMotion: reduceMotion) {
                    Text(number(routine.completed)).font(.yqHeadline).foregroundStyle(Color.yqAccentDeep)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("Today’s goals", "أهداف اليوم")).font(.yqHeadline).foregroundStyle(Color.yqInk)
                    Text(progressText).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    if let next = routine.nextGoal {
                        Text(copy("Up next: \(next.title(language))", "التالي: \(next.title(language))"))
                            .font(.yqCaption).foregroundStyle(Color.yqAccentDeep)
                    } else if !routine.enabled.isEmpty {
                        Text(copy("Alhamdulillah. A little, every day.", "الحمد لله. قليل يدوم كل يوم."))
                            .font(.yqCaption).foregroundStyle(Color.yqAccentDeep)
                    }
                }.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Chevron()
            }
            .multilineTextAlignment(.leading).padding(18).frame(maxWidth: .infinity, alignment: .leading).yqCard(cornerRadius: 24)
        }
        .buttonStyle(.yqPressSoft)
        .accessibilityElement(children: .combine)
        .accessibilityHint(copy("Open your daily goals or customise your routine.", "افتح أهداف اليوم أو خصّص روتينك."))
        .accessibilityIdentifier("account-hub.goals")
    }

    private var personalLibrary: some View {
        let counts = summary
        return VStack(alignment: .leading, spacing: 12) {
            Text(copy("Your library", "محفوظاتك")).font(.yqHeadline).foregroundStyle(Color.yqInk)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink { AyahLibraryView(language: language) } label: {
                    libraryTile(title: copy("Qur’an library", "محفوظات القرآن"), count: counts.ayat,
                                detail: copy("Ayat, highlights & notes", "آيات وتظليل وملاحظات"), artwork: .quran)
                }.accessibilityIdentifier("account-hub.quran-library")
                NavigationLink(value: AccountHubRoute.saved(.duas)) {
                    libraryTile(title: copy("Saved du’as", "أدعية محفوظة"), count: counts.duas,
                                detail: copy("Words to keep close", "كلمات قريبة من قلبك"), artwork: .saved)
                }.accessibilityIdentifier("account-hub.saved-duas")
                NavigationLink(value: AccountHubRoute.saved(.moments)) {
                    libraryTile(title: copy("Saved moments", "مواقف محفوظة"), count: counts.moments,
                                detail: copy("Readings to return to", "قراءات تعود إليها"), artwork: .hopeful)
                }.accessibilityIdentifier("account-hub.saved-moments")
                NavigationLink(value: AccountHubRoute.saved(.reflections)) {
                    libraryTile(title: copy("Reflections", "تأملات"), count: counts.reflections,
                                detail: copy("A space for your words", "مساحة لكلماتك"), artwork: .journal)
                }.accessibilityIdentifier("account-hub.reflections")
            }
            .buttonStyle(.yqPressSoft)
            if counts.notes > 0 {
                NavigationLink {
                    AyahListView(title: copy("Qur’an notes", "ملاحظات القرآن"), keys: library.notedKeys, language: language)
                } label: {
                    HStack {
                        Text(copy("Open your Qur’an notes", "افتح ملاحظاتك على القرآن")).font(.yqSubheadBold)
                        Spacer(minLength: 8)
                        Text(number(counts.notes)).font(.yqSubhead)
                        Chevron()
                    }.foregroundStyle(Color.yqAccentDeep).padding(.vertical, 12).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            Text(copy("Your saved library and reading place sync with your account. Daily goals, dhikr counts and prayer settings stay on this iPhone.",
                      "تتزامن محفوظاتك وموضع قراءتك مع حسابك. وتبقى أهداف اليوم وعدّادات الذكر وإعدادات الصلاة على هذا الهاتف."))
                .font(.yqCaption).foregroundStyle(Color.yqSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func libraryTile(title: String, count: Int, detail: String, artwork: CompanionArtwork) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CompanionIllustration(artwork: artwork, size: 42)
                Spacer(minLength: 4)
                if count > 0 {
                    Text(number(count)).font(.yqTitle2).foregroundStyle(Color.yqAccentDeep)
                } else {
                    Chevron()
                }
            }
            Text(title).font(.yqSubheadBold).foregroundStyle(Color.yqInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading).padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .yqCard(cornerRadius: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 0 ? "\(title), \(number(count)). \(detail)" : "\(title). \(detail)")
    }

    private var syncStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CompanionIllustration(artwork: .backup, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("Account backup", "نسخة حسابك الاحتياطية")).font(.yqHeadline).foregroundStyle(Color.yqInk)
                    Text(sync.isSyncing ? copy("Syncing your library…", "جارٍ مزامنة محفوظاتك…") :
                         sync.hasPendingChanges ? copy("Changes waiting to sync", "تغييرات في انتظار المزامنة") :
                         sync.lastSyncedAt == nil ? copy("Ready to sync", "جاهز للمزامنة") : copy("Library synced", "تمت مزامنة المحفوظات"))
                        .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                }
                Spacer(minLength: 0)
                if sync.isSyncing { ProgressView() }
            }
            if let message = sync.statusMessage {
                Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
            }
            if sync.hasPendingChanges {
                Text(copy("Your changes are saved on this iPhone. Keep Haneen open with a connection to finish backing them up.",
                          "تغييراتك محفوظة على هذا الهاتف. أبقِ حنين مفتوحًا مع اتصال بالإنترنت لإكمال نسخها احتياطيًا."))
                    .font(.yqCaption).foregroundStyle(Color.yqSecondary)
            }
            if let date = sync.lastSyncedAt {
                Text(copy("Last synced: \(date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(language.locale)))",
                          "آخر مزامنة: \(date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(language.locale)))"))
                    .font(.yqCaption).foregroundStyle(Color.yqSecondary)
            }
            Button { Task { await sync.syncNow() } } label: {
                Text(copy("Sync now", "مزامنة الآن")).font(.yqSubheadBold).frame(minHeight: 44)
            }
            .buttonStyle(.plain).foregroundStyle(Color.yqAccentDeep)
            .disabled(sync.isSyncing || sync.isPreparing || account.busy)
            .accessibilityIdentifier("account.sync-now")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(18).frame(maxWidth: .infinity, alignment: .leading).yqCard(cornerRadius: 20)
        .accessibilityIdentifier("account.sync-status")
    }

    private var accountControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy("Account", "الحساب")).font(.yqHeadline).foregroundStyle(Color.yqInk)
                .accessibilityAddTraits(.isHeader)
            if account.signedIn {
                connectedContent
            } else {
                DisclosureGroup(isExpanded: $showSignIn) {
                    signInContent.padding(.top, 16)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy("Sign in or create an account", "سجّل الدخول أو أنشئ حسابًا")).font(.yqSubheadBold)
                        Text(copy("Keep your saved library together across your devices.", "احتفظ بمحفوظاتك معًا عبر أجهزتك."))
                            .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    }.fixedSize(horizontal: false, vertical: true)
                }
                .padding(18).yqCard(cornerRadius: 20).disabled(account.busy)
                .accessibilityIdentifier("account-hub.signin")
            }
            if account.busy { ProgressView().frame(minHeight: 32).frame(maxWidth: .infinity) }
            if let message = account.message {
                Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var connectedContent: some View {
        RowGroup {
            Button { Task { await account.signOut() } } label: {
                BadgeRow(symbol: "rectangle.portrait.and.arrow.right", title: copy("Sign out", "تسجيل الخروج"),
                         subtitle: copy("Sign in to this account again to reopen your library.", "سجّل الدخول إلى هذا الحساب مجددًا لفتح محفوظاتك."), artwork: .signout)
            }.buttonStyle(.yqPressSoft).accessibilityIdentifier("account.sign-out")
            RowDivider()
            Button { account.message = nil; showDelete = true } label: {
                HStack(spacing: 14) {
                    CompanionIllustration(artwork: .deleteAccount, size: 44)
                    Text(copy("Delete account", "حذف الحساب")).font(.yqSubheadBold).foregroundStyle(.red)
                    Spacer(minLength: 0)
                    Chevron()
                }.padding(14).frame(minHeight: 58).contentShape(Rectangle())
            }.buttonStyle(.yqPressSoft)
        }.disabled(account.busy)
    }

    private var signInContent: some View {
        VStack(spacing: 16) {
            Text(copy("New or returning, use the same sign-in options.", "سواء كنت جديدًا أو عائدًا، استخدم خيارات تسجيل الدخول نفسها."))
                .font(.yqSubhead).foregroundStyle(Color.yqSecondary).frame(maxWidth: .infinity, alignment: .leading)
            SignInWithAppleButton(.continue, onRequest: account.prepareApple) { result in
                Task { await account.completeApple(result) }
            }.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52).clipShape(RoundedRectangle(cornerRadius: 14))
            Button { Task { await account.google() } } label: {
                HStack(spacing: 12) {
                    Image("GoogleSignInLogo").resizable().frame(width: 20, height: 20)
                    Text(copy("Continue with Google", "المتابعة باستخدام Google")).font(.yqHeadline)
                }.frame(maxWidth: .infinity).frame(height: 52).yqCard(cornerRadius: 14)
            }.buttonStyle(.plain)
            HStack { Rectangle().frame(height: 1); Text(copy("or email", "أو بالبريد الإلكتروني")).font(.yqCaption).fixedSize(); Rectangle().frame(height: 1) }
                .foregroundStyle(Color.yqSecondary).padding(.vertical, 8)
            TextField(copy("Email address", "البريد الإلكتروني"), text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(16).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14))
            if sent {
                TextField(copy("Email code", "رمز التحقق المرسل إلى بريدك"), text: $code).textContentType(.oneTimeCode).keyboardType(.numberPad)
                    .padding(16).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14))
                Button(copy("Verify & continue", "التحقق والمتابعة")) { Task { await account.verify(email: email, code: code) } }
                    .buttonStyle(.borderedProminent).disabled(CompanionAccount.normalizedEmailCode(code) == nil)
            }
            Button { Task { if await account.sendCode(email: email) { sent = true; code = "" } } } label: {
                Text(sent ? copy("Send another email", "إرسال الرسالة مجددًا") : copy("Continue with email", "المتابعة بالبريد الإلكتروني")).font(.yqHeadline)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.yqAccentDeep, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(Color.yqOnAccent)
            }.buttonStyle(.plain).disabled(!CompanionAccount.validEmail(email)).opacity(CompanionAccount.validEmail(email) ? 1 : 0.45)
            Text(copy("Sign in to back up your saved ayat, du’as, notes and reflections with your account.", "سجّل الدخول لنسخ آياتك وأدعيتك وملاحظاتك وتأملاتك المحفوظة احتياطيًا في حسابك."))
                .font(.yqCaption).foregroundStyle(Color.yqSecondary).multilineTextAlignment(.center)
        }.disabled(!account.configured)
    }
}

private struct AccountDeletionSheet: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    @ObservedObject var account: CompanionAccount
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var feedback = ""
    @State private var confirm = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(copy("Your account and its cloud library will be permanently deleted, including saved ayat, du’as, notes and reflections. This account’s saved library will also be removed from this iPhone. This cannot be undone.", "سيُحذف حسابك ومحفوظاته السحابية نهائيًا، بما فيها الآيات والأدعية والملاحظات والتأملات المحفوظة. وستُزال أيضًا محفوظات هذا الحساب من هذا الهاتف. لا يمكن التراجع عن الحذف."))
                        .font(.yqSubhead)
                }
                Section {
                    Picker(copy("Reason", "السبب"), selection: $reason) {
                        Text(copy("Prefer not to say", "أفضل عدم الإجابة")).tag("")
                        Text(copy("I don’t use it enough", "لا أستخدم التطبيق كثيرًا")).tag("not_using")
                        Text(copy("Something isn’t working", "أواجه مشكلة في التطبيق")).tag("technical")
                        Text(copy("Privacy concerns", "لدي مخاوف بشأن الخصوصية")).tag("privacy")
                        Text(copy("I’m using another app", "أستخدم تطبيقًا آخر")).tag("another_app")
                        Text(copy("Something else", "سبب آخر")).tag("other")
                    }
                    TextField(copy("What could we improve?", "ما الذي يمكننا تحسينه؟"), text: $feedback, axis: .vertical)
                        .lineLimit(4...7)
                        .onChange(of: feedback) { _, value in if value.count > 1000 { feedback = String(value.prefix(1000)) } }
                } header: { Text(copy("Optional feedback", "ملاحظات اختيارية")) }
                  footer: { Text(copy("Feedback is sent with your authenticated deletion request, then stored without your account identifier. Please leave out personal details. You can delete without answering.", "تُرسل الملاحظات مع طلب الحذف باستخدام جلسة تسجيل دخولك، ثم تُحفظ دون معرّف حسابك. يرجى عدم ذكر معلومات شخصية. يمكنك حذف الحساب دون الإجابة.")) }
                Section {
                    Button(copy("Delete account", "حذف الحساب"), role: .destructive) { confirm = true }
                        .disabled(account.busy)
                    if account.busy { ProgressView(copy("Deleting account…", "جارٍ حذف الحساب…")) }
                    if let message = account.message { Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary) }
                }
            }.font(.yqBody).navigationTitle(copy("Delete account", "حذف الحساب")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(copy("Cancel", "إلغاء")) { dismiss() }.disabled(account.busy) } }
                .confirmationDialog(copy("Permanently delete your account?", "هل تريد حذف حسابك نهائيًا؟"), isPresented: $confirm, titleVisibility: .visible) {
                    Button(copy("Delete account", "حذف الحساب"), role: .destructive) { Task {
                        if await account.deleteAccount(reason: reason, feedback: feedback) { dismiss() }
                    } }
                }
        }
        .interactiveDismissDisabled(account.busy)
    }
}

/// Obtain a fresh, single-use code only after the user confirms account deletion.
/// The server verifies its Apple subject against the signed-in Supabase identity.
@MainActor
private final class AppleDeletionAuthorization: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<String, Error>?
    private var controller: ASAuthorizationController?
    private var window: UIWindow?

    func authorize() async throws -> String {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?.windows.first(where: \.isKeyWindow) else {
            throw CocoaError(.userCancelled)
        }
        self.window = window
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = []
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let data = credential.authorizationCode,
              let code = String(data: data, encoding: .utf8), !code.isEmpty else {
            finish(.failure(CocoaError(.coderInvalidValue)))
            return
        }
        finish(.success(code))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<String, Error>) {
        let pending = continuation
        continuation = nil
        controller = nil
        window = nil
        pending?.resume(with: result)
    }
}
