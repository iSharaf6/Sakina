import AVFoundation
import CoreLocation
import SwiftUI
import UIKit

// MARK: - Flow

/// A calm, first-run setup for the few preferences Yaqeen needs in order to
/// feel useful immediately. Every choice is written through `AppStorage`, so
/// onboarding and Settings always describe the same state.
struct OnboardingFlow: View {
    private enum Step: Int {
        case welcome
        case prayer
        case reminder
        case reading
        case ready
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    @AppStorage(SettingsKeys.reminderEnabled) private var reminderEnabled = true
    @AppStorage(SettingsKeys.reminderHour) private var reminderHour = 9
    @AppStorage(SettingsKeys.reminderMinute) private var reminderMinute = 0
    @AppStorage(SettingsKeys.reciter) private var reciterRaw = Reciter.alafasy.rawValue
    @AppStorage(SettingsKeys.arabicScale) private var arabicScale = 1.0
    @AppStorage(SettingsKeys.prayerCalculationMethod) private var prayerMethodRaw = PrayerCalculationMethod.muslimWorldLeague.rawValue
    @AppStorage(SettingsKeys.prayerAsrMethod) private var prayerAsrRaw = PrayerAsrMethod.standard.rawValue
    @AppStorage(SettingsKeys.prayerHighLatitude) private var highLatitudeRaw = PrayerHighLatitudePreference.automatic.rawValue

    @ObservedObject private var prayerService: PrayerTimesService
    @ObservedObject private var locationService: PrayerLocationService
    @StateObject private var previewPlayer = OnboardingReciterPreview()
    @State private var step: Step = .welcome

    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        let service = PrayerTimesService.shared
        self.onFinish = onFinish
        _prayerService = ObservedObject(wrappedValue: service)
        _locationService = ObservedObject(wrappedValue: service.locationService)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .english
    }

    private var prayerSettings: PrayerCalculationSettings {
        var settings = PrayerCalculationSettings.default
        settings.method = PrayerCalculationMethod(rawValue: prayerMethodRaw) ?? .muslimWorldLeague
        settings.asrMethod = PrayerAsrMethod(rawValue: prayerAsrRaw) ?? .standard
        settings.highLatitudePreference = PrayerHighLatitudePreference(rawValue: highLatitudeRaw) ?? .automatic
        return settings
    }

    var body: some View {
        currentScreen
            .id(step)
            .transition(screenTransition)
            .background { AtmosphereBackground() }
            .yaqeenLanguage(language)
            .animation(stepAnimation, value: step)
            .onDisappear { previewPlayer.stop() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { previewPlayer.stop() }
            }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView(
                language: language,
                chooseLanguage: { languageRaw = $0.rawValue },
                onContinue: { go(to: .prayer) }
            )

        case .prayer:
            OnboardingPrayerView(
                language: language,
                prayerService: prayerService,
                locationService: locationService,
                settings: prayerSettings,
                onSkip: { go(to: .ready) },
                onContinue: { go(to: .reminder) }
            )

        case .reminder:
            OnboardingReminderView(
                language: language,
                isEnabled: $reminderEnabled,
                hour: $reminderHour,
                minute: $reminderMinute,
                onSkip: { go(to: .ready) },
                onContinue: { go(to: .reading) }
            )

        case .reading:
            OnboardingReadingView(
                language: language,
                reciterRaw: $reciterRaw,
                arabicScale: $arabicScale,
                previewPlayer: previewPlayer,
                onSkip: { go(to: .ready) },
                onContinue: { go(to: .ready) }
            )

        case .ready:
            OnboardingReadyView(language: language) {
                previewPlayer.stop()
                onFinish()
            }
        }
    }

    private var screenTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 10)),
            removal: .opacity
        )
    }

    private var stepAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .easeOut(duration: 0.46)
    }

    private func go(to newStep: Step) {
        previewPlayer.stop()
        withAnimation(stepAnimation) {
            step = newStep
        }
    }
}

// MARK: - Welcome

private struct OnboardingWelcomeView: View {
    let language: AppLanguage
    let chooseLanguage: (AppLanguage) -> Void
    let onContinue: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        YaqeenMark()
                            .fill(Color.sakinaInk)
                            .frame(width: 66, height: 94)
                            .accessibilityHidden(true)

                        Text(copy("Yaqeen", "يقين"))
                            .font(.display(36))
                            .foregroundStyle(Color.sakinaInk)
                            .padding(.top, 26)

                        Text(copy("يقين", "Yaqeen"))
                            .font(.reading(16))
                            .foregroundStyle(Color.sakinaMuted)
                            .padding(.top, 3)

                        StarDivider()
                            .frame(maxWidth: 142)
                            .padding(.top, 22)

                        Text(copy(
                            "Guidance from the Qur’an, for every season of life.",
                            "هداية من القرآن لكل موسم من مواسم حياتك."
                        ))
                        .font(.reading(18))
                        .foregroundStyle(Color.sakinaMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 280)
                        .padding(.top, 22)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    languageButton(.english)
                    languageButton(.arabic)
                }

                OnboardingPrimaryButton(title: copy("Begin", "ابدأ"), action: onContinue)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 16)
        }
    }

    private func languageButton(_ option: AppLanguage) -> some View {
        let isSelected = language == option
        return Button {
            chooseLanguage(option)
        } label: {
            Text(option.nativeName)
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .foregroundStyle(isSelected ? Color.sakinaCanvas : Color.sakinaInk)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    isSelected ? Color.sakinaInk : Color.sakinaElevated,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.sakinaInk : Color.sakinaHairline,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.yaqeenPressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Prayer times

private struct OnboardingPrayerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    let language: AppLanguage
    @ObservedObject var prayerService: PrayerTimesService
    @ObservedObject var locationService: PrayerLocationService
    let settings: PrayerCalculationSettings
    let onSkip: () -> Void
    let onContinue: () -> Void

    private let prayerKinds: [PrayerKind] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private var copy: AppCopy { AppCopy(language: language) }
    private var isAuthorized: Bool {
        [.authorizedAlways, .authorizedWhenInUse].contains(locationService.authorizationStatus)
    }
    private var hasPrayerTimes: Bool { isAuthorized && prayerService.schedule != nil }
    private var permissionUnavailable: Bool {
        [.denied, .restricted].contains(locationService.authorizationStatus)
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: 1, language: language, onSkip: onSkip)
                .padding(.horizontal, 30)
                .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingIntro(
                        symbol: "location.fill",
                        eyebrow: copy("Prayer times", "أوقات الصلاة"),
                        title: copy("Keep the day’s rhythm.", "حافظ على إيقاع يومك."),
                        body: copy(
                            "Your location calculates accurate prayer times. Yaqeen saves the resulting schedule and city label for widgets, not your coordinates.",
                            "يُستخدم موقعك لحساب أوقات الصلاة بدقة. يحفظ يقين الجدول الناتج واسم المدينة للويدجت، لا إحداثياتك."
                        )
                    )

                    prayerPreview
                        .padding(.top, 24)

                    if let error = prayerService.errorMessage {
                        Label(
                            language.pick(error, "تعذّر تحديد موقعك. يمكنك المحاولة مجددًا أو المتابعة دون تفعيل الموقع."),
                            systemImage: "exclamationmark.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(Color.sakinaMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }

            VStack(spacing: 8) {
                OnboardingPrimaryButton(
                    title: primaryTitle,
                    isLoading: prayerService.isRefreshing,
                    action: primaryAction
                )

                OnboardingSecondaryButton(title: copy("Not now", "ليس الآن"), action: onContinue)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 16)
        }
    }

    private var prayerPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: hasPrayerTimes ? "location.fill" : "location")
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)

                Text(hasPrayerTimes
                     ? copy("Using your current location", "وفق موقعك الحالي")
                     : copy("Enable location to see prayer times", "فعّل الموقع لعرض أوقات الصلاة"))
                    .font(.system(.caption, design: .default, weight: .semibold))
            }
            .foregroundStyle(hasPrayerTimes ? Color.yaqeenForest : Color.sakinaMuted)

            HStack(alignment: .top, spacing: 4) {
                ForEach(prayerKinds) { kind in
                    VStack(spacing: 7) {
                        Image(systemName: onboardingSymbol(for: kind))
                            .font(.system(size: 18, weight: .regular))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(hasPrayerTimes ? Color.yaqeenForest : Color.sakinaMuted.opacity(0.42))
                            .frame(height: 20)

                        Text(kind.displayName(locale: language.locale))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.sakinaMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)

                        Text(time(for: kind))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(hasPrayerTimes ? Color.sakinaInk : Color.sakinaMuted.opacity(0.42))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
            .id(hasPrayerTimes)
            .transition(
                reduceMotion
                    ? .opacity
                    : .opacity.combined(with: .offset(y: 6))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .sakinaCard(cornerRadius: 22)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.34), value: hasPrayerTimes)
    }

    private var primaryTitle: String {
        if hasPrayerTimes { return copy("Continue", "متابعة") }
        if permissionUnavailable { return copy("Open Settings", "فتح الإعدادات") }
        return copy("Enable location", "تفعيل الموقع")
    }

    private func primaryAction() {
        if hasPrayerTimes {
            onContinue()
        } else if permissionUnavailable {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        } else {
            Task {
                await prayerService.refreshUsingCurrentLocation(settings: settings)
            }
        }
    }

    private func time(for kind: PrayerKind) -> String {
        guard hasPrayerTimes,
              let schedule = prayerService.schedule,
              let date = schedule.events(on: .now).first(where: { $0.kind == kind })?.time else {
            return "· ·"
        }

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = schedule.timeZone
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    private func onboardingSymbol(for kind: PrayerKind) -> String {
        switch kind {
        case .fajr: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        case .sunrise: return "sunrise.fill"
        }
    }
}

// MARK: - Reminder

private struct OnboardingReminderView: View {
    @Environment(\.openURL) private var openURL

    let language: AppLanguage
    @Binding var isEnabled: Bool
    @Binding var hour: Int
    @Binding var minute: Int
    let onSkip: () -> Void
    let onContinue: () -> Void

    @State private var isRequestingAuthorization = false
    @State private var authorizationDenied = false

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: 2, language: language, onSkip: onSkip)
                .padding(.horizontal, 30)
                .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingIntro(
                        symbol: "bell",
                        eyebrow: copy("Daily reminder", "تذكير يومي"),
                        title: copy("A gentle word each day.", "كلمة لطيفة كل يوم."),
                        body: copy(
                            "One ayah of guidance, at a time that suits you.",
                            "آيةُ هدايةٍ واحدة، في الوقت الذي يناسبك."
                        )
                    )

                    reminderCard
                        .padding(.top, 24)

                    if authorizationDenied {
                        Label(
                            copy(
                                "Notifications are off. You can allow them in Settings, or continue without reminders.",
                                "الإشعارات متوقفة. يمكنك السماح بها من الإعدادات أو المتابعة دون تذكير."
                            ),
                            systemImage: "bell.slash"
                        )
                        .font(.footnote)
                        .foregroundStyle(Color.sakinaMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }

            VStack(spacing: 8) {
                OnboardingPrimaryButton(
                    title: primaryTitle,
                    isLoading: isRequestingAuthorization,
                    action: enableReminder
                )

                OnboardingSecondaryButton(
                    title: authorizationDenied
                        ? copy("Continue without reminders", "المتابعة دون تذكير")
                        : copy("Maybe later", "لاحقًا")
                ) {
                    isEnabled = false
                    ReminderScheduler.refresh()
                    onContinue()
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 16)
        }
    }

    private var reminderCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.sakinaInk)
                    .accessibilityHidden(true)

                Text(copy("Daily reminder", "التذكير اليومي"))
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(Color.sakinaInk)

                Spacer(minLength: 10)

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(.sakinaInk)
                    .accessibilityLabel(copy("Daily reminder", "التذكير اليومي"))
            }

            Divider()
                .overlay(Color.sakinaHairline)

            HStack(spacing: 12) {
                Text(copy("Remind me at", "ذكّرني عند"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sakinaMuted)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    timeAdjustmentButton(symbol: "minus", change: -15)

                    Text(formattedReminderTime)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(Color.sakinaInk)
                        .monospacedDigit()
                        .frame(minWidth: 104)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    timeAdjustmentButton(symbol: "plus", change: 15)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            .opacity(isEnabled ? 1 : 0.42)
            .allowsHitTesting(isEnabled)
            .animation(.easeInOut(duration: 0.18), value: isEnabled)
        }
        .padding(18)
        .sakinaCard(cornerRadius: 22)
    }

    private var primaryTitle: String {
        if authorizationDenied { return copy("Open Settings", "فتح الإعدادات") }
        return isEnabled
            ? copy("Continue", "متابعة")
            : copy("Turn on reminders", "تفعيل التذكير")
    }

    private func enableReminder() {
        let shouldOpenSettingsIfDenied = authorizationDenied
        isEnabled = true
        isRequestingAuthorization = true

        Task {
            let enabled = await ReminderScheduler.enableAndRefresh()
            isRequestingAuthorization = false

            if enabled {
                authorizationDenied = false
                onContinue()
            } else {
                isEnabled = false
                authorizationDenied = true

                if shouldOpenSettingsIfDenied,
                   let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
        }
    }

    private func timeAdjustmentButton(symbol: String, change: Int) -> some View {
        Button {
            adjustTime(by: change)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.sakinaInk)
                .frame(width: 44, height: 44)
                .background(
                    Color.sakinaCanvas,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.sakinaHairline, lineWidth: 1)
                }
        }
        .buttonStyle(.yaqeenPressable)
        .accessibilityLabel(change < 0
                            ? copy("15 minutes earlier", "قبل 15 دقيقة")
                            : copy("15 minutes later", "بعد 15 دقيقة"))
    }

    private var formattedReminderTime: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    private func adjustTime(by amount: Int) {
        let current = hour * 60 + minute
        let adjusted = min(1_350, max(300, current + amount))
        hour = adjusted / 60
        minute = adjusted % 60
    }
}

// MARK: - Reading

private struct OnboardingReadingView: View {
    let language: AppLanguage
    @Binding var reciterRaw: String
    @Binding var arabicScale: Double
    @ObservedObject var previewPlayer: OnboardingReciterPreview
    let onSkip: () -> Void
    let onContinue: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }
    private var selectedReciter: Reciter {
        Reciter(rawValue: reciterRaw) ?? .alafasy
    }

    private var arabicPointSize: Binding<Double> {
        Binding {
            min(46, max(24, arabicScale * 34))
        } set: { newValue in
            arabicScale = newValue / 34
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: 3, language: language, onSkip: onSkip)
                .padding(.horizontal, 30)
                .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingIntro(
                        symbol: "textformat.size",
                        eyebrow: copy("Reading", "القراءة"),
                        title: copy("Set your reading.", "اضبط قراءتك."),
                        body: copy(
                            "Choose a reciter and a comfortable size for the Arabic.",
                            "اختر القارئ وحجمًا مريحًا للنص العربي."
                        )
                    )

                    CapsLabel(text: copy("Reciter", "القارئ"))
                        .padding(.top, 22)

                    VStack(spacing: 10) {
                        ForEach(Reciter.allCases) { reciter in
                            reciterRow(reciter)
                        }
                    }
                    .padding(.top, 12)

                    CapsLabel(text: copy("Arabic size", "حجم النص العربي"))
                        .padding(.top, 26)

                    HStack(spacing: 14) {
                        Text("A")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.sakinaMuted)

                        Slider(value: arabicPointSize, in: 24...46, step: 1)
                            .tint(.sakinaInk)
                            .accessibilityLabel(copy("Arabic text size", "حجم النص العربي"))

                        Text("A")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.sakinaMuted)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.top, 8)

                    ayahPreview
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 18)
            }

            OnboardingReadingFooter(
                title: copy("Continue", "متابعة"),
                action: onContinue
            )
        }
    }

    private func reciterRow(_ reciter: Reciter) -> some View {
        let isSelected = selectedReciter == reciter
        let isPlaying = previewPlayer.playing == reciter
        let isLoading = previewPlayer.loading == reciter

        return HStack(spacing: 14) {
            Button {
                reciterRaw = reciter.rawValue
                previewPlayer.toggle(reciter)
            } label: {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.sakinaInk : Color.sakinaInk.opacity(0.08))

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.sakinaInk)
                    } else if isPlaying {
                        OnboardingEqualizer()
                            .foregroundStyle(Color.sakinaCanvas)
                            .frame(width: 16, height: 15)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.sakinaInk)
                            .offset(x: 1)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.yaqeenPressable)
            .accessibilityLabel(
                isLoading
                    ? copy("Loading reciter preview", "جارٍ تحميل معاينة القارئ")
                    : isPlaying
                        ? copy("Stop preview", "إيقاف المعاينة")
                        : copy("Preview reciter", "معاينة القارئ")
            )

            Button {
                if previewPlayer.playing != nil && previewPlayer.playing != reciter {
                    previewPlayer.stop()
                }
                reciterRaw = reciter.rawValue
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reciterName(reciter))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sakinaInk)
                            .multilineTextAlignment(.leading)

                        Text(reciterDescriptor(reciter))
                            .font(.caption)
                            .foregroundStyle(Color.sakinaMuted)
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.sakinaInk : Color.clear)
                        Circle()
                            .strokeBorder(isSelected ? Color.clear : Color.sakinaHairline, lineWidth: 1.5)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.sakinaCanvas)
                        }
                    }
                    .frame(width: 22, height: 22)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.yaqeenPressable)
            .accessibilityLabel("\(reciterName(reciter)), \(reciterDescriptor(reciter))")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSelected ? Color.sakinaInk : Color.sakinaHairline, lineWidth: isSelected ? 1.5 : 1)
        }
        .animation(.easeInOut(duration: 0.16), value: isSelected)
        .animation(.easeInOut(duration: 0.16), value: isPlaying)
    }

    private var ayahPreview: some View {
        VStack(spacing: 16) {
            Text("أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ")
                .font(.arabic(CGFloat(arabicPointSize.wrappedValue)))
                .foregroundStyle(Color.sakinaInk)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .rightToLeft)

            Divider()
                .overlay(Color.sakinaHairline)
                .frame(maxWidth: 190)

            if language == .english {
                Text("Unquestionably, by the remembrance of Allah hearts are assured.")
                    .font(.reading(14))
                    .foregroundStyle(Color.sakinaMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            CapsLabel(text: copy("Ar-Ra‘d · 13:28 · Excerpt", "الرعد · ٢٨ · مقتطف"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .sakinaCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }

    private func reciterName(_ reciter: Reciter) -> String {
        switch reciter {
        case .alafasy:
            return copy("Mishary Rashid Alafasy", "مشاري راشد العفاسي")
        case .husary:
            return copy("Mahmoud Khalil Al-Husary", "محمود خليل الحصري")
        case .abdulBasit:
            return copy("Abdul Basit Abdus-Samad", "عبد الباسط عبد الصمد")
        }
    }

    private func reciterDescriptor(_ reciter: Reciter) -> String {
        switch reciter {
        case .alafasy:
            return copy("Warm · measured", "دافئ · متزن")
        case .husary:
            return copy("Classic · precise", "كلاسيكي · دقيق")
        case .abdulBasit:
            return copy("Rich · resonant", "ثريّ · رخيم")
        }
    }
}

// MARK: - Ready

private struct OnboardingReadyView: View {
    let language: AppLanguage
    let onFinish: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        YaqeenMark()
                            .fill(Color.sakinaInk)
                            .frame(width: 52, height: 74)
                            .accessibilityHidden(true)

                        Text("بِسْمِ اللَّه")
                            .font(.arabic(32))
                            .foregroundStyle(Color.sakinaInk)
                            .environment(\.layoutDirection, .rightToLeft)
                            .padding(.top, 24)

                        StarDivider()
                            .frame(maxWidth: 136)
                            .padding(.top, 20)

                        Text(copy("You’re ready.", "أنت الآن جاهز."))
                            .font(.display(27))
                            .foregroundStyle(Color.sakinaInk)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)

                        Text(copy(
                            "Start with the part of life you’re in.",
                            "ابدأ بالجانب الذي تعيشه الآن."
                        ))
                        .font(.reading(16))
                        .foregroundStyle(Color.sakinaMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 260)
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 20)
                }
            }

            OnboardingPrimaryButton(
                title: copy("Enter Yaqeen", "ادخل إلى يقين"),
                action: onFinish
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Shared pieces

private struct OnboardingProgressHeader: View {
    let step: Int
    let language: AppLanguage
    let onSkip: () -> Void

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { segment in
                    Capsule(style: .continuous)
                        .fill(segment <= step ? Color.sakinaInk : Color.sakinaHairline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.28), value: step)
                }
            }

            Button(copy("Skip", "تخطّي"), action: onSkip)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.sakinaMuted)
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.yaqeenPressable)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
    }
}

private struct OnboardingIntro: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let detail: String

    init(symbol: String, eyebrow: String, title: String, body: String) {
        self.symbol = symbol
        self.eyebrow = eyebrow
        self.title = title
        self.detail = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Color.sakinaInk)
                .frame(width: 60, height: 60)
                .background(
                    Color.sakinaInk.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .accessibilityHidden(true)

            CapsLabel(text: eyebrow)
                .padding(.top, 22)

            Text(title)
                .font(.display(27))
                .foregroundStyle(Color.sakinaInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)

            Text(detail)
                .font(.reading(16))
                .foregroundStyle(Color.sakinaMuted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320, alignment: .leading)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(Color.sakinaCanvas)
                }
            }
            .font(.system(.headline, design: .default, weight: .semibold))
            .foregroundStyle(Color.sakinaCanvas)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 12)
            .background(
                Color.sakinaInk,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.yaqeenPressable)
        .disabled(isLoading)
    }
}

private struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .default, weight: .semibold))
                .foregroundStyle(Color.sakinaMuted)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.yaqeenPressable)
    }
}

private struct OnboardingReadingFooter: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String
    let action: () -> Void

    var body: some View {
        OnboardingPrimaryButton(title: title, action: action)
            .padding(.horizontal, 30)
            .padding(.top, 14)
            .padding(.bottom, 16)
            .background {
                if reduceTransparency {
                    Color.sakinaCanvas
                } else {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.sakinaCanvas.opacity(0.82)
                }
            }
            .overlay(alignment: .top) {
                Color.sakinaHairline.frame(height: 0.75)
            }
    }
}

private struct OnboardingEqualizer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            bars(at: 0)
        } else {
            TimelineView(.animation(minimumInterval: 0.10)) { context in
                bars(at: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func bars(at time: TimeInterval) -> some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(Color.sakinaCanvas)
                    .frame(
                        width: 2.5,
                        height: reduceMotion
                            ? CGFloat([7, 13, 9, 11][index])
                            : animatedHeight(index: index, time: time)
                    )
            }
        }
    }

    private func animatedHeight(index: Int, time: TimeInterval) -> CGFloat {
        let wave = sin(time * 7.5 + Double(index) * 1.7)
        return 5 + CGFloat((wave + 1) * 4.6)
    }
}

// MARK: - Reciter preview

/// Plays the preview ayah used in the Reading screen. It deliberately owns a
/// separate player so preview state cannot collide with an open guidance page.
@MainActor
private final class OnboardingReciterPreview: ObservableObject {
    @Published private(set) var playing: Reciter?
    @Published private(set) var loading: Reciter?

    private var player: AVPlayer?
    private var activeReciter: Reciter?
    private var endObserver: NSObjectProtocol?
    private var itemStatusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var startupTimeout: Task<Void, Never>?

    func toggle(_ reciter: Reciter) {
        if activeReciter == reciter {
            stop()
            return
        }

        stop()
        guard let url = URL(string: "https://everyayah.com/data/\(reciter.rawValue)/013028.mp3") else {
            return
        }

        let item = AVPlayerItem(url: url)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let player = AVPlayer(playerItem: item)
        self.player = player
        activeReciter = reciter
        loading = reciter

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in self?.stop() }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) {
            [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self, self.activeReciter == reciter else { return }

                switch player.timeControlStatus {
                case .playing:
                    self.startupTimeout?.cancel()
                    self.startupTimeout = nil
                    self.loading = nil
                    self.playing = reciter
                case .waitingToPlayAtSpecifiedRate:
                    self.loading = reciter
                    self.playing = nil
                case .paused:
                    self.playing = nil
                @unknown default:
                    self.stop()
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stop() }
        }

        startupTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled,
                  let self,
                  self.activeReciter == reciter,
                  self.playing != reciter else { return }
            self.stop()
        }

        player.play()
    }

    func stop() {
        activeReciter = nil
        player?.pause()
        player = nil
        startupTimeout?.cancel()
        startupTimeout = nil
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        playing = nil
        loading = nil
    }

    deinit {
        startupTimeout?.cancel()
        itemStatusObservation?.invalidate()
        timeControlObservation?.invalidate()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}
