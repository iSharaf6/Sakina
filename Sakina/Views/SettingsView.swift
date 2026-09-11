import GoogleSignInSwift
import SwiftData
import SwiftUI

/// Settings is five short groups in the order people reach for them:
/// prayer, reading, reminders, backup, about. Every row is a `BadgeRow`
/// inside a `RowGroup`, so the screen reads like Explore and Home.
struct SettingsView: View {
    var showsDismissButton = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]

    @ObservedObject private var account = GoogleAccountManager.shared
    @ObservedObject private var prayerService = PrayerTimesService.shared
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.translationVisible) private var translationVisible = true
    @AppStorage(SettingsKeys.transliterationVisible) private var transliterationVisible = true
    @AppStorage(SettingsKeys.reciter) private var reciterRaw = Reciter.alafasy.rawValue
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(SettingsKeys.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKeys.reminderHour) private var reminderHour = 9
    @AppStorage(SettingsKeys.reminderMinute) private var reminderMinute = 0
    @AppStorage(SettingsKeys.prayerCalculationMethod) private var prayerMethodRaw = PrayerCalculationMethod.muslimWorldLeague.rawValue
    @AppStorage(SettingsKeys.prayerAsrMethod) private var prayerAsrRaw = PrayerAsrMethod.standard.rawValue
    @AppStorage(SettingsKeys.prayerHighLatitude) private var highLatitudeRaw = PrayerHighLatitudePreference.automatic.rawValue
    @AppStorage(Haptics.enabledKey) private var hapticsEnabled = true

    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .system
    @State private var showReaderAppearance = false
    @State private var showAbout = false
    @State private var resetConfirmation = false
    @State private var resetting = false
    @State private var replayOnboarding = false
    @State private var showDisconnectConfirmation = false
    @State private var appeared = false

    private func useDigitalReading() {
        guard !resetting else { return }
        UserDefaults.standard.set(MushafPreferences.Presentation.digital.rawValue, forKey: MushafPreferences.presentationKey)
    }

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    PageHeader(title: copy("Settings", "الإعدادات"))
                        .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                    RowGroup {
                        NavigationLink { CompanionAccountView() } label: { BadgeRow(symbol: "person.fill", title: copy("Account", "الحساب"), subtitle: copy("Sign in or create an account", "تسجيل الدخول أو إنشاء حساب"), artwork: .privacy) }
                        RowDivider()
                        NavigationLink { WidgetCollectionView() } label: { BadgeRow(symbol: "square.grid.2x2", title: copy("Widget collection", "مجموعة الأدوات"), subtitle: copy("10 companions for your screens", "١٠ تصاميم لشاشاتك"), artwork: .morning) }
                    }.buttonStyle(.plain)
                    prayerSection.revealed(1, appeared: appeared, reduceMotion: reduceMotion)
                    readingSection.revealed(2, appeared: appeared, reduceMotion: reduceMotion)
                    remindersSection.revealed(3, appeared: appeared, reduceMotion: reduceMotion)
                    feedbackSection.revealed(4, appeared: appeared, reduceMotion: reduceMotion)
                    helpSection.revealed(5, appeared: appeared, reduceMotion: reduceMotion)
                    communitySection.revealed(6, appeared: appeared, reduceMotion: reduceMotion)
                    backupSection.revealed(7, appeared: appeared, reduceMotion: reduceMotion)
                    aboutSection.revealed(8, appeared: appeared, reduceMotion: reduceMotion)
                    RowGroup {
                        Button { replayOnboarding = true } label: { BadgeRow(symbol: "sparkles", title: copy("Welcome tour", "جولة الترحيب"), artwork: .breathe) }.buttonStyle(.plain)
                        RowDivider()
                        Button { resetConfirmation = true } label: { BadgeRow(symbol: "arrow.counterclockwise", title: copy("Reset settings", "إعادة ضبط الإعدادات"), subtitle: copy("Keep your saved ayat and notes", "الاحتفاظ بالآيات والملاحظات المحفوظة"), artwork: .settings) }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .yqScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(copy("Done", "تم")) { dismiss() }
                            .font(.yqSubheadBold)
                            .tint(.yqAccentDeep)
                    }
                }
            }
            .fullScreenCover(isPresented: $replayOnboarding) { CompanionOnboarding(allowsDismiss: true) { replayOnboarding = false } }
            .confirmationDialog(copy("Reset settings?", "إعادة ضبط الإعدادات؟"), isPresented: $resetConfirmation, titleVisibility: .visible) {
                Button(copy("Reset settings", "إعادة الضبط"), role: .destructive) {
                    resetting = true
                    SettingsReset.reset()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { resetting = false }
                    PrayerTimesService.shared.refreshSavedLocation()
                    ReminderScheduler.refresh()
                }
            } message: { Text(copy("Appearance, reading, prayer calculation and reminder preferences return to their defaults. Your notes, saved ayat, progress and account stay.", "ستعود إعدادات المظهر والقراءة والصلاة والتذكيرات إلى الوضع الافتراضي. ستبقى ملاحظاتك وآياتك وتقدمك وحسابك.")) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showReaderAppearance) { MushafDisplaySheet(language: language) }
            .preferredColorScheme(theme.colorScheme)
            .onChange(of: arabicScale) { _, _ in useDigitalReading() }
            .onChange(of: translationVisible) { _, _ in useDigitalReading() }
            .onChange(of: transliterationVisible) { _, _ in useDigitalReading() }
            .sheet(isPresented: $account.showConfigurationHelp) {
                GoogleConfigurationHelp(language: language)
            }
            .confirmationDialog(
                copy("Disconnect Google?", "قطع الاتصال بحساب Google؟"),
                isPresented: $showDisconnectConfirmation,
                titleVisibility: .visible
            ) {
                Button(copy("Disconnect and revoke access", "قطع الاتصال وإلغاء الوصول"), role: .destructive) {
                    account.disconnect()
                }
                Button(copy("Cancel", "إلغاء"), role: .cancel) {}
            } message: {
                Text(copy(
                    "Your local notes stay on this iPhone. The private Drive backup is not deleted.",
                    "ستبقى ملاحظاتك على هذا الهاتف، ولن تُحذف النسخة الخاصة من Google Drive."
                ))
            }
            .onAppear { appeared = true }
            .onChange(of: hapticsEnabled) { _, on in if on { Haptics.success() } }
            .onChange(of: reminderEnabled) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: reminderHour) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: reminderMinute) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: [prayerMethodRaw, prayerAsrRaw, highLatitudeRaw]) { _, _ in PrayerTimesService.shared.refreshSavedLocation() }
            .onChange(of: languageRaw) { _, _ in ReminderScheduler.refresh() }
        }
    }

    // MARK: Prayer

    private var prayerSection: some View {
        SettingsGroup(
            title: copy("Prayer times", "مواقيت الصلاة"),
            footnote: copy(
                "Calculated offline. Add the Haneen widget to your Home or Lock Screen once a location is set.",
                "تُحسب دون اتصال. أضف أداة حنين إلى الشاشة الرئيسية أو شاشة القفل بعد تحديد الموقع."
            )
        ) {
            BadgeRow(
                symbol: "location.fill",
                title: copy("Location", "الموقع"),
                subtitle: prayerService.schedule?.locationLabel ?? copy("Not set yet", "لم يُحدَّد بعد")
            ) {
                Button(action: updatePrayerTimes) {
                    Group {
                        if prayerService.isRefreshing {
                            ProgressView().controlSize(.small).tint(.yqAccentDeep)
                        } else {
                            Text(prayerService.schedule == nil
                                 ? copy("Set", "اضبط")
                                 : copy("Update", "تحديث"))
                        }
                    }
                    .font(.yqSubheadBold)
                    .foregroundStyle(Color.yqAccentDeep)
                    .frame(minWidth: 62, minHeight: 32)
                    .background(Color.yqAccentTint, in: Capsule(style: .continuous))
                }
                .buttonStyle(.yqPress)
                .disabled(prayerService.isRefreshing)
            }

            if let error = prayerService.errorMessage {
                Text(error)
                    .font(.yqCaption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            RowDivider()
            MenuRow(symbol: "function", title: copy("Calculation method", "طريقة الحساب"),
                    value: prayerMethod.displayName, selection: $prayerMethodRaw) {
                ForEach(PrayerCalculationMethod.allCases) { Text($0.displayName).tag($0.rawValue) }
            }
            RowDivider()
            MenuRow(symbol: "sun.max.fill", title: copy("Asr", "العصر"),
                    value: prayerAsr.displayName, selection: $prayerAsrRaw) {
                ForEach(PrayerAsrMethod.allCases) { Text($0.displayName).tag($0.rawValue) }
            }
            RowDivider()
            MenuRow(symbol: "globe.europe.africa.fill", title: copy("High latitudes", "خطوط العرض العليا"),
                    value: highLatitude.displayName, selection: $highLatitudeRaw) {
                ForEach(PrayerHighLatitudePreference.allCases) { Text($0.displayName).tag($0.rawValue) }
            }
        }
    }

    private var prayerMethod: PrayerCalculationMethod {
        PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muslimWorldLeague
    }

    private var prayerAsr: PrayerAsrMethod {
        PrayerAsrMethod(rawValue: prayerAsrRaw) ?? .standard
    }

    private var highLatitude: PrayerHighLatitudePreference {
        PrayerHighLatitudePreference(rawValue: highLatitudeRaw) ?? .automatic
    }

    private func updatePrayerTimes() {
        var settings = PrayerCalculationSettings.default
        settings.method = prayerMethod
        settings.asrMethod = prayerAsr
        settings.highLatitudePreference = highLatitude
        Task { await prayerService.refreshUsingCurrentLocation(settings: settings) }
    }

    // MARK: Reading

    private var readingSection: some View {
        SettingsGroup(title: copy("Reading", "القراءة"), footnote: copy("Text size, translation and transliteration are shared by the Qur’an and du’a readers.", "حجم الخط والترجمة والكتابة اللاتينية مشتركة بين قارئ القرآن والأدعية.")) {
            MenuRow(symbol: "character.bubble.fill", title: copy("App language", "لغة التطبيق"),
                    value: language.nativeName, selection: $languageRaw) {
                ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0.rawValue) }
            }
            RowDivider()
            MenuRow(symbol: "waveform", title: copy("Reciter", "القارئ"),
                    value: reciter.displayName, selection: $reciterRaw) {
                ForEach(Reciter.allCases) { Text($0.displayName).tag($0.rawValue) }
            }
            RowDivider()
            Button { showReaderAppearance = true } label: {
                BadgeRow(symbol: "book.closed", title: copy("Qur’an reader", "قارئ القرآن")) {
                    Image(systemName: "chevron.forward").foregroundStyle(Color.yqSecondary)
                }
            }.buttonStyle(.plain)
            RowDivider()
            MenuRow(symbol: "circle.lefthalf.filled", title: copy("Appearance", "المظهر"),
                    value: theme.title(language), selection: $theme) {
                ForEach(MushafPreferences.Theme.allCases) { Text($0.title(language)).tag($0) }
            }
            RowDivider()
            ToggleRow(symbol: "text.quote", title: copy("English meaning", "المعنى بالإنجليزية"),
                      isOn: $translationVisible)
            RowDivider()
            ToggleRow(symbol: "textformat.abc", title: copy("Transliteration", "الكتابة بحروف لاتينية"),
                      isOn: $transliterationVisible)
            RowDivider()
            VStack(spacing: 0) {
                BadgeRow(symbol: "textformat.size", title: copy("Arabic text size", "حجم الخط العربي")) {
                    Text("بِسْمِ ٱللَّهِ")
                        .font(.arabic(18 * arabicScale))
                        .foregroundStyle(Color.yqInk)
                        .lineLimit(1)
                        .frame(height: 30)
                }
                HStack(spacing: 12) {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 13, weight: .semibold))
                    Slider(value: $arabicScale, in: MushafPreferences.fontScaleRange, step: 0.05)
                        .tint(.yqAccentDeep)
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.yqSecondary)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
    }

    private var reciter: Reciter { Reciter(rawValue: reciterRaw) ?? .alafasy }

    // MARK: Reminders

    private var remindersSection: some View {
        SettingsGroup(title: copy("Reminders", "التذكيرات")) {
            NavigationLink { ReminderSettingsView() } label: {
                BadgeRow(symbol: "bell.fill", title: copy("Your reminders", "تذكيراتك"),
                         subtitle: copy("Prayers, adhkar and a daily reflection", "الصلاة والأذكار وتأمل يومي"))
            }.buttonStyle(.plain)
        }
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now
        } set: { value in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
            reminderHour = parts.hour ?? 9
            reminderMinute = parts.minute ?? 0
        }
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        SettingsGroup(
            title: copy("Feel", "الإحساس"),
            footnote: copy("Taps, dhikr counts and finished goals answer back with a small vibration.",
                           "الضغطات وعدّ الذكر وإتمام الأهداف تردّ عليك باهتزاز خفيف.")
        ) {
            ToggleRow(symbol: "hand.tap.fill", title: copy("Haptics", "الاهتزاز"), isOn: $hapticsEnabled)
        }
    }

    // MARK: Help

    private var helpSection: some View {
        SettingsGroup(title: copy("Help", "المساعدة")) {
            NavigationLink { FAQView(language: language) } label: {
                BadgeRow(symbol: "questionmark.circle.fill", title: copy("Questions & answers", "أسئلة وأجوبة"))
            }
            .buttonStyle(.yqPressSoft)
            RowDivider()
            NavigationLink { ContactSupportView(language: language) } label: {
                BadgeRow(symbol: "envelope.fill", title: copy("Contact support", "الدعم الفني"),
                         subtitle: copy("Report a problem or send an idea", "أبلغ عن مشكلة أو أرسل فكرة"))
            }
            .buttonStyle(.yqPressSoft)
            RowDivider()
            NavigationLink { AboutUsView(language: language) } label: {
                BadgeRow(symbol: "person.2.fill", title: copy("About us", "من نحن"))
            }
            .buttonStyle(.yqPressSoft)
        }
    }

    // MARK: Community

    private var communitySection: some View {
        SettingsGroup(title: copy("Spread the word", "انشر الخير")) {
            ShareLink(item: AppLinks.shareText(language)) {
                BadgeRow(symbol: "square.and.arrow.up.fill", title: copy("Share Haneen", "شارك حنين"),
                         subtitle: copy("Send it to someone who’d use it", "أرسله لمن ينتفع به"))
            }
            .buttonStyle(.yqPressSoft)
            RowDivider()
            Button { AppRating.request(fallback: openURL) } label: {
                BadgeRow(symbol: "star.fill", title: copy("Rate Haneen", "قيّم حنين"),
                         subtitle: copy("A review helps others find it", "تقييمك يساعد غيرك على إيجاده"))
            }
            .buttonStyle(.yqPressSoft)
        }
    }

    // MARK: Backup

    @ViewBuilder
    private var backupSection: some View {
        if !account.isConfigured {
            SettingsGroup(title: copy("Your data", "بياناتك")) {
                BadgeRow(
                    symbol: "iphone.gen3",
                    title: copy("Stored on this iPhone", "محفوظة على هذا الهاتف"),
                    subtitle: copy(
                        "Saved moments and reflections never leave the app’s private storage.",
                        "تبقى المواقف المحفوظة والتأملات في مساحة التطبيق الخاصة ولا تُرفع أبدًا."
                    )
                ) { EmptyView() }
            }
        } else if account.isSignedIn {
            SettingsGroup(title: copy("Backup", "النسخ الاحتياطي"), footnote: syncMessage) {
                HStack(spacing: 14) {
                    AsyncImage(url: account.imageURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            CompanionIllustration(artwork: .confident, size: 36)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.displayName)
                            .font(.yqBodyMedium)
                            .foregroundStyle(Color.yqInk)
                        Text(account.email)
                            .font(.yqSubhead)
                            .foregroundStyle(Color.yqSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 58)

                RowDivider()
                ActionRow(symbol: "arrow.triangle.2.circlepath",
                          title: copy("Back up now", "نسخ احتياطي الآن"),
                          busy: isSyncing, action: backUpNow)
                RowDivider()
                ActionRow(symbol: "arrow.down.doc.fill",
                          title: copy("Restore & merge", "استعادة ودمج"),
                          busy: isSyncing, action: restoreBackup)
                RowDivider()
                ActionRow(symbol: "rectangle.portrait.and.arrow.right",
                          title: copy("Sign out", "تسجيل الخروج"),
                          action: account.signOut)
                RowDivider()
                ActionRow(symbol: "xmark.circle.fill", tint: .red,
                          title: copy("Disconnect Google", "قطع الاتصال بحساب Google"),
                          destructive: true) { showDisconnectConfirmation = true }
            }
        } else {
            SettingsGroup(
                title: copy("Backup", "النسخ الاحتياطي"),
                footnote: copy(
                    "Haneen is local-first. A private copy of Saved goes to your Google Drive app-data space, which only Haneen can read.",
                    "حنين يحفظ بياناتك على جهازك أولًا. تُحفظ نسخة خاصة من المحفوظات في مساحة بيانات التطبيق على Google Drive ولا يقرؤها إلا حنين."
                )
            ) {
                BadgeRow(
                    symbol: "lock.shield.fill",
                    title: copy("Keep your reflections with you", "احتفظ بتأملاتك معك"),
                    subtitle: copy("Optional. Nothing is uploaded until you connect.", "اختياري. لا يُرفع شيء قبل الربط.")
                ) { EmptyView() }

                GoogleSignInButton(viewModel: googleButtonModel) { account.signIn() }
                    .frame(minHeight: 48)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)

                if case .failure(let message) = account.syncState {
                    Text(message)
                        .font(.yqCaption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private var googleButtonModel: GoogleSignInButtonViewModel {
        GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: .normal)
    }

    private var isSyncing: Bool {
        if case .working = account.syncState { return true }
        return false
    }

    private var syncMessage: String? {
        switch account.syncState {
        case .idle:
            if let date = UserDefaults.standard.object(forKey: "googleBackupLastSync") as? Date {
                let stamp = date.formatted(date: .abbreviated, time: .shortened)
                return copy("Last backed up \(stamp).", "آخر نسخة احتياطية \(stamp).")
            }
            return copy("Saved is backed up after every change while connected.",
                        "تُنسخ المحفوظات احتياطيًا بعد كل تغيير أثناء الاتصال.")
        case .working(let message), .success(let message), .failure(let message):
            return message
        }
    }

    private func backUpNow() {
        guard let backup = YaqeenBackup.snapshot(from: context) else { return }
        Task { _ = await account.upload(backup) }
    }

    private func restoreBackup() {
        Task {
            guard let backup = await account.download() else { return }
            merge(backup)
        }
    }

    private func merge(_ backup: YaqeenBackup) {
        let savedIDs = Set(bookmarks.map(\.situationID))
        for remote in backup.savedMoments where !savedIDs.contains(remote.situationID) {
            guard SituationCatalog.by(id: remote.situationID) != nil else { continue }
            context.insert(Bookmark(situationID: remote.situationID, createdAt: remote.createdAt))
        }

        let localByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.syncID, $0) })
        for remote in backup.reflections {
            guard SituationCatalog.by(id: remote.situationID) != nil else { continue }
            if let local = localByID[remote.id] {
                if remote.updatedAt > local.updatedAt {
                    local.text = remote.text
                    local.situationID = remote.situationID
                    local.updatedAt = remote.updatedAt
                }
            } else {
                context.insert(JournalEntry(
                    syncID: remote.id,
                    situationID: remote.situationID,
                    text: remote.text,
                    createdAt: remote.createdAt,
                    updatedAt: remote.updatedAt
                ))
            }
        }
        try? context.save()
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsGroup(
            title: copy("Sources & privacy", "المصادر والخصوصية"),
            footnote: copy(
                "Read the original references and learn about Haneen.",
                "اقرأ المراجع الأصلية وتعرّف على حنين."
            )
        ) {
            Button { showAbout = true } label: {
                BadgeRow(symbol: "checkmark.shield.fill",
                         title: copy("Sources, privacy & credits", "المصادر والخصوصية والشكر"))
            }
            .buttonStyle(.yqPress)

            RowDivider()
            Link(destination: URL(string: "https://quran.com")!) {
                BadgeRow(symbol: "book.closed.fill", title: copy("Qur’an source", "مصدر القرآن"), subtitle: "Quran.com") {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.yqTertiary)
                }
            }
            .buttonStyle(.yqPress)

            RowDivider()
            BadgeRow(symbol: "info.circle.fill", title: copy("Version", "الإصدار")) {
                Text(versionLabel)
                    .font(.yqSubhead)
                    .foregroundStyle(Color.yqSecondary)
                    .monospacedDigit()
            }
        }
    }

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(version) (\($0))" } ?? version
    }
}

// MARK: - Settings building blocks

/// A titled card of rows with an optional one-line footnote beneath it.
private struct SettingsGroup<Content: View>: View {
    let title: String
    var footnote: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title)
            RowGroup { content() }
            if let footnote {
                Text(footnote)
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
            }
        }
    }
}

/// A row whose trailing switch is the whole point.
private struct ToggleRow: View {
    let symbol: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        BadgeRow(symbol: symbol, title: title) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.yqAccentDeep)
        }
        .haptic(.press, on: isOn)
        .accessibilityElement(children: .combine)
    }
}

/// A row that opens a menu of choices; the current choice sits under the title.
private struct MenuRow<Options: View, Value: Hashable>: View {
    let symbol: String
    let title: String
    let value: String
    @Binding var selection: Value
    @ViewBuilder var options: () -> Options

    var body: some View {
        Menu {
            Picker(title, selection: $selection) { options() }
        } label: {
            BadgeRow(symbol: symbol, title: title, subtitle: value, subtitleLines: 1) {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.yqTertiary)
            }
        }
        .tint(.yqInk)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

/// A tappable row that performs an action instead of navigating.
private struct ActionRow: View {
    let symbol: String
    var tint: Color = .yqAccent
    let title: String
    var busy = false
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BadgeRow(symbol: symbol, tint: tint, title: title) {
                if busy { ProgressView().controlSize(.small).tint(.yqSecondary) }
            }
            .foregroundStyle(destructive ? Color.red : Color.yqInk)
        }
        .buttonStyle(.yqPress)
        .disabled(busy)
    }
}

private struct GoogleConfigurationHelp: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    IconBadge(symbol: "wrench.and.screwdriver.fill", size: 48)

                    Text(copy("One developer step remains", "تبقت خطوة للمطور"))
                        .font(.yqTitle)
                        .foregroundStyle(Color.yqInk)

                    Text(copy(
                        "Google requires an OAuth client tied to this app’s bundle ID. Add your iOS client ID and reversed URL scheme in project.yml, enable the Google Drive API, then regenerate the Xcode project.",
                        "يتطلب Google معرّف OAuth مرتبطًا بحزمة التطبيق. أضف معرّف iOS ومخطط الرابط المعكوس في project.yml، وفعّل Google Drive API، ثم أعد توليد مشروع Xcode."
                    ))
                    .font(.yqBody)
                    .foregroundStyle(Color.yqSecondary)
                    .lineSpacing(5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOOGLE_CLIENT_ID")
                        Text("GOOGLE_REVERSED_CLIENT_ID")
                    }
                    .font(.system(.callout, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Color.yqInk)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .yqCard()

                    Text(copy(
                        "The app intentionally refuses to fake a login when those credentials are absent. Local notes and bookmarks remain fully usable.",
                        "يرفض التطبيق عمدًا محاكاة تسجيل الدخول عند غياب بيانات الاعتماد. وتبقى الملاحظات والمحفوظات المحلية متاحة بالكامل."
                    ))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqSecondary)
                }
                .padding(22)
            }
            .yqScreen()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
    }
}
