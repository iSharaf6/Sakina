import SwiftUI

struct CompanionOnboarding: View {
    static let completedKey = "companion.onboarding.complete"
    @AppStorage("companion.intention") private var intention = "read"
    @AppStorage(MushafPreferences.themeKey) private var theme: MushafPreferences.Theme = .system
    @AppStorage(SettingsKeys.reminderEnabled) private var daily = false
    @AppStorage(CompanionReminderPlan.prayerKey) private var prayers = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var floating = false
    @State private var showAccount = false
    @State private var showWidgets = false
    @State private var permissionBusy = false
    let onFinish: () -> Void
    private let intentions = [("read", "Read a little Qur’an", CompanionArtwork.quran), ("pray", "Keep close to prayer", .salah), ("remember", "Build a dhikr rhythm", .morning), ("reflect", "Find words for how I feel", .breathe)]
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Yaqeen").font(.yqHeadline).foregroundStyle(Color.yqAccentDeep)
                    Spacer()
                    Button("Skip for now", action: finish).font(.yqSubhead)
                }.padding(.horizontal, 24).padding(.top, 16)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 6) {
                            ForEach(0..<4) { index in Capsule().fill(index <= step ? Color.yqAccentDeep : Color.yqHairline).frame(width: index == step ? 28 : 12, height: 4) }
                        }.accessibilityLabel("Step \(step + 1) of 4")
                        CompanionIllustration(artwork: artwork, size: step == 0 ? 165 : 120)
                            .rotationEffect(.degrees(reduceMotion ? 0 : floating ? 2 : -2), anchor: .bottom)
                            .offset(y: reduceMotion ? 0 : floating ? -5 : 2)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: floating)
                        Text(title).font(.system(.largeTitle, design: .serif, weight: .medium)).fixedSize(horizontal: false, vertical: true)
                        Text(subtitle).font(.yqBody).foregroundStyle(Color.yqSecondary).fixedSize(horizontal: false, vertical: true)
                        if step == 0 {
                            if let ayah = QuranStore.shared.ayah("94:5") {
                                VStack(spacing: 12) {
                                    Text(QuranTextRenderer.swiftUI(ayah, script: .uthmani, size: 28))
                                    Text(ayah.translation).font(.yqSubhead).multilineTextAlignment(.center)
                                    Text("Ash-Sharh · 94:5").font(.yqCaption).foregroundStyle(Color.yqSecondary)
                                }.padding(22).frame(maxWidth: .infinity).yqCard(cornerRadius: 24)
                            }
                        } else if step == 1 {
                            ForEach(intentions, id: \.0) { value, title, art in
                                Button { intention = value; Haptics.tap() } label: {
                                    HStack(spacing: 14) {
                                        CompanionIllustration(artwork: art, size: 42)
                                        Text(title).font(.yqBodyMedium)
                                        Spacer()
                                        Image(systemName: intention == value ? "checkmark.circle.fill" : "circle").foregroundStyle(Color.yqAccentDeep)
                                    }.padding(16).yqCard()
                                }.buttonStyle(.plain)
                            }
                        } else if step == 2 {
                            RowGroup {
                                Toggle("A daily reflection", isOn: $daily).padding(18)
                                RowDivider(inset: 18)
                                Toggle("Prayer-time invitations", isOn: $prayers).padding(18)
                            }
                            Text("You choose what arrives. Times, sounds and quiet hours can be changed in Settings.").font(.yqCaption).foregroundStyle(Color.yqSecondary)
                            if daily || prayers {
                                Button("Allow my reminders") { Task { permissionBusy = true; await ReminderCenter.shared.enablePermissions(); permissionBusy = false } }
                                    .buttonStyle(.bordered).disabled(permissionBusy)
                                if prayers {
                                    Button("Set my prayer location") { Task { _ = await PrayerTimesService.shared.refreshUsingCurrentLocation() } }.buttonStyle(.bordered)
                                    if let location = PrayerTimesService.shared.schedule?.locationLabel { Text(location).font(.yqCaption) }
                                }
                            }
                        } else {
                            Picker("Appearance", selection: $theme) { ForEach(MushafPreferences.Theme.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.segmented)
                            Button { showWidgets = true } label: { BadgeRow(symbol: "square.grid.2x2", title: "Choose a widget companion", subtitle: "10 designs for your everyday", artwork: .morning) }.buttonStyle(.plain).yqCard()
                            Button { showAccount = true } label: { BadgeRow(symbol: "person.fill", title: "Sign in or create an account", subtitle: "Optional. Start reading without one.", artwork: .privacy) }.buttonStyle(.plain).yqCard()
                        }
                    }.padding(24)
                }
                HStack(spacing: 16) {
                    if step > 0 { Button("Back") { withAnimation { step -= 1 } }.font(.yqHeadline) }
                    Button(step == 3 ? "Make room for a moment" : step == 0 ? "Find my quiet corner" : "Continue") {
                        if step == 3 { finish() } else { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { step += 1 } }
                    }.font(.yqHeadline).frame(maxWidth: .infinity).padding(18).foregroundStyle(Color.yqOnAccent)
                        .background(Color.yqAccent, in: Capsule()).buttonStyle(.plain)
                }.padding(24)
            }.background(Color.yqCanvas).tint(.yqAccentDeep).preferredColorScheme(theme.colorScheme)
                .onAppear { floating = true }
                .sheet(isPresented: $showAccount) { NavigationStack { CompanionAccountView().toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAccount = false } } } } }
                .sheet(isPresented: $showWidgets) { NavigationStack { WidgetCollectionView().toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showWidgets = false } } } } }
        }
    }
    private var artwork: CompanionArtwork { [.breathe, .hopeful, .reminder, .appearance][step] }
    private var title: String { ["A little space\nfor your heart.", "What brings\nyou here?", "Small moments.\nYour own rhythm.", "Make it\nfeel like you."][step] }
    private var subtitle: String { ["Qur’an, du’a and remembrance. A place to return to, whatever today feels like.", "Start with what matters today. Everything else is here whenever you need it.", "Let Yaqeen meet you at the moments you choose.", "A quiet companion, on your screen and in your day."][step] }
    private func finish() { UserDefaults.standard.set(true, forKey: Self.completedKey); onFinish() }
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
