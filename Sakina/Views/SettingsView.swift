import GoogleSignInSwift
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
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

    @State private var showAbout = false
    @State private var showDisconnectConfirmation = false

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                List {
                    accountSection
                    languageSection
                    prayerSection
                    readingSection
                    remindersSection
                    trustSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 6, for: .scrollContent)
            }
            .navigationTitle(copy("Settings", "الإعدادات"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAbout) { AboutView() }
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
            .onChange(of: reminderEnabled) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: reminderHour) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: reminderMinute) { _, _ in ReminderScheduler.refresh() }
            .onChange(of: languageRaw) { _, _ in ReminderScheduler.refresh() }
        }
    }

    // MARK: Account

    private var accountSection: some View {
        Section {
            if !account.isConfigured {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        copy("Private on this iPhone", "خاص على هذا الهاتف"),
                        systemImage: "iphone.gen3.badge.checkmark"
                    )
                    .font(.headline)
                    .foregroundStyle(Color.sakinaInk)

                    Text(copy(
                        "Saved moments and reflections stay in Yaqeen’s private app storage. No account is required.",
                        "تبقى المواقف المحفوظة والتأملات في مساحة يقين الخاصة، ولا يلزم إنشاء حساب."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 5)
            } else if account.isSignedIn {
                HStack(spacing: 13) {
                    AsyncImage(url: account.imageURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(Color.sakinaMuted.opacity(0.45))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(account.displayName)
                            .font(.headline)
                            .foregroundStyle(Color.sakinaInk)
                        Text(account.email)
                            .font(.caption)
                            .foregroundStyle(Color.sakinaMuted)
                    }
                }
                .padding(.vertical, 4)

                Button {
                    backUpNow()
                } label: {
                    Label(copy("Back up now", "نسخ احتياطي الآن"), systemImage: "arrow.triangle.2.circlepath.icloud")
                }
                .disabled(isSyncing)

                Button {
                    restoreBackup()
                } label: {
                    Label(copy("Restore & merge", "استعادة ودمج"), systemImage: "arrow.down.doc")
                }
                .disabled(isSyncing)

                if let syncMessage {
                    Label(syncMessage, systemImage: syncSymbol)
                        .font(.caption)
                        .foregroundStyle(syncColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(copy("Sign out", "تسجيل الخروج")) {
                    account.signOut()
                }

                Button(copy("Disconnect Google", "قطع الاتصال بحساب Google"), role: .destructive) {
                    showDisconnectConfirmation = true
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(copy("Keep your reflections with you", "احتفظ بتأملاتك معك"), systemImage: "lock.shield")
                        .font(.headline)
                        .foregroundStyle(Color.sakinaInk)
                    Text(copy(
                        "Yaqeen is local-first. Connect Google to keep an encrypted-in-transit private backup in your Google Drive app-data space.",
                        "يقين يحفظ بياناتك على جهازك أولًا. اربط حساب Google لحفظ نسخة خاصة في مساحة بيانات التطبيق على Google Drive."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                GoogleSignInButton(viewModel: googleButtonModel) {
                    account.signIn()
                }
                .frame(minHeight: 50)

                if case .failure(let message) = account.syncState {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text(account.isConfigured
                 ? copy("Account & backup", "الحساب والنسخ الاحتياطي")
                 : copy("Privacy & storage", "الخصوصية والتخزين"))
        } footer: {
            if account.isConfigured {
                Text(copy(
                    "While connected, changes to Saved are backed up after you make them. The backup lives in a hidden app-data folder that only Yaqeen can access after you grant permission.",
                    "أثناء الاتصال، تُنسخ تغييرات المحفوظات احتياطيًا بعد إجرائها. وتُحفظ النسخة في مساحة مخفية لا يصل إليها إلا تطبيق يقين بعد موافقتك."
                ))
            } else {
                Text(copy(
                    "Your private writing is not uploaded by Yaqeen.",
                    "لا يرفع يقين كتاباتك الخاصة إلى أي خادم."
                ))
            }
        }
        .listRowBackground(Color.sakinaElevated)
    }

    private var googleButtonModel: GoogleSignInButtonViewModel {
        GoogleSignInButtonViewModel(
            scheme: .light,
            style: .wide,
            state: .normal
        )
    }

    private var isSyncing: Bool {
        if case .working = account.syncState { return true }
        return false
    }

    private var syncMessage: String? {
        switch account.syncState {
        case .idle:
            if let date = UserDefaults.standard.object(forKey: "googleBackupLastSync") as? Date {
                return copy(
                    "Last synced \(date.formatted(date: .abbreviated, time: .shortened))",
                    "آخر مزامنة \(date.formatted(date: .abbreviated, time: .shortened))"
                )
            }
            return nil
        case .working(let message), .success(let message), .failure(let message):
            return message
        }
    }

    private var syncSymbol: String {
        switch account.syncState {
        case .working: return "arrow.triangle.2.circlepath"
        case .failure: return "exclamationmark.circle"
        case .success: return "checkmark.circle.fill"
        case .idle: return "checkmark.icloud"
        }
    }

    private var syncColor: Color {
        if case .failure = account.syncState { return .red }
        return .sakinaMuted
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

    // MARK: Preferences

    private var languageSection: some View {
        Section {
            Picker(copy("App language", "لغة التطبيق"), selection: $languageRaw) {
                ForEach(AppLanguage.allCases) { item in
                    Text(item.nativeName).tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Toggle(copy("Show English meaning", "إظهار المعنى بالإنجليزية"), isOn: $translationVisible)
            Toggle(copy("Show du’a transliteration", "إظهار كتابة الدعاء بحروف لاتينية"), isOn: $transliterationVisible)
        } header: {
            Text(copy("Language", "اللغة"))
        }
        .listRowBackground(Color.sakinaElevated)
    }

    private var readingSection: some View {
        Section {
            Picker(copy("Reciter", "القارئ"), selection: $reciterRaw) {
                ForEach(Reciter.allCases) { reciter in
                    Text(reciter.displayName).tag(reciter.rawValue)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(copy("Qur’an text size", "حجم خط القرآن"))
                    Spacer()
                    Text("بِسْمِ ٱللَّهِ")
                        .font(.arabic(18 * arabicScale))
                        .foregroundStyle(Color.sakinaInk)
                }
                Slider(value: $arabicScale, in: 0.85...1.45, step: 0.05)
                    .tint(.sakinaInk)
            }
        } header: {
            Text(copy("Reading & recitation", "القراءة والتلاوة"))
        }
        .listRowBackground(Color.sakinaElevated)
    }

    private var prayerSection: some View {
        Section {
            if let schedule = prayerService.schedule {
                LabeledContent {
                    Text(schedule.locationLabel)
                        .foregroundStyle(Color.sakinaMuted)
                } label: {
                    Label(copy("Location", "الموقع"), systemImage: "location.fill")
                }
            }

            Picker(copy("Calculation method", "طريقة الحساب"), selection: $prayerMethodRaw) {
                ForEach(PrayerCalculationMethod.allCases) { method in
                    Text(method.displayName).tag(method.rawValue)
                }
            }

            Picker(copy("Asr method", "طريقة العصر"), selection: $prayerAsrRaw) {
                ForEach(PrayerAsrMethod.allCases) { method in
                    Text(method.displayName).tag(method.rawValue)
                }
            }

            Picker(copy("High latitudes", "خطوط العرض العليا"), selection: $highLatitudeRaw) {
                ForEach(PrayerHighLatitudePreference.allCases) { preference in
                    Text(preference.displayName).tag(preference.rawValue)
                }
            }

            Button {
                updatePrayerTimes()
            } label: {
                HStack {
                    Label(
                        prayerService.schedule == nil
                            ? copy("Set from my location", "اضبط حسب موقعي")
                            : copy("Update prayer times", "تحديث مواقيت الصلاة"),
                        systemImage: "location.viewfinder"
                    )
                    Spacer()
                    if prayerService.isRefreshing { ProgressView().controlSize(.small) }
                }
            }
            .disabled(prayerService.isRefreshing)

            if let error = prayerService.errorMessage {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text(copy("Prayer times & widgets", "مواقيت الصلاة والأدوات"))
        } footer: {
            Text(copy(
                "Times are calculated offline. Add the Yaqeen Prayer Times widget to your Home Screen or Lock Screen after setting a location.",
                "تُحسب المواقيت دون اتصال. أضف أداة مواقيت يقين إلى الشاشة الرئيسية أو شاشة القفل بعد تحديد الموقع."
            ))
        }
        .listRowBackground(Color.sakinaElevated)
    }

    private func updatePrayerTimes() {
        var settings = PrayerCalculationSettings.default
        settings.method = PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muslimWorldLeague
        settings.asrMethod = PrayerAsrMethod(rawValue: prayerAsrRaw) ?? .standard
        settings.highLatitudePreference = PrayerHighLatitudePreference(rawValue: highLatitudeRaw) ?? .automatic
        Task { await prayerService.refreshUsingCurrentLocation(settings: settings) }
    }

    private var remindersSection: some View {
        Section {
            Toggle(copy("Daily guidance reminder", "تذكير يومي بالهداية"), isOn: $reminderEnabled)
            if reminderEnabled {
                DatePicker(
                    copy("Reminder time", "وقت التذكير"),
                    selection: reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text(copy("Reminders", "التذكيرات"))
        } footer: {
            Text(copy(
                "A gentle daily invitation, never a streak or score.",
                "دعوة يومية لطيفة، بلا سلاسل أو نقاط."
            ))
        }
        .listRowBackground(Color.sakinaElevated)
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

    private var trustSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label(copy("Sources, privacy & about", "المصادر والخصوصية وحول التطبيق"), systemImage: "checkmark.shield")
            }

            Link(destination: URL(string: "https://quran.com")!) {
                Label(copy("Qur’an source: Quran.com", "مصدر القرآن: Quran.com"), systemImage: "arrow.up.right.square")
            }
        } header: {
            Text(copy("Trust", "الأمانة"))
        } footer: {
            Text(copy(
                "Qur’anic guidance supports reflection; it does not replace qualified scholarship, pastoral care, or professional help.",
                "الهداية القرآنية تعين على التدبر، ولا تغني عن سؤال أهل العلم أو الدعم الأسري أو المساعدة المتخصصة."
            ))
        }
        .listRowBackground(Color.sakinaElevated)
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
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.sakinaInk)

                    Text(copy("One developer step remains", "تبقت خطوة للمطور"))
                        .font(.display(30))
                        .foregroundStyle(Color.sakinaInk)

                    Text(copy(
                        "Google requires an OAuth client tied to this app’s bundle ID. Add your iOS client ID and reversed URL scheme in project.yml, enable the Google Drive API, then regenerate the Xcode project.",
                        "يتطلب Google معرّف OAuth مرتبطًا بحزمة التطبيق. أضف معرّف iOS ومخطط الرابط المعكوس في project.yml، وفعّل Google Drive API، ثم أعد توليد مشروع Xcode."
                    ))
                    .font(.body)
                    .foregroundStyle(Color.sakinaMuted)
                    .lineSpacing(5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOOGLE_CLIENT_ID")
                        Text("GOOGLE_REVERSED_CLIENT_ID")
                    }
                    .font(.system(.callout, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Color.sakinaInk)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 16))

                    Text(copy(
                        "The app intentionally refuses to fake a login when those credentials are absent. Local notes and bookmarks remain fully usable.",
                        "يرفض التطبيق عمدًا محاكاة تسجيل الدخول عند غياب بيانات الاعتماد. وتبقى الملاحظات والمحفوظات المحلية متاحة بالكامل."
                    ))
                    .font(.footnote)
                    .foregroundStyle(Color.sakinaMuted)
                }
                .padding(22)
            }
            .background(Color.sakinaCanvas)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
    }
}
