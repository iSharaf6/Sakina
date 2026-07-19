import SwiftUI

// MARK: Settings and about

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKeys.reminderHour) private var reminderHour = 9
    @AppStorage(SettingsKeys.reminderMinute) private var reminderMinute = 0
    @AppStorage(SettingsKeys.reciter) private var reciterRaw = Reciter.alafasy.rawValue
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: reminderHour, minute: reminderMinute)
                ) ?? .now
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = comps.hour ?? 9
                reminderMinute = comps.minute ?? 0
                ReminderScheduler.refresh()
            }
        )
    }

    var body: some View {
        ZStack {
            AtmosphereBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    EightPointStar()
                        .fill(Color.sakinaGold)
                        .frame(width: 22, height: 22)
                        .padding(.top, 36)

                    VStack(spacing: 8) {
                        Text("Sakina")
                            .font(.display(36))
                            .foregroundStyle(Color.sakinaInk)
                        Text("سَكِينَة means tranquility")
                            .font(.reading(15))
                            .italic()
                            .foregroundStyle(Color.sakinaMuted)
                    }

                    reminderCard
                    recitationCard
                    textSizeCard
                    sourcesCard
                    amanahCard
                    syncCard

                    Text("May Allah place sakina in every home.")
                        .font(.reading(15))
                        .italic()
                        .foregroundStyle(Color.sakinaGold)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.sakinaMuted.opacity(0.7))
            }
            .padding(20)
            .accessibilityLabel("Close")
        }
    }

    // MARK: Daily reminder

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(text: "Daily reminder", color: .sakinaGold)
            Toggle(isOn: $reminderEnabled) {
                Text("Ayah of the day notification")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.sakinaInk)
            }
            .tint(.sakinaGold)
            .onChange(of: reminderEnabled) {
                ReminderScheduler.refresh()
            }
            if reminderEnabled {
                DatePicker(
                    selection: reminderTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Text("Time")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.sakinaInk)
                }
                .tint(.sakinaGold)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard(tint: .sakinaGold)
    }

    // MARK: Recitation

    private var recitationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CapsLabel(text: "Recitation", color: .sakinaGold)
            Picker("Reciter", selection: $reciterRaw) {
                ForEach(Reciter.allCases) { reciter in
                    Text(reciter.displayName).tag(reciter.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(.sakinaGold)
            Text("Streamed verse by verse from everyayah.com")
                .font(.system(size: 11))
                .foregroundStyle(Color.sakinaMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard()
    }

    // MARK: Arabic text size

    private var textSizeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(text: "Arabic text size", color: .sakinaGold)
            Text("الْحَمْدُ لِلَّهِ رَبِّ الْعَـٰلَمِينَ")
                .font(.arabic(24 * arabicScale))
                .foregroundStyle(Color.sakinaInk)
                .frame(maxWidth: .infinity, alignment: .center)
                .animation(.easeOut(duration: 0.15), value: arabicScale)
            Slider(value: $arabicScale, in: 0.85...1.5, step: 0.05)
                .tint(.sakinaGold)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard()
    }

    // MARK: Sources

    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CapsLabel(text: "Sources", color: .sakinaGold)
            sourceRow("Arabic text", "Uthmani script, Quran.com API")
            sourceRow("Translation", "Saheeh International, via the Quran.com API")
            sourceRow("Typeface", "KFGQPC HAFS Uthmanic Script, King Fahd Complex")
            sourceRow("Recitation", "Streamed from everyayah.com")
            sourceRow("Citations", "Sahih al Bukhari and Jami at Tirmidhi")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard(tint: .sakinaGold)
    }

    private func sourceRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.sakinaInk)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(Color.sakinaMuted)
        }
    }

    // MARK: Amanah

    private var amanahCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsLabel(text: "An amanah", color: .sakinaGold)
            Text("The Qur'an is a trust. The verse notes in this app are brief reflections on each verse's plain meaning. They are not tafsir, and they are no substitute for scholars. Every verse page links to the full tafsir on Quran.com, and for rulings on marriage, divorce, or family matters, please consult a qualified scholar you trust.")
                .font(.reading(14))
                .lineSpacing(6)
                .foregroundStyle(Color.sakinaInk.opacity(0.92))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard()
    }

    // MARK: Sync

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsLabel(text: "Your data", color: .sakinaGold)
            Text("Bookmarks and reflections live privately on this device. iCloud sync is prepared in the project and switches on once the app is signed with your Apple developer account. The README explains the steps.")
                .font(.system(size: 12))
                .lineSpacing(4)
                .foregroundStyle(Color.sakinaMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sakinaCard()
    }
}
