import SwiftUI
import AuthenticationServices

/// One welcome screen. The preview uses the same views and Quran renderer as the app.
struct CompanionOnboarding: View {
    static let completedKey = "companion.onboarding.complete"
    @ObservedObject private var account = CompanionAccount.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var page = 0
    @State private var showEmail = false
    @State private var showPrivacy = false
    @State private var paused = false
    var allowsDismiss = false
    let onFinish: () -> Void

    private let captions = ["Your daily companion.", "Keep the Qur’an close.", "A moment to remember."]
    private let details = ["Prayer, Qur’an and du’a. Together.", "Beautiful pages. A clearer meaning.", "Make space for a little dhikr."]
    private var ink: Color { colorScheme == .dark ? Color(red: 0.93, green: 0.94, blue: 0.86) : Color(red: 0.12, green: 0.23, blue: 0.17) }
    private var paper: Color { colorScheme == .dark ? Color(red: 0.07, green: 0.12, blue: 0.10) : Color(red: 0.90, green: 0.93, blue: 0.86) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        YaqeenBrandIcon(size: 34)
                        Text("haneen").font(.system(size: 26, weight: .semibold, design: .rounded)).tracking(-0.8)
                        Spacer()
                        if account.signedIn || allowsDismiss {
                            Button("Done") { if allowsDismiss { onFinish() } else { finish() } }.font(.subheadline.weight(.semibold))
                        } else {
                            Button { paused.toggle() } label: {
                                Image(systemName: paused ? "play.fill" : "pause.fill").font(.system(size: 12, weight: .bold))
                                    .frame(width: 40, height: 40).background(ink.opacity(0.07), in: Circle())
                            }.accessibilityLabel(paused ? "Play app preview" : "Pause app preview")
                        }
                    }.padding(.horizontal, 26).padding(.top, 8)

                    WelcomeAppPreview(page: page, reduceMotion: reduceMotion || paused)
                        .frame(height: typeSize.isAccessibilitySize ? 220 : max(225, geometry.size.height - 370))
                        .clipped()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("App preview: \(details[page])")

                    VStack(spacing: 8) {
                        Text(captions[page]).font(.system(size: 30, weight: .semibold, design: .serif))
                            .minimumScaleFactor(0.8).lineLimit(2)
                        Text(details[page]).font(.subheadline).foregroundStyle(ink.opacity(0.72))
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) { page = index } } label: {
                                    Capsule().fill(ink.opacity(page == index ? 0.8 : 0.20)).frame(width: page == index ? 20 : 6, height: 6)
                                        .frame(height: 28)
                                }.accessibilityLabel("Preview \(index + 1): \(captions[index])")
                                    .accessibilityAddTraits(page == index ? .isSelected : [])
                            }
                        }
                    }.multilineTextAlignment(.center).padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        if account.signedIn {
                            Button("Continue to Haneen", action: finish).font(.headline)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .foregroundStyle(paper).background(ink, in: Capsule())
                        } else {
                            SignInWithAppleButton(.continue, onRequest: account.prepareApple) { result in
                                Task { await account.completeApple(result) }
                            }.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 52).clipShape(Capsule())
                                .accessibilityIdentifier("welcome.apple")
                            Button { Task { await account.google() } } label: {
                                HStack(spacing: 12) {
                                    Image("GoogleSignInLogo").resizable().frame(width: 20, height: 20)
                                    Text("Continue with Google").font(.system(size: 17, weight: .medium))
                                }.frame(maxWidth: .infinity).frame(height: 52)
                                    .foregroundStyle(Color(white: 0.24)).background(.white, in: Capsule())
                            }.accessibilityIdentifier("welcome.google")
                            Button { account.message = nil; showEmail = true } label: {
                                Label("Continue with email", systemImage: "envelope").font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity).frame(height: 52)
                                    .background(ink.opacity(0.07), in: Capsule())
                                    .overlay(Capsule().strokeBorder(ink.opacity(0.16), lineWidth: 1))
                            }.accessibilityIdentifier("welcome.email")
                        }
                        if account.busy { ProgressView().tint(ink).accessibilityLabel("Signing in") }
                        if let message = account.message, !showEmail {
                            Text(message).font(.footnote).multilineTextAlignment(.center).accessibilityAddTraits(.updatesFrequently)
                        }
                        HStack(spacing: 18) {
                            Link("Privacy", destination: URL(string: "https://isharaf6.github.io/Sakina/privacy.html")!)
                            Button("Sources") { showPrivacy = true }
                        }.font(.caption).foregroundStyle(ink.opacity(0.65)).padding(.top, 3)
                    }.buttonStyle(.plain).disabled(account.busy).padding(.horizontal, 26).padding(.bottom, 16)
                }.frame(minHeight: geometry.size.height)
            }.background(paper.ignoresSafeArea()).foregroundStyle(ink)
        }
        .sheet(isPresented: $showEmail) { WelcomeEmailView().presentationDragIndicator(.visible) }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { AboutView().toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showPrivacy = false } } } }
        }
        .task { if account.signedIn && !allowsDismiss { finish() } }
        .onChange(of: account.signedIn) { _, signedIn in if signedIn { finish() } }
        .task(id: "\(paused)-\(reduceMotion)-\(scenePhase)-\(showEmail)-\(showPrivacy)") {
            guard !paused, !reduceMotion, scenePhase == .active, !showEmail, !showPrivacy else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                withAnimation(.easeInOut(duration: 0.65)) { page = (page + 1) % 3 }
            }
        }
    }
    private func finish() {
        guard account.signedIn else { return }
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        onFinish()
    }
}

private struct WelcomeAppPreview: View {
    let page: Int
    let reduceMotion: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var floating = false
    var body: some View {
        GeometryReader { geometry in
            let scale = min((geometry.size.height - 20) / 720, (geometry.size.width - 96) / 360)
            ZStack(alignment: .bottom) {
                Ellipse().fill(Color.yqAccentDeep.opacity(0.09)).frame(width: geometry.size.width * 0.86, height: geometry.size.height * 0.68)
                    .blur(radius: 24)
                phone
                    .frame(width: 360, height: 720)
                    .background(Color.yqCanvas)
                    .clipShape(RoundedRectangle(cornerRadius: 42))
                    .overlay(RoundedRectangle(cornerRadius: 42).strokeBorder(Color(white: 0.18), lineWidth: 7))
                    .overlay(alignment: .top) { Capsule().fill(.black).frame(width: 100, height: 24).padding(.top, 13) }
                    .shadow(color: .black.opacity(0.22), radius: 25, x: 8, y: 18)
                    .rotationEffect(.degrees(reduceMotion ? 0 : page == 1 ? 3 : -3))
                    .scaleEffect(scale)
                    .frame(width: 360 * scale, height: 720 * scale)
                    .padding(.bottom, 14)
                CompanionIllustration(artwork: page == 2 ? .morning : .breathe, size: min(112, geometry.size.width * 0.27))
                    .rotationEffect(.degrees(reduceMotion ? 0 : floating ? 3 : -2), anchor: .bottom)
                    .offset(x: geometry.size.width * 0.28, y: -5)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { floating = true }
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floating)
        }.allowsHitTesting(false)
    }
    private var phone: some View {
        VStack(spacing: 0) {
            HStack { Text("9:41"); Spacer(); Image(systemName: "wifi"); Image(systemName: "battery.100percent") }
                .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 25).frame(height: 48)
            ZStack {
                if page == 0 {
                    HomeView(path: .constant(NavigationPath()), openSearch: { _ in }).transition(.opacity)
                } else if page == 1 {
                    VStack(spacing: 6) {
                        HStack { Text("Al-Fatihah").font(.headline); Image(systemName: "chevron.down"); Spacer(); Text("Qur’an").font(.subheadline) }.padding(.horizontal, 20).frame(height: 40)
                        PrintedMushafPage(page: 1, language: .english, onTap: { _ in }, onPageTap: {})
                    }.background(MushafPaper.background).transition(.opacity)
                } else {
                    NavigationStack { DhikrListView(language: .english) }.transition(.opacity)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            HStack(spacing: 38) {
                ForEach([CompanionArtwork.morning, .quran, .sunnah, .saved], id: \.self) { artwork in
                    CompanionIllustration(artwork: artwork, size: 30)
                }
            }.frame(height: 44).frame(maxWidth: .infinity).background(Color.yqSurface)
            Capsule().fill(Color.primary).frame(width: 100, height: 4).padding(.vertical, 8)
        }.environment(\.dynamicTypeSize, .medium)
    }
}

private struct WelcomeEmailView: View {
    @ObservedObject private var account = CompanionAccount.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var code = ""
    @State private var sent = false
    @FocusState private var focused: Bool
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CompanionIllustration(artwork: .privacy, size: 76)
                    Text(sent ? "Check your inbox." : "Your email. You’re in.")
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                    Text(sent ? "Open the sign-in email sent to \(email), then tap its link on this iPhone." : "New here or returning? Use your email to sign in. No password to remember.")
                        .font(.body).foregroundStyle(Color.yqSecondary)
                    if sent {
                        Text("Have a code instead? Enter it below.").font(.footnote).foregroundStyle(Color.yqSecondary)
                        TextField("Sign-in code", text: $code).textContentType(.oneTimeCode).keyboardType(.numberPad)
                            .focused($focused).padding(18).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityIdentifier("auth.code")
                        Button("Sign in") { Task { await account.verify(email: email, code: code) } }
                            .buttonStyle(WelcomePrimaryButton()).disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
                        Button("Use another email") { sent = false; code = ""; account.message = nil; focused = true }
                        Button("Send another email") { send() }
                    } else {
                        TextField("Email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().focused($focused)
                            .submitLabel(.go).onSubmit { if validEmail { send() } }
                            .padding(18).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityIdentifier("auth.email")
                        Button("Continue") { send() }.buttonStyle(WelcomePrimaryButton()).disabled(!validEmail)
                    }
                    if account.busy { ProgressView() }
                    if let message = account.message { Text(message).font(.footnote).foregroundStyle(Color.yqSecondary) }
                }.padding(26).disabled(account.busy)
            }.background(Color.yqCanvas).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.tint(.yqAccentDeep).onChange(of: account.signedIn) { _, signedIn in if signedIn { dismiss() } }
    }
    private var validEmail: Bool { CompanionAccount.validEmail(email) }
    private func send() { Task { if await account.sendCode(email: email, creating: true) { sent = true; focused = true } } }
}

private struct WelcomePrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(18)
            .foregroundStyle(Color.yqOnAccent).background(Color.yqAccent, in: Capsule()).opacity(configuration.isPressed ? 0.7 : 1)
    }
}

enum SettingsReset {
    /// Explicit allowlist protects saved ayat, notes, account credentials and progress.
    static let keys = [SettingsKeys.reciter, SettingsKeys.arabicScale, SettingsKeys.appLanguage,
                       SettingsKeys.translationVisible, SettingsKeys.transliterationVisible,
                       SettingsKeys.prayerCalculationMethod, SettingsKeys.prayerAsrMethod, SettingsKeys.prayerHighLatitude,
                       SettingsKeys.reminderEnabled, SettingsKeys.reminderHour, SettingsKeys.reminderMinute,
                       MushafPreferences.themeKey, MushafPreferences.scriptKey, MushafPreferences.translationKey,
                       MushafPreferences.layoutKey, MushafPreferences.directionKey, MushafPreferences.presentationKey,
                       "yaqeen.mushaf.colorMarkers", "yaqeen.mushaf.fitPage", "yaqeen.mushaf.didSelectAyah", Haptics.enabledKey,
                       CompanionReminderPlan.prayerKey, CompanionReminderPlan.morningKey, CompanionReminderPlan.eveningKey,
                       CompanionReminderPlan.soundKey, CompanionReminderPlan.quietStartKey, CompanionReminderPlan.quietEndKey]
    static func reset(_ defaults: UserDefaults = .standard) {
        for key in keys { defaults.removeObject(forKey: key) }
    }
}
