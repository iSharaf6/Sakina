import SwiftUI
import UserNotifications

/// All requests are local. Prayer alerts use calculated instants, never a repeating
/// clock time, because prayer times change each day and when the user travels.
enum CompanionReminderPlan {
    static let prayerKey = "reminders.prayers"
    static let morningKey = "reminders.morning"
    static let eveningKey = "reminders.evening"
    static let soundKey = "reminders.sound"
    static let quietStartKey = "reminders.quietStart"
    static let quietEndKey = "reminders.quietEnd"
    static let prefix = "yaqeen."

    struct Item {
        let id: String
        let title: String
        let body: String
        let destination: String
        let components: DateComponents
        let repeats: Bool
        let prayer: Bool
    }

    static func isQuiet(_ hour: Int, start: Int, end: Int) -> Bool {
        if start == end { return false }
        return start < end ? (start..<end).contains(hour) : hour >= start || hour < end
    }

    static func make(defaults: UserDefaults = .standard, schedule: PrayerSchedule?, now: Date = .now) -> [Item] {
        let arabic = defaults.string(forKey: SettingsKeys.appLanguage) == "ar"
        func text(_ en: String, _ ar: String) -> String { arabic ? ar : en }
        let quietStart = defaults.object(forKey: quietStartKey) as? Int ?? 22
        let quietEnd = defaults.object(forKey: quietEndKey) as? Int ?? 7
        func allowedHour(_ hour: Int) -> Int { isQuiet(hour, start: quietStart, end: quietEnd) ? quietEnd : hour }
        var items: [Item] = []
        if defaults.bool(forKey: SettingsKeys.reminderEnabled) {
            let titles = ["A little room for reflection", "One ayah. A fresh perspective.", "Pause here for a moment", "Something to carry into today", "Your quiet corner is here", "A moment for your heart", "Begin again, gently"]
            let arabicTitles = ["فسحة للتأمل", "آية تفتح لك أفقًا جديدًا", "خذ لحظة للهدوء", "تأمل يرافق يومك", "ركنك للهدوء بانتظارك", "لحظة لقلبك", "ابدأ من جديد برفق"]
            let hour = allowedHour(defaults.object(forKey: SettingsKeys.reminderHour) as? Int ?? 9)
            let minute = defaults.integer(forKey: SettingsKeys.reminderMinute)
            for day in 1...7 {
                items.append(Item(id: "yaqeen.guidance.\(day)", title: text(titles[day - 1], arabicTitles[day - 1]),
                                  body: text("An ayah and a small reflection are waiting in Haneen.", "آية وتأمل قصير بانتظارك في حنين."),
                                  destination: "haneen://daily", components: DateComponents(hour: hour, minute: minute, weekday: day), repeats: true, prayer: false))
            }
        }
        for (key, hour, collection, title, body) in [
            (morningKey, 8, "morning", text("Meet the morning with dhikr", "ابدأ صباحك بالذكر"), text("A few quiet minutes for your morning adhkar.", "دقائق هادئة لأذكار الصباح.")),
            (eveningKey, 18, "evening", text("Let the day soften", "مساء يطمئن فيه القلب"), text("Your evening adhkar are here when you’re ready.", "أذكار المساء بانتظارك حين تكون مستعدًا."))
        ] where defaults.bool(forKey: key) {
            items.append(Item(id: "yaqeen.\(collection)", title: title, body: body, destination: "haneen://collection/\(collection)",
                              components: DateComponents(hour: allowedHour(hour), minute: 0), repeats: true, prayer: false))
        }
        if defaults.bool(forKey: prayerKey), let schedule {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            for event in schedule.allEvents where event.kind != .sunrise && event.time > now && event.time < schedule.expiresAt {
                let name = event.kind.displayName(locale: Locale(identifier: arabic ? "ar" : "en"))
                var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: event.time)
                components.timeZone = calendar.timeZone
                items.append(Item(id: "yaqeen.prayer.\(Int(event.time.timeIntervalSince1970))", title: text("It’s time for \(name)", "حان وقت صلاة \(name)"),
                                  body: schedule.locationLabel, destination: "haneen://prayer-times", components: components, repeats: false, prayer: true))
            }
        }
        return Array(items.prefix(60)) // Reserve room below iOS's pending-request limit for snoozes.
    }
}

@MainActor
final class ReminderCenter: ObservableObject {
    static let shared = ReminderCenter()
    @Published var status: UNAuthorizationStatus = .notDetermined
    @Published var error: String?
    private var schedulingTask: Task<Void, Never>?

    func refreshStatus() async { status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus }

    func enablePermissions() async {
        do { _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
        catch { self.error = error.localizedDescription }
        await refreshStatus()
        refresh()
    }

    func refresh() {
        schedulingTask?.cancel()
        schedulingTask = Task {
            let center = UNUserNotificationCenter.current()
            await refreshStatus()
            guard !Task.isCancelled else { return }
            let requests = await center.pendingNotificationRequests()
            guard !Task.isCancelled else { return }
            let plan = CompanionReminderPlan.make(schedule: SharedStore.prayerSchedule)
            let owned = requests.map(\.identifier).filter {
                ($0.hasPrefix("yaqeen.") || $0.hasPrefix("sakinaDaily")) && ($0 != "yaqeen.snooze" || plan.isEmpty)
            }
            center.removePendingNotificationRequests(withIdentifiers: owned)
            guard status == .authorized || status == .provisional else { return }
            let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "en") ?? .english
            let open = UNNotificationAction(identifier: "open", title: language.pick("Open Haneen", "افتح حنين"), options: .foreground)
            let later = UNNotificationAction(identifier: "later", title: language.pick("In 10 minutes", "بعد ١٠ دقائق"), options: [])
            center.setNotificationCategories([UNNotificationCategory(identifier: "companion", actions: [open, later], intentIdentifiers: [])])
            for item in plan {
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = item.title
                content.body = item.body
                content.userInfo = ["destination": item.destination]
                content.categoryIdentifier = "companion"
                content.threadIdentifier = item.prayer ? "prayers" : "moments"
                content.interruptionLevel = item.prayer ? .active : .passive
                if UserDefaults.standard.bool(forKey: CompanionReminderPlan.soundKey) { content.sound = .default }
                do { try await center.add(UNNotificationRequest(identifier: item.id, content: content,
                            trigger: UNCalendarNotificationTrigger(dateMatching: item.components, repeats: item.repeats))) }
                catch { self.error = error.localizedDescription }
            }
        }
    }
}

struct ReminderSettingsView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private func copy(_ english: String, _ arabic: String) -> String { language.pick(english, arabic) }
    @ObservedObject private var center = ReminderCenter.shared
    @AppStorage(SettingsKeys.reminderEnabled) private var daily = false
    @AppStorage(SettingsKeys.reminderHour) private var hour = 9
    @AppStorage(SettingsKeys.reminderMinute) private var minute = 0
    @AppStorage(CompanionReminderPlan.prayerKey) private var prayers = false
    @AppStorage(CompanionReminderPlan.morningKey) private var morning = false
    @AppStorage(CompanionReminderPlan.eveningKey) private var evening = false
    @AppStorage(CompanionReminderPlan.soundKey) private var sound = false
    @AppStorage(CompanionReminderPlan.quietStartKey) private var quietStart = 22
    @AppStorage(CompanionReminderPlan.quietEndKey) private var quietEnd = 7
    @Environment(\.openURL) private var openURL
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    CompanionIllustration(artwork: .reminder, size: 80)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(copy("A rhythm that fits you", "تذكيرات تناسب يومك")).font(.yqTitle2)
                        Text(copy("Choose the moments you want to make room for.", "اختر ما تريد أن تخصّص له وقتًا في يومك.")).font(.yqSubhead).foregroundStyle(Color.yqSecondary)
                    }
                }
                if center.status == .notDetermined {
                    Button(copy("Allow notifications", "السماح بالإشعارات")) { Task { await center.enablePermissions() } }.buttonStyle(.borderedProminent)
                } else if center.status == .denied {
                    Button(copy("Enable notifications in iPhone Settings", "فعّل الإشعارات من إعدادات iPhone")) { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                }
                RowGroup {
                    Toggle(copy("Daily reflection", "تأمل يومي"), isOn: $daily).padding(16)
                    if daily {
                        DatePicker(copy("Your time", "الوقت المناسب لك"), selection: Binding(get: { Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now }, set: {
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: $0); hour = parts.hour ?? 9; minute = parts.minute ?? 0
                        }), displayedComponents: .hourAndMinute).padding(16)
                    }
                    RowDivider(inset: 16)
                    Toggle(copy("Morning adhkar, 8 am", "أذكار الصباح، ٨ صباحًا"), isOn: $morning).padding(16)
                    RowDivider(inset: 16)
                    Toggle(copy("Evening adhkar, 6 pm", "أذكار المساء، ٦ مساءً"), isOn: $evening).padding(16)
                    RowDivider(inset: 16)
                    Toggle(copy("The five daily prayers", "الصلوات الخمس"), isOn: $prayers).padding(16)
                }
                Text(copy("Prayer alerts follow your saved location and calculation method, including Fajr. Open Haneen at least weekly to refresh the coming days. Sunrise is shown in widgets but doesn’t send an adhan alert.", "تُحدَّد تنبيهات الصلاة، بما فيها الفجر، بحسب موقعك المحفوظ وطريقة الحساب التي اخترتها. افتح حنين مرة أسبوعيًا على الأقل لتحديث مواقيت الأيام القادمة. يظهر موعد الشروق في الأدوات دون إرسال تنبيه للأذان."))
                    .font(.yqCaption).foregroundStyle(Color.yqSecondary)
                if prayers && SharedStore.prayerSchedule == nil { Text(copy("Set your prayer location in Settings to schedule prayer alerts.", "حدّد موقعك في إعدادات الصلاة لتفعيل تنبيهاتها.")).foregroundStyle(Color.yqAccentDeep) }
                RowGroup {
                    Toggle(copy("Notification sound", "صوت الإشعارات"), isOn: $sound).padding(16)
                    RowDivider(inset: 16)
                    Picker(copy("Quiet hours begin", "بداية ساعات الهدوء"), selection: $quietStart) { ForEach(0..<24) { Text(hourLabel($0)).tag($0) } }.padding(16)
                    Picker(copy("Quiet hours end", "نهاية ساعات الهدوء"), selection: $quietEnd) { ForEach(0..<24) { Text(hourLabel($0)).tag($0) } }.padding(16)
                }
                Text(copy("Reflections and adhkar move to the end of quiet hours. Prayer alerts stay at the prayer time. Sound uses your iPhone’s notification tone.", "تُؤجَّل تذكيرات التأمل والأذكار إلى نهاية ساعات الهدوء. وتبقى تنبيهات الصلاة في مواعيدها، ويُستخدم صوت الإشعارات المحدّد على iPhone.")).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                if let error = center.error { Text(error).font(.yqCaption).foregroundStyle(.red) }
            }.padding(20)
        }.yqScreen().navigationTitle(copy("Your reminders", "تذكيراتك")).navigationBarTitleDisplayMode(.inline)
            .yaqeenLanguage(language)
            .task { await center.refreshStatus() }
            .onChange(of: [daily, prayers, morning, evening, sound]) { _, _ in center.refresh() }
            .onChange(of: [hour, minute, quietStart, quietEnd]) { _, _ in center.refresh() }
    }

    private func hourLabel(_ value: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(from: DateComponents(hour: value, minute: 0)) ?? .now
        return formatter.string(from: date)
    }
}
