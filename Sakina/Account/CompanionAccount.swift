import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit
import Security

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
        guard let client else { message = "Sign-in is temporarily unavailable. Please try again shortly."; return false }
        guard Self.validEmail(email) else { message = "Enter a valid email address."; return false }
        busy = true; message = nil; defer { busy = false }
        do {
            try await client.auth.signInWithOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines), redirectTo: URL(string: "yaqeen://auth-callback"), shouldCreateUser: creating)
            message = "Check your email for your sign-in link."
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
        do { _ = try await client.auth.signInWithOAuth(provider: .google, redirectTo: URL(string: "yaqeen://auth-callback")) }
        catch { if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue { message = error.localizedDescription } }
    }

    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { message = "Please try signing in again."; return }
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
                message = "Apple couldn’t complete sign-in. Please try again."; return
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

    func deleteAccount() async {
        guard let client else { return }
        busy = true; defer { busy = false }
        do {
            try await client.functions.invoke("delete-account")
            try await client.auth.signOut(scope: .local)
        } catch { message = "Account deletion couldn’t finish. \(error.localizedDescription)" }
    }
}

struct CompanionAccountView: View {
    @ObservedObject private var account = CompanionAccount.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var creating = true
    @State private var email = ""
    @State private var code = ""
    @State private var sent = false
    @State private var confirmDelete = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CompanionIllustration(artwork: .privacy, size: 110).frame(maxWidth: .infinity)
                Text(account.signedIn ? "Your Haneen account" : creating ? "Make yourself at home." : "Welcome back.")
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                Text("Reading, prayer times and your local library are always available without an account.").font(.yqBody).foregroundStyle(Color.yqSecondary)
                if account.signedIn {
                    Text(account.email ?? "Signed in").font(.yqHeadline)
                    Text("Your account is connected. Notes and bookmarks stay on this iPhone; account sign-in does not upload them.").font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    Button("Sign out") { Task { await account.signOut() } }.buttonStyle(.bordered)
                    Button("Delete account", role: .destructive) { confirmDelete = true }
                } else {
                    if !account.configured {
                        Text("Accounts aren’t available in this build yet. Your local library is ready to use.")
                            .font(.yqSubhead).padding(20).frame(maxWidth: .infinity, alignment: .leading).yqCard()
                    }
                    Group {
                    Picker("Account", selection: $creating) { Text("Sign up").tag(true); Text("Sign in").tag(false) }.pickerStyle(.segmented)
                    SignInWithAppleButton(creating ? .signUp : .signIn, onRequest: account.prepareApple) { result in
                        Task { await account.completeApple(result) }
                    }.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black).frame(height: 52).clipShape(RoundedRectangle(cornerRadius: 14))
                    Button { Task { await account.google() } } label: {
                        Text("Continue with Google").font(.yqHeadline).frame(maxWidth: .infinity).padding(17).yqCard(cornerRadius: 14)
                    }.buttonStyle(.plain)
                    Text("Or use your email").font(.yqCaption).foregroundStyle(Color.yqSecondary)
                    TextField("Email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().padding(16).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14))
                    if sent {
                        TextField("Email code", text: $code).textContentType(.oneTimeCode).keyboardType(.numberPad)
                            .padding(16).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 14))
                        Button("Verify & continue") { Task { await account.verify(email: email, code: code) } }.buttonStyle(.borderedProminent).disabled(code.count < 6)
                    }
                    Button(sent ? "Send another email" : "Email me a sign-in link") { Task { sent = await account.sendCode(email: email, creating: creating) } }
                        .buttonStyle(.bordered).disabled(!email.contains("@"))
                    }.disabled(!account.configured)
                }
                if account.busy { ProgressView() }
                if let message = account.message { Text(message).font(.yqSubhead).foregroundStyle(Color.yqSecondary) }
                NavigationLink("Sources & privacy") { AboutView() }.font(.yqCaption)
            }.padding(24).disabled(account.busy)
        }.yqScreen().navigationTitle("Account").navigationBarTitleDisplayMode(.inline)
            .onChange(of: email) { _, _ in sent = false; code = "" }
            .onChange(of: creating) { _, _ in sent = false; code = "" }
            .confirmationDialog("Delete your Haneen account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete account", role: .destructive) { Task { await account.deleteAccount() } }
            } message: { Text("Your sign-in account will be permanently deleted. Local notes and bookmarks stay on this iPhone.") }
    }
}
