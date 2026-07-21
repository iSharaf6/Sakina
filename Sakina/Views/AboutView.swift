import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        brand
                        trustCard
                        privacyCard
                        careCard
                        links
                        version
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 42)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy("Done", "تم")) { dismiss() }
                }
            }
        }
    }

    private var brand: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color.sakinaInk)
                YaqeenMark()
                    .fill(Color.sakinaCanvas)
                    .padding(20)
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("يقين")
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    Text("Yaqeen")
                        .font(.largeTitle.weight(.semibold))
                }
                .foregroundStyle(Color.sakinaInk)

                Text(copy("Certainty in every step", "يقين في كل خطوة"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.sakinaMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var trustCard: some View {
        aboutCard(
            symbol: "checkmark.shield",
            title: copy("The Qur’an is an amanah", "القرآن أمانة"),
            body: copy(
                "All 71 bundled ayat were machine-compared against Quran.com API v4 on 20 July 2026. The Arabic matches its Uthmani text exactly; the displayed Saheeh International text removes only HTML footnote markers. A frozen checksum guards against accidental glyph changes.",
                "تمت مطابقة الآيات الـ71 المضمّنة آليًا مع Quran.com API v4 بتاريخ 20 يوليو 2026. يطابق النص العربي الرسم العثماني تمامًا، ولا يُحذف من ترجمة Saheeh International المعروضة إلا علامات الحواشي البرمجية. ويحمي فحص ثابت النص من أي تغيير غير مقصود."
            )
        )
    }

    private var privacyCard: some View {
        aboutCard(
            symbol: "lock",
            title: copy("Private by default", "الخصوصية أولًا"),
            body: copy(
                "Bookmarks, reflections, and prayer preferences begin on this iPhone. Prayer coordinates never enter the widget payload. Google backup is optional and uses a private app-data folder after you grant permission.",
                "تبدأ المحفوظات والتأملات وتفضيلات الصلاة على هذا الهاتف. لا تدخل إحداثيات الصلاة في بيانات الأداة. والنسخ الاحتياطي إلى Google اختياري ويستخدم مساحة خاصة بعد موافقتك."
            )
        )
    }

    private var careCard: some View {
        aboutCard(
            symbol: "heart.text.square",
            title: copy("Guidance, with context", "هداية مع حفظ السياق"),
            body: copy(
                "Yaqeen distinguishes direct source context from a general principle. It never treats forgiveness as permission for harm, or patience as a reason to remain unsafe. Reflections are not tafsir or a substitute for qualified scholarship, safeguarding, or professional care.",
                "يميّز يقين بين سياق النص المباشر والمبدأ العام. ولا يجعل العفو إذنًا بالضرر، ولا الصبر سببًا للبقاء في الخطر. والتأملات ليست تفسيرًا ولا بديلًا عن أهل العلم أو الحماية أو الرعاية المتخصصة."
            )
        )
    }

    private func aboutCard(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(Color.sakinaInk)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Color.sakinaMuted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }

    private var links: some View {
        VStack(spacing: 0) {
            Link(destination: URL(string: "https://quran.com")!) {
                sourceRow(copy("Qur’an text and tafsir", "نص القرآن والتفسير"), detail: "Quran.com")
            }
            Divider().padding(.leading, 46)
            Link(destination: URL(string: "https://sunnah.com")!) {
                sourceRow(copy("Hadith references", "مراجع الحديث"), detail: "Sunnah.com")
            }
        }
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.sakinaHairline, lineWidth: 1)
        )
    }

    private func sourceRow(_ title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right.square")
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(Color.sakinaMuted)
        }
        .foregroundStyle(Color.sakinaInk)
        .padding(15)
        .contentShape(Rectangle())
    }

    private var version: some View {
        Text("Yaqeen · 1.0")
            .font(.caption2)
            .foregroundStyle(Color.sakinaMuted)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
