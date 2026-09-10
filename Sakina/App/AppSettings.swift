import Foundation
import UserNotifications

// MARK: Reciters

/// A recitation available from the everyayah.com CDN. `rawValue` is the CDN
/// folder and is exactly what `SettingsKeys.reciter` stores, so the catalog
/// can grow without migrating anybody's saved choice.
///
/// Every folder here answered HTTP 200 for `001001.mp3` when the list was
/// assembled. Names follow the reciters' own commonly published spellings.
struct Reciter: Identifiable, Hashable {
    /// The everyayah folder, e.g. "Alafasy_128kbps".
    let rawValue: String
    let displayName: String
    let arabicName: String
    /// "Murattal" (measured), "Mujawwad" (melodic) or "Muallim" (teaching).
    let style: String
    /// Encoded bitrate in kbps; a rough guide to download size per ayah.
    let bitrate: Int

    var id: String { rawValue }

    private init(_ rawValue: String, _ displayName: String, _ arabicName: String,
                 style: String = "Murattal", bitrate: Int) {
        self.rawValue = rawValue
        self.displayName = displayName
        self.arabicName = arabicName
        self.style = style
        self.bitrate = bitrate
    }

    /// Looks the folder up in the catalog; nil for a folder we no longer ship.
    init?(rawValue: String) {
        guard let match = Reciter.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        self = match
    }

    func name(_ language: AppLanguage) -> String {
        language == .arabic ? arabicName : displayName
    }

    /// The three original choices keep their folders so saved settings survive.
    static let alafasy = Reciter("Alafasy_128kbps", "Mishary Rashid Alafasy", "مشاري راشد العفاسي", bitrate: 128)
    static let husary = Reciter("Husary_128kbps", "Mahmoud Khalil Al-Husary", "محمود خليل الحصري", bitrate: 128)
    static let abdulBasit = Reciter("Abdul_Basit_Murattal_192kbps", "Abdul Basit Abdus-Samad", "عبد الباسط عبد الصمد", bitrate: 192)

    static let allCases: [Reciter] = [
        // Murattal
        alafasy,
        husary,
        abdulBasit,
        Reciter("Abdurrahmaan_As-Sudais_192kbps", "Abdur-Rahman As-Sudais", "عبد الرحمن السديس", bitrate: 192),
        Reciter("Saood_ash-Shuraym_128kbps", "Saud Ash-Shuraim", "سعود الشريم", bitrate: 128),
        Reciter("MaherAlMuaiqly128kbps", "Maher Al-Muaiqly", "ماهر المعيقلي", bitrate: 128),
        Reciter("Minshawy_Murattal_128kbps", "Mohamed Siddiq Al-Minshawi", "محمد صديق المنشاوي", bitrate: 128),
        Reciter("Hudhaify_128kbps", "Ali Al-Hudhaify", "علي الحذيفي", bitrate: 128),
        Reciter("Abu_Bakr_Ash-Shaatree_128kbps", "Abu Bakr Ash-Shatri", "أبو بكر الشاطري", bitrate: 128),
        Reciter("ahmed_ibn_ali_al_ajamy_128kbps", "Ahmed Al-Ajmi", "أحمد بن علي العجمي", bitrate: 128),
        Reciter("Hani_Rifai_192kbps", "Hani Ar-Rifai", "هاني الرفاعي", bitrate: 192),
        Reciter("Yasser_Ad-Dussary_128kbps", "Yasser Ad-Dossari", "ياسر الدوسري", bitrate: 128),
        Reciter("Nasser_Alqatami_128kbps", "Nasser Al-Qatami", "ناصر القطامي", bitrate: 128),
        Reciter("Ghamadi_40kbps", "Saad Al-Ghamdi", "سعد الغامدي", bitrate: 40),
        Reciter("Muhammad_Ayyoub_128kbps", "Muhammad Ayyub", "محمد أيوب", bitrate: 128),
        Reciter("Muhammad_Jibreel_128kbps", "Muhammad Jibreel", "محمد جبريل", bitrate: 128),
        Reciter("Mohammad_al_Tablaway_128kbps", "Mohammad At-Tablawi", "محمد الطبلاوي", bitrate: 128),
        Reciter("Abdullah_Basfar_192kbps", "Abdullah Basfar", "عبد الله بصفر", bitrate: 192),
        Reciter("Muhsin_Al_Qasim_192kbps", "Muhsin Al-Qasim", "محسن القاسم", bitrate: 192),
        Reciter("Abdullaah_3awwaad_Al-Juhaynee_128kbps", "Abdullah Awad Al-Juhani", "عبد الله عواد الجهني", bitrate: 128),
        Reciter("Salaah_AbdulRahman_Bukhatir_128kbps", "Salah Bukhatir", "صلاح بوخاطر", bitrate: 128),
        Reciter("Ali_Jaber_64kbps", "Ali Jaber", "علي جابر", bitrate: 64),
        Reciter("Fares_Abbad_64kbps", "Fares Abbad", "فارس عباد", bitrate: 64),
        Reciter("khalefa_al_tunaiji_64kbps", "Khalifa At-Tunaiji", "خليفة الطنيجي", bitrate: 64),
        Reciter("Ayman_Sowaid_64kbps", "Ayman Suwaid", "أيمن سويد", bitrate: 64),
        Reciter("Yaser_Salamah_128kbps", "Yaser Salamah", "ياسر سلامة", bitrate: 128),
        Reciter("Sahl_Yassin_128kbps", "Sahl Yassin", "سهل ياسين", bitrate: 128),
        Reciter("Akram_AlAlaqimy_128kbps", "Akram Al-Alaqimi", "أكرم العلاقمي", bitrate: 128),
        Reciter("Ibrahim_Akhdar_32kbps", "Ibrahim Al-Akhdar", "إبراهيم الأخضر", bitrate: 32),
        Reciter("mahmoud_ali_al_banna_32kbps", "Mahmoud Ali Al-Banna", "محمود علي البنا", bitrate: 32),
        // Mujawwad
        Reciter("Abdul_Basit_Mujawwad_128kbps", "Abdul Basit Abdus-Samad", "عبد الباسط عبد الصمد", style: "Mujawwad", bitrate: 128),
        Reciter("Minshawy_Mujawwad_192kbps", "Mohamed Siddiq Al-Minshawi", "محمد صديق المنشاوي", style: "Mujawwad", bitrate: 192),
        Reciter("Mustafa_Ismail_48kbps", "Mustafa Ismail", "مصطفى إسماعيل", style: "Mujawwad", bitrate: 48),
        // Muallim
        Reciter("Husary_Muallim_128kbps", "Mahmoud Khalil Al-Husary", "محمود خليل الحصري", style: "Muallim", bitrate: 128),
    ]
}

// MARK: Settings keys

enum SettingsKeys {
    static let reciter = "reciterFolder"
    static let arabicScale = "arabicScale"
    static let appLanguage = "appLanguage"
    static let translationVisible = "translationVisible"
    static let transliterationVisible = "transliterationVisible"
    static let prayerCalculationMethod = "prayerCalculationMethod"
    static let prayerAsrMethod = "prayerAsrMethod"
    static let prayerHighLatitude = "prayerHighLatitude"
    static let reminderEnabled = "reminderEnabled"
    static let reminderHour = "reminderHour"
    static let reminderMinute = "reminderMinute"
}

// MARK: Notification routing

/// Receives notification taps and publishes the situation to open.
final class NotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    @Published var pendingSituationID: String?

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let storedID = response.notification.request.content.userInfo["situationID"] as? String
        // Repeating reminders cannot carry a different payload each day, so
        // resolve the daily reading at the moment the person returns.
        let id = storedID ?? SharedStore.situationOfTheDay().id
        Task { @MainActor in
            self.pendingSituationID = id
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // The app already shows the daily moment. Avoid interrupting somebody
        // who is actively reading it with a second banner and sound.
        completionHandler([])
    }
}

// MARK: Daily reminder

/// Schedules one durable, quiet daily invitation. A repeating calendar trigger
/// keeps working even when the app has not been launched recently.
enum ReminderScheduler {
    private static let identifier = "yaqeen.daily-guidance"

    static func refresh() {
        let defaults = UserDefaults.standard
        let center = UNUserNotificationCenter.current()
        let legacyIDs = (0..<7).map { "sakinaDaily\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: legacyIDs + [identifier])

        guard defaults.bool(forKey: SettingsKeys.reminderEnabled) else { return }
        let hour = defaults.object(forKey: SettingsKeys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: SettingsKeys.reminderMinute) as? Int ?? 0
        let language = AppLanguage(
            rawValue: defaults.string(forKey: SettingsKeys.appLanguage) ?? AppLanguage.english.rawValue
        ) ?? .english

        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert])) ?? false
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = language.pick("A quiet moment with the Qur’an", "لحظة هادئة مع القرآن")
            content.body = language.pick(
                "Your daily Yaqeen guidance is ready whenever you are.",
                "هداية يقين اليومية بانتظارك متى كنت مستعدًا."
            )
            content.interruptionLevel = .passive
            content.userInfo = ["openDaily": true]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: hour, minute: minute),
                repeats: true
            )
            try? await center.add(UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            ))
        }
    }
}
