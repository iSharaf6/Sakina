import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit
import Security
import GoogleSignIn

@MainActor
final class CompanionAccount: ObservableObject {
    static let shared = CompanionAccount()
    @Published private(set) var email: String?
    @Published private(set) var signedIn = false
    @Published var busy = false
    @Published var message: String?
    private(set) var client: SupabaseClient?
    private var nonce: String?
    private var stateTask: Task<Void, Never>?
    var configured: Bool { client != nil }
    private var copy: AppCopy {
        AppCopy(language: AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english)
    }

    private init() {
        func value(_ name: String) -> String? {
            guard let value = Bundle.main.object(forInfoDictionaryKey: name) as? String,
                  !value.isEmpty, !value.contains("$(") else { return nil }
            return value
        }
        if let urlString = value("YaqeenAuthSupabaseURL"), let key = value("YaqeenAuthSupabaseKey"),
           let url = URL(string: urlString), url.scheme == "https" {
            client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        }
        if let client {
            stateTask = Task { [weak self] in
                for await (_, session) in client.auth.authStateChanges {
                    self?.signedIn = session != nil
                    self?.email = session?.user.email
                }
            }
        }
    }

    nonisolated static func validEmail(_ value: String) -> Bool {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    func sendCode(email: String, creating: Bool) async -> Bool {
        guard let client else { message = copy("Sign-in is temporarily unavailable. Please try again shortly.", "تسجيل الدخول غير متاح مؤقتًا. حاول مرة أخرى بعد قليل."); return false }
        guard Self.validEmail(email) else { message = copy("Enter a valid email address.", "أدخل عنوان بريد إلكتروني صحيحًا."); return false }
        busy = true; message = nil; defer { busy = false }
        do {
            try await client.auth.signInWithOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), redirectTo: URL(string: "yaqeen://auth-callback"), shouldCreateUser: creating)
            message = copy("Check your email for your sign-in link.", "افتح بريدك الإلكتروني للاطلاع على رابط تسجيل الدخول.")
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func verify(email: String, code: String) async {
        guard let client else { return }
        busy = true; message = nil; defer { busy = false }
        do { _ = try await client.auth.verifyOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), token: code.trimmingCharacters(in: .whitespacesAndNewlines), type: .email) }
        catch { message = error.localizedDescription }
    }

    func google() async {
        guard let client else { return }
        busy = true; message = nil; defer { busy = false }
        do {
            guard let presenter = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
            var top = presenter
            while let presented = top.presentedViewController { top = presented }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: top)
            guard let token = result.user.idToken?.tokenString else {
                message = copy("Google couldn’t complete sign-in. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Google. حاول مرة أخرى."); return
            }
            _ = try await client.auth.signInWithIdToken(credentials: .init(provider: .google, idToken: token, accessToken: result.user.accessToken.tokenString))
        } catch {
            if (error as NSError).code != GIDSignInError.canceled.rawValue { message = copy("Google sign-in couldn’t finish. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Google. حاول مرة أخرى.") }
        }
    }

    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { message = copy("Please try signing in again.", "حاول تسجيل الدخول مرة أخرى."); return }
        let raw = bytes.map { String(format: "%02x", $0) }.joined()
        nonce = raw
        request.requestedScopes = [.email, .fullName]
        request.nonce = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func completeApple(_ result: Result<ASAuthorization, Error>) async {
        guard let client else { return }
        busy = true; message = nil; defer { busy = false; nonce = nil }
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken, let token = String(data: data, encoding: .utf8), let nonce else {
                message = copy("Apple couldn’t complete sign-in. Please try again.", "تعذّر إكمال تسجيل الدخول عبر Apple. حاول مرة أخرى."); return
            }
            _ = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: token, nonce: nonce))
        } catch { if (error as NSError).code != ASAuthorizationError.canceled.rawValue { message = error.localizedDescription } }
    }

    func handle(_ url: URL) async {
        guard url.scheme == "yaqeen", url.host == "auth-callback", let client else { return }
        do { _ = try await client.auth.session(from: url) } catch { message = error.localizedDescription }
    }

    func signOut() async {
        do { try await client?.auth.signOut(scope: .local) } catch { message = error.localizedDescription }
    }

    func deleteAccount(reason: String = "", feedback: String = "") async {
        guard let client else { return }
        busy = true; message = nil; defer { busy = false }
        do {
            let user = try await client.auth.user()
            var body: [String: String] = ["reason": reason, "feedback": String(feedback.prefix(1000))]
            if user.identities?.contains(where: { $0.provider == "apple" }) == true {
                let authorization = AppleDeletionAuthorization()
                body["appleAuthorizationCode"] = try await authorization.authorize()
            }
            try await client.functions.invoke("delete-account", options: .init(body: body))
            try await client.auth.signOut(scope: .local)
        } catch {
            if let error = error as? ASAuthorizationError, error.code == .canceled { return }
            message = copy("Account deletion couldn’t finish. Please try again and use the same Apple account if prompted.", "تعذّر إكمال حذف الحساب. حاول مرة أخرى، واستخدم حساب Apple نفسه إذا طُلب منك ذلك.")
        }
    }
}

struct CompanionAccountView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    @ObservedObject private var account = CompanionAccount.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var creating = true
    @State private var email = ""
    @State private var code = ""
    @State private var sent = false
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    CompanionIllustration(artwork: .privacy, size: 76)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(account.signedIn ? copy("Your account", "حسابك") : copy("Welcome to Haneen", "مرحبًا بك في حنين")).font(.yqTitle2)
                        Text(account.signedIn ? copy("A little space of your own.", "مساحتك الخاصة في حنين.") : copy("Come back to what matters.", "عُد إلى ما يهمّك."))
                            .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    }
                    Spacer(minLength: 0)
                }.padding(.top, 12)
                if account.signedIn { connectedContent } else { signInContent }
                if account.busy { ProgressView().frame(minHeight: 32) }
                if let message = account.message {
                    Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                NavigationLink { AboutView() } label: {
                    HStack {
                        CompanionIllustration(artwork: .help, size: 32)
                        Text(copy("Sources & privacy", "المصادر والخصوصية")).font(.yqSubheadBold)
                        Spacer()
                        Image(systemName: "chevron.forward").font(.caption)
                    }.padding(16).yqCard(cornerRadius: 20)
                }.buttonStyle(.plain)
            }.padding(20).font(.yqBody).disabled(account.busy)
        }
        .background(Color.yqSurface.ignoresSafeArea())
        .navigationTitle(copy("Account", "الحساب")).navigationBarTitleDisplayMode(.inline)
        .onChange(of: email) { _, _ in sent = false; code = "" }
        .onChange(of: creating) { _, _ in sent = false; code = "" }
        .sheet(isPresented: $showDelete) { AccountDeletionSheet() }
    }

    private var connectedContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text(copy("SIGNED IN", "تم تسجيل الدخول")).font(.yqCaption).foregroundStyle(Color.yqAccentDeep)
                Text(account.email ?? copy("Connected", "متصل")).font(.yqHeadline).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                HStack(alignment: .top, spacing: 12) {
                    CompanionIllustration(artwork: .saved, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy("Your library stays with you", "محفوظاتك تبقى معك")).font(.yqSubheadBold)
                        Text(copy("Notes and bookmarks are stored on this iPhone. Signing out keeps them here.", "تبقى ملاحظاتك وعلاماتك المرجعية محفوظة على هذا الهاتف، حتى بعد تسجيل الخروج."))
                            .font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    }
                }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading).yqCard(cornerRadius: 24)
            Button { Task { await account.signOut() } } label: {
                HStack(spacing: 12) {
                    CompanionIllustration(artwork: .signout, size: 36)
                    Text(copy("Sign out", "تسجيل الخروج")).font(.yqHeadline)
                    Spacer()
                    Image(systemName: "chevron.forward").font(.caption)
                }.padding(16).yqCard(cornerRadius: 20)
            }.buttonStyle(.plain)
            Button { showDelete = true } label: {
                Text(copy("Delete account", "حذف الحساب")).font(.yqSubhead).foregroundStyle(.red).frame(minHeight: 44)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var signInContent: some View {
        VStack(spacing: 16) {
            Picker(copy("Account", "الحساب"), selection: $creating) { Text(copy("Sign up", "إنشاء حساب")).tag(true); Text(copy("Sign in", "تسجيل الدخول")).tag(false) }.pickerStyle(.segmented)
            SignInWithAppleButton(creating ? .signUp : .signIn, onRequest: account.prepareApple) { result in
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
                    .buttonStyle(.borderedProminent).disabled(code.count < 6)
            }
            Button { Task { sent = await account.sendCode(email: email, creating: creating) } } label: {
                Text(sent ? copy("Send another email", "إرسال الرسالة مجددًا") : copy("Continue with email", "المتابعة بالبريد الإلكتروني")).font(.yqHeadline)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.yqAccentDeep, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(Color.yqOnAccent)
            }.buttonStyle(.plain).disabled(!CompanionAccount.validEmail(email)).opacity(CompanionAccount.validEmail(email) ? 1 : 0.45)
            Text(copy("Your reading and local library are also available without an account.", "يمكنك أيضًا القراءة والرجوع إلى محفوظاتك على هذا الهاتف دون حساب."))
                .font(.yqCaption).foregroundStyle(Color.yqSecondary).multilineTextAlignment(.center)
        }.disabled(!account.configured)
    }
}

private struct AccountDeletionSheet: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    @ObservedObject private var account = CompanionAccount.shared
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var feedback = ""
    @State private var confirm = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(copy("Your sign-in account will be permanently deleted. Your local notes and bookmarks stay on this iPhone.", "سيُحذف حسابك نهائيًا. ستبقى ملاحظاتك وعلاماتك المرجعية المحفوظة محليًا على هذا الهاتف."))
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
                  footer: { Text(copy("If you leave feedback, it is sent to Haneen without your account identifier. Please leave out personal details. You can delete without answering.", "إذا أرسلت ملاحظات، فستصل إلى حنين دون معرّف حسابك. يرجى عدم ذكر معلومات شخصية. يمكنك حذف الحساب دون الإجابة.")) }
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
                        await account.deleteAccount(reason: reason, feedback: feedback)
                        if !account.signedIn { dismiss() }
                    } }
                }
        }
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
