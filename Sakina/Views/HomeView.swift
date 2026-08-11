import SwiftUI

struct HomeView: View {
    @Binding var path: NavigationPath

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.prayerCalculationMethod) private var prayerMethodRaw = PrayerCalculationMethod.muslimWorldLeague.rawValue
    @AppStorage(SettingsKeys.prayerAsrMethod) private var prayerAsrRaw = PrayerAsrMethod.standard.rawValue
    @AppStorage(SettingsKeys.prayerHighLatitude) private var highLatitudeRaw = PrayerHighLatitudePreference.automatic.rawValue
    @ObservedObject private var prayerService = PrayerTimesService.shared

    private let today = SharedStore.situationOfTheDay()

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var prayerSettings: PrayerCalculationSettings {
        var settings = PrayerCalculationSettings.default
        settings.method = PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muslimWorldLeague
        settings.asrMethod = PrayerAsrMethod(rawValue: prayerAsrRaw) ?? .standard
        settings.highLatitudePreference = PrayerHighLatitudePreference(rawValue: highLatitudeRaw) ?? .automatic
        return settings
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AtmosphereBackground()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 30) {
                        header
                        prayerCard
                        NavigationLink {
                            QiblaView()
                        } label: {
                            QiblaShortcutCard(language: language)
                        }
                        .buttonStyle(YaqeenPressStyle())
                        groups
                        dailyGuidance
                        sourceNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(for: LifeGroup.self) { group in
                LifeGroupView(group: group)
            }
            .navigationDestination(for: Situation.self) { situation in
                SituationDetailView(situation: situation)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            YaqeenMark()
                .fill(Color.sakinaInk)
                .frame(width: 34, height: 46)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Yaqeen")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    Text("يقين")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.sakinaInk.opacity(0.72))
                }
                Text(copy("Certainty in every step", "يقين في كل خطوة"))
                    .font(.caption)
                    .foregroundStyle(Color.sakinaMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                Text(hijriDate)
                    .font(.caption2)
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
    }

    private var hijriDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = language.locale
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: .now)
    }

    // MARK: Prayer times

    @ViewBuilder
    private var prayerCard: some View {
        if let schedule = prayerService.schedule, !schedule.isStale() {
            PrayerHeroCard(
                schedule: schedule,
                language: language,
                isRefreshing: prayerService.isRefreshing,
                refresh: refreshPrayerTimes
            )
        } else {
            PrayerPermissionCard(
                language: language,
                isRefreshing: prayerService.isRefreshing,
                errorMessage: prayerService.errorMessage,
                action: refreshPrayerTimes
            )
        }
    }

    private func refreshPrayerTimes() {
        Task { await prayerService.refreshUsingCurrentLocation(settings: prayerSettings) }
    }

    // MARK: Groups

    private var groups: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionEyebrow(
                title: copy("What do you need today?", "ماذا تحتاج اليوم؟"),
                detail: copy("Choose a life group", "اختر مجموعة")
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 11) {
                    ForEach(GuidanceCatalog.groups) { group in
                        NavigationLink(value: group) {
                            CompactLifeGroupCard(group: group, language: language)
                        }
                        .buttonStyle(YaqeenPressStyle())
                    }
                }
            }
            .contentMargins(.horizontal, 1, for: .scrollContent)
        }
    }

    // MARK: Daily guidance

    private var dailyGuidance: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionEyebrow(
                title: copy("A quiet reminder", "تذكير هادئ"),
                detail: copy("Daily guidance", "هداية اليوم")
            )

            NavigationLink(value: today) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max")
                        Text(copy("AYAH OF THE DAY", "آية اليوم"))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk.opacity(0.72))

                    if let verse = today.primaryVerse {
                        Text(verse.arabic)
                            .font(.arabic(23))
                            .lineSpacing(9)
                            .lineLimit(3)
                            .foregroundStyle(Color.sakinaInk)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                    }

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(today.localizedTitle(language))
                                .font(.headline)
                                .foregroundStyle(Color.sakinaInk)
                                .multilineTextAlignment(.leading)
                            Text(today.referenceLabel)
                                .font(.caption)
                                .foregroundStyle(Color.sakinaMuted)
                        }
                        Spacer(minLength: 12)
                        Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.sakinaInk)
                    }
                }
                .padding(20)
                .sakinaCard(cornerRadius: 24)
            }
            .buttonStyle(YaqeenPressStyle())
        }
    }

    private var sourceNote: some View {
        Text(copy(
            "Qur’an text verified against Quran.com API v4 · Uthmani script",
            "تمت مطابقة النص القرآني مع Quran.com API v4 · بالرسم العثماني"
        ))
        .font(.caption2)
        .foregroundStyle(Color.sakinaMuted)
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.top, 2)
    }
}

// MARK: - Prayer hero

private struct PrayerHeroCard: View {
    let schedule: PrayerSchedule
    let language: AppLanguage
    let isRefreshing: Bool
    let refresh: () -> Void

    private let forest = Color(red: 0.075, green: 0.235, blue: 0.205)
    private let ivory = Color(red: 0.976, green: 0.961, blue: 0.925)
    private let mutedIvory = Color(red: 0.79, green: 0.84, blue: 0.80)

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let events = schedule.events(on: context.date)
            let next = schedule.nextEvent(after: context.date)

            VStack(alignment: .leading, spacing: 21) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy("NEXT PRAYER", "الصلاة القادمة"))
                            .font(.caption2.weight(.bold))
                            .tracking(language == .arabic ? 0 : 1.4)
                            .foregroundStyle(mutedIvory)

                        if let next {
                            HStack(alignment: .firstTextBaseline, spacing: 9) {
                                Text(next.kind.displayName(locale: language.locale))
                                    .font(.title.weight(.semibold))
                                Text(time(next.time))
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(ivory.opacity(0.82))
                            }
                            .foregroundStyle(ivory)

                            Text(countdown(to: next.time, now: context.date))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(mutedIvory)
                        }
                    }

                    Spacer()

                    Image(systemName: next?.kind.symbolName ?? "moon.stars.fill")
                        .font(.system(size: 27, weight: .light))
                        .foregroundStyle(ivory)
                        .symbolRenderingMode(.hierarchical)
                }

                Divider().overlay(ivory.opacity(0.18))

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    spacing: 15
                ) {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.kind.displayName(locale: language.locale))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(event.kind == next?.kind ? ivory : mutedIvory)
                            Text(time(event.time))
                                .font(.subheadline.weight(event.kind == next?.kind ? .bold : .medium))
                                .foregroundStyle(ivory)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(event.kind.displayName(locale: language.locale)), \(time(event.time))")
                    }
                }

                Button(action: refresh) {
                    HStack(spacing: 7) {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(mutedIvory)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(schedule.locationLabel)
                            .lineLimit(1)
                        Spacer()
                        Text(copy("Update", "تحديث"))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(mutedIvory)
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(forest)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(ivory.opacity(0.055))
                            .frame(width: 180, height: 180)
                            .blur(radius: 2)
                            .offset(x: 54, y: -82)
                    }
            )
            .shadow(color: forest.opacity(0.2), radius: 24, y: 13)
            .accessibilityElement(children: .contain)
        }
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = schedule.timeZone
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func countdown(to date: Date, now: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSince(now) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 {
            return copy("in \(hours) hr \(remainder) min", "بعد \(hours) س و\(remainder) د")
        }
        return copy("in \(remainder) min", "بعد \(remainder) دقيقة")
    }
}

private struct PrayerPermissionCard: View {
    let language: AppLanguage
    let isRefreshing: Bool
    let errorMessage: String?
    let action: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(copy("Prayer times, where you are", "مواقيت الصلاة حيث أنت"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.sakinaInk)
                    Text(copy(
                        "Calculated privately on your iPhone. Your coordinates are never shared with the widget.",
                        "تُحسب على جهازك بخصوصية، ولا تُشارك إحداثياتك مع الأداة."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(Color.sakinaMuted)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Image(systemName: "location.viewfinder")
                    .font(.system(size: 25, weight: .light))
                    .foregroundStyle(Color.sakinaInk)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                HStack {
                    if isRefreshing { ProgressView().tint(Color.sakinaCanvas) }
                    Text(isRefreshing
                         ? copy("Finding your city…", "جارٍ تحديد مدينتك…")
                         : copy("Use my location", "استخدم موقعي"))
                    Spacer()
                    Image(systemName: language == .arabic ? "arrow.left" : "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.sakinaCanvas)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(Color.sakinaInk, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(YaqeenPressStyle())
            .disabled(isRefreshing)
        }
        .padding(20)
        .sakinaCard(cornerRadius: 26)
    }
}

private struct CompactLifeGroupCard: View {
    let group: LifeGroup
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: group.symbol)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.sakinaInk)
                .frame(width: 40, height: 40)
                .background(Color.sakinaInk.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(group.title(language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sakinaInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(language.pick("\(group.stages.count) stages", "\(group.stages.count) مراحل"))
                    .font(.caption2)
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
        .padding(15)
        .frame(width: 152, height: 145, alignment: .leading)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }
}

// MARK: - Compatibility motion helpers

struct PressableCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct Revealed: ViewModifier {
    let order: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            .animation(reduceMotion ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: appeared)
    }
}

extension View {
    func revealed(_ order: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        modifier(Revealed(order: order, appeared: appeared, reduceMotion: reduceMotion))
    }
}
