import MessageUI
import StoreKit
import SwiftUI
import UIKit

// MARK: - Links and addresses
//
// Everything outward-facing lives here so it can be changed in one place.

enum AppLinks {
    /// Set once the app is live: the numeric id from App Store Connect.
    static let appStoreID = ""
    static let supportEmail = "islamsharaf2005@gmail.com"

    static var appStore: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    static var writeReview: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    static func shareText(_ language: AppLanguage) -> String {
        let line = language.pick(
            "Haneen: du’a, dhikr and Qur’an for how you feel. Prayer times, ruqyah, a dhikr counter and nothing tracked.",
            "حنين: أدعية وأذكار وآيات تناسب ما تشعر به، مع مواقيت الصلاة والرقية وعدّاد الأذكار، بلا تتبّع."
        )
        if let appStore { return line + "\n" + appStore.absoluteString }
        return line
    }
}

// MARK: - FAQ

struct FAQView: View {
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded: Set<Int> = []
    @State private var appeared = false
    private var copy: AppCopy { AppCopy(language: language) }

    private var questions: [(q: String, a: String)] {
        [
            (copy("Is Haneen free?", "هل حنين مجاني؟"),
             copy("Yes. There are no ads, subscriptions or tracking.", "نعم. لا إعلانات ولا اشتراكات ولا تتبع.")),
            (copy("Where does the Qur’an text come from?", "ما مصدر نص القرآن؟"),
             copy("Every ayah is fetched from Quran.com in Uthmani script with the Saheeh International translation, then frozen so it cannot drift.",
                  "نصوص الآيات مأخوذة من Quran.com بالرسم العثماني، مع ترجمة صحيح إنترناشونال. وتُحفظ نسخة ثابتة منها داخل التطبيق.")),
            (copy("Are the du’as authentic?", "هل الأدعية صحيحة؟"),
             copy("Each du’a shows its collection, hadith number and grade, with a link to the source page on Sunnah.com. Excerpts are labelled.",
                  "يُعرض مع كل دعاء مصدره ورقم الحديث ودرجته، مع رابط إلى صفحة المصدر في Sunnah.com. ويُوضَّح ما إذا كان النص مقتطفًا.")),
            (copy("How are prayer times calculated?", "كيف تُحسب مواقيت الصلاة؟"),
             copy("On your iPhone, from your approximate location, using the calculation method you choose in Settings. Nearby-place searches separately share your search location with map providers.",
                  "على جهازك من موقعك التقريبي وبالطريقة التي تختارها في الإعدادات. ويشارك البحث عن الأماكن القريبة موقع البحث مع مزودي الخرائط بشكل منفصل.")),
            (copy("Why does a mosque or restaurant look wrong?", "لماذا قد تكون بيانات مسجد أو مطعم غير صحيحة؟"),
             copy("Nearby places come from Apple Maps and OpenStreetMap. Places found in both are marked. Always confirm halal status with the restaurant, and use Report a problem to fix the map data.",
                  "تأتي بيانات الأماكن القريبة من خرائط Apple وOpenStreetMap، وتُميَّز الأماكن المذكورة في المصدرين معًا. تأكد من المطعم أن الطعام حلال، واستخدم خيار الإبلاغ عن مشكلة لتصحيح البيانات.")),
            (copy("Does the app work offline?", "هل يعمل التطبيق دون اتصال؟"),
             copy("Du’as, Qur’an, prayer times and the dhikr counter all work offline. Recitation audio and nearby places need a connection.",
                  "الأدعية والقرآن ومواقيت الصلاة وعداد الذكر تعمل دون اتصال. أما التلاوة الصوتية والأماكن القريبة فتحتاج إلى اتصال.")),
            (copy("How do I add the widget?", "كيف أضيف الأداة؟"),
             copy("Set a location in Settings, then long-press your Home or Lock Screen, tap +, and search for Haneen.",
                  "حدد الموقع في الإعدادات، ثم اضغط مطولًا على الشاشة الرئيسية أو شاشة القفل، واضغط + وابحث عن حنين.")),
            (copy("Is my data backed up?", "هل تُنسخ بياناتي احتياطيًا؟"),
             copy("Not unless you choose to. Saved du’as and reflections stay on this iPhone. Google Drive backup is optional and private to the app.",
                  "لا، إلا إذا اخترت ذلك. تبقى الأدعية المحفوظة والتأملات على هذا الهاتف. والنسخ إلى Google Drive اختياري وخاص بالتطبيق.")),
            (copy("Can I turn off vibrations?", "هل يمكن إيقاف الاهتزاز؟"),
             copy("Yes. Settings → Haptics.", "نعم. الإعدادات ← الاهتزاز.")),
        ]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Questions", "أسئلة شائعة"),
                           subtitle: copy("Short answers. Ask us if yours isn’t here.", "إجابات قصيرة. اسألنا إن لم تجد سؤالك."))
                    .revealed(0, appeared: appeared, reduceMotion: reduceMotion)
                RowGroup {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, item in
                        Button {
                            Haptics.press()
                            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.85)) {
                                if expanded.contains(index) { expanded.remove(index) } else { expanded.insert(index) }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(item.q)
                                        .font(.yqBodyMedium)
                                        .foregroundStyle(Color.yqInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.yqTertiary)
                                        .rotationEffect(.degrees(expanded.contains(index) ? 180 : 0))
                                }
                                if expanded.contains(index) {
                                    Text(item.a)
                                        .font(.yqSubhead)
                                        .lineSpacing(4)
                                        .foregroundStyle(Color.yqSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityValue(expanded.contains(index) ? copy("Expanded", "موسّع") : copy("Collapsed", "مطوي"))
                        if index < questions.count - 1 { RowDivider(inset: 16) }
                    }
                }
                .revealed(1, appeared: appeared, reduceMotion: reduceMotion)

                NavigationLink { ContactSupportView(language: language) } label: {
                    SecondaryButton(title: copy("Still stuck? Contact us", "ما زلت محتارًا؟ تواصل معنا"), symbol: "envelope.fill")
                }
                .buttonStyle(.yqPress)
                .revealed(2, appeared: appeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }
}

// MARK: - Contact support

struct ContactSupportView: View {
    let language: AppLanguage
    @Environment(\.openURL) private var openURL
    @State private var topic: Topic = .problem
    @State private var message = ""
    @State private var showComposer = false
    @State private var sent = false
    @FocusState private var focused: Bool
    private var copy: AppCopy { AppCopy(language: language) }

    enum Topic: String, CaseIterable, Identifiable {
        case problem, idea, content, other
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .problem: return "ladybug.fill"
            case .idea: return "lightbulb.fill"
            case .content: return "text.badge.checkmark"
            case .other: return "bubble.left.fill"
            }
        }
        func title(_ language: AppLanguage) -> String {
            switch self {
            case .problem: return language.pick("Something’s broken", "شيء لا يعمل")
            case .idea: return language.pick("An idea", "فكرة")
            case .content: return language.pick("A correction to a du’a or ayah", "تصحيح في دعاء أو آية")
            case .other: return language.pick("Something else", "شيء آخر")
            }
        }
    }

    private var subject: String { "Haneen, \(topic.title(.english))" }
    private var trimmed: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var messageBody: String {
        let device = UIDevice.current
        return """
        \(message)

        —
        Haneen \(AppLinks.version), iOS \(device.systemVersion), \(device.model), \(language.rawValue)
        """
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: copy("Contact us", "تواصل معنا"),
                           subtitle: copy("A real person reads every message.", "يقرأ رسالتك إنسان حقيقي."))

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(copy("What is it about?", "بم يتعلق الأمر؟"))
                    RowGroup {
                        ForEach(Array(Topic.allCases.enumerated()), id: \.element.id) { index, item in
                            Button {
                                Haptics.selection()
                                topic = item
                            } label: {
                                BadgeRow(symbol: item.symbol, title: item.title(language)) {
                                    Image(systemName: topic == item ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(topic == item ? Color.yqAccent : Color.yqHairline)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            .buttonStyle(.yqPressSoft)
                            if index < Topic.allCases.count - 1 { RowDivider() }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(copy("Your message", "رسالتك"))
                    TextEditor(text: $message)
                        .focused($focused)
                        .font(.yqBody)
                        .foregroundStyle(Color.yqInk)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        .padding(12)
                        .yqCard(cornerRadius: 16)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text(copy("What happened, and what did you expect?", "ما الذي حدث، وما الذي كنت تتوقعه؟"))
                                    .font(.yqBody)
                                    .foregroundStyle(Color.yqTertiary)
                                    .padding(20)
                                    .allowsHitTesting(false)
                            }
                        }
                    Text(copy("We attach the app version and iOS version so we can reproduce the issue. Nothing else.",
                              "نرفق إصدار التطبيق ونظام iOS للمساعدة في معرفة سبب المشكلة، دون أي معلومات أخرى."))
                        .font(.yqCaption)
                        .foregroundStyle(Color.yqSecondary)
                }

                Button {
                    focused = false
                    Haptics.thud()
                    if MFMailComposeViewController.canSendMail() {
                        showComposer = true
                    } else {
                        openMailto()
                    }
                } label: {
                    PrimaryButton(title: copy("Send", "إرسال"), symbol: "paperplane.fill")
                }
                .buttonStyle(.yqPress)
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.5 : 1)

                if sent {
                    Label(copy("Thank you. We’ll reply by email.", "شكرًا لك. سنرد عبر البريد."), systemImage: "checkmark.circle.fill")
                        .font(.yqSubheadMedium)
                        .foregroundStyle(Color.yqAccentDeep)
                }

                Text(copy("Or email \(AppLinks.supportEmail) directly.", "أو راسل \(AppLinks.supportEmail) مباشرة."))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showComposer) {
            MailComposer(to: AppLinks.supportEmail, subject: subject, body: messageBody) { result in
                if result == .sent { sent = true; Haptics.success() }
            }
            .ignoresSafeArea()
        }
    }

    private func openMailto() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppLinks.supportEmail
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: messageBody)]
        if let url = components.url {
            openURL(url)
            sent = true
        }
    }
}

private struct MailComposer: UIViewControllerRepresentable {
    let to: String
    let subject: String
    let body: String
    let completion: (MFMailComposeResult) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([to])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposer
        init(parent: MailComposer) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.completion(result)
            parent.dismiss()
        }
    }
}

// MARK: - About us

struct AboutUsView: View {
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 14) {
                    YaqeenBrandIcon(size: 92)
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("حنين").font(.arabicProse(30))
                            Text("Haneen").font(.yqTitle)
                        }
                        .foregroundStyle(Color.yqInk)
                        Text(copy("Qur’an and du’a for how you feel", "آيات وأدعية تناسب ما تشعر به"))
                            .font(.yqSubheadMedium)
                            .foregroundStyle(Color.yqSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .revealed(0, appeared: appeared, reduceMotion: reduceMotion)

                storyCard(
                    symbol: "heart.fill",
                    title: copy("Why we made it", "لماذا أنشأنا حنين"),
                    body: copy(
                        "Most of us don’t open a du’a book when the day gets heavy. We open our phone. Haneen meets you there: a feeling, one tap, and words from the Qur’an and the Sunnah that were made for that moment.",
                        "حين تثقل علينا هموم اليوم، يلجأ كثير منا إلى هاتفه. اختر في حنين ما تشعر به لتصل بضغطة واحدة إلى آيات وأدعية من القرآن والسنة تناسب حالك."
                    )
                )
                .revealed(1, appeared: appeared, reduceMotion: reduceMotion)

                storyCard(
                    symbol: "checkmark.shield.fill",
                    title: copy("What we promise", "ما نعد به"),
                    body: copy(
                        "Every ayah is fetched from Quran.com and frozen. Every hadith shows its collection, number and grade. Nothing you read or write is tracked, sold, or sent anywhere without you choosing it.",
                        "نصوص الآيات مأخوذة من Quran.com ومحفوظة دون تغيير، ويُعرض مع كل حديث مصدره ورقمه ودرجته. ولا نتتبّع ما تقرأه أو تكتبه، ولا نبيعه أو نرسله إلى أي جهة دون اختيارك."
                    )
                )
                .revealed(2, appeared: appeared, reduceMotion: reduceMotion)

                storyCard(
                    symbol: "person.fill",
                    title: copy("Who we are", "من نحن"),
                    body: copy(
                        "Haneen is independently built and shaped by your feedback. If it helps you, tell a friend.",
                        "حنين تطبيق مستقل تسهم ملاحظاتكم في تطويره. إن نفعك، فأخبر صديقًا."
                    )
                )
                .revealed(3, appeared: appeared, reduceMotion: reduceMotion)

                RowGroup {
                    ShareLink(item: AppLinks.shareText(language)) {
                        BadgeRow(symbol: "square.and.arrow.up.fill", title: copy("Share Haneen", "شارك حنين"))
                    }
                    .buttonStyle(.yqPressSoft)
                    RowDivider()
                    NavigationLink { ContactSupportView(language: language) } label: {
                        BadgeRow(symbol: "envelope.fill", title: copy("Write to us", "راسلنا"))
                    }
                    .buttonStyle(.yqPressSoft)
                }
                .revealed(4, appeared: appeared, reduceMotion: reduceMotion)

                Text(copy("Haneen, \(AppLinks.version)", "حنين، \(AppLinks.version)"))
                    .font(.yqCaption)
                    .foregroundStyle(Color.yqTertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .yqScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { appeared = true }
    }

    private func storyCard(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                IconBadge(symbol: symbol, size: 32)
                Text(title).font(.yqHeadline).foregroundStyle(Color.yqInk)
            }
            Text(body)
                .font(.yqSubhead)
                .lineSpacing(5)
                .foregroundStyle(Color.yqSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yqCard(cornerRadius: 20)
    }
}

enum AppRating {
    /// Asks for the native review prompt; falls back to the App Store page when it can’t show one.
    @MainActor static func request(fallback openURL: OpenURLAction) {
        Haptics.thud()
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        } else if let url = AppLinks.writeReview {
            openURL(url)
        }
    }
}
