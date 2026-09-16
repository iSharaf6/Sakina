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
                        HaneenCreatorCard(language: language)
                        HaneenDedicationCard(language: language)
                        trustCard
                        privacyCard
                        fontCredits
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
        .yaqeenLanguage(language)
    }

    private var brand: some View {
        VStack(spacing: 14) {
            YaqeenBrandIcon(size: 96)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("حنين")
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    Text("Haneen")
                        .font(.largeTitle.weight(.semibold))
                }
                .foregroundStyle(Color.sakinaInk)

                Text(copy("Qur’an and du’a for how you feel", "آيات وأدعية تناسب ما تشعر به"))
                    .font(.yqBodyMedium)
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
                "Qur’an passages link to their original references. Du’as and their reported virtues include the supporting narration and its grading, so you can read the source in context.",
                "تجد مع الآيات روابط إلى مصادرها الأصلية، ومع الأدعية وفضائلها الروايات الواردة فيها ودرجاتها، لتتمكن من قراءة كل نص في سياقه."
            )
        )
    }

    private var privacyCard: some View {
        aboutCard(
            symbol: "lock",
            title: copy("Private by default", "الخصوصية أولًا"),
            body: copy(
                "Bookmarks, reflections and prayer preferences stay on this iPhone. Haneen has no ads or behavioural analytics integration. Sign-in and online services process account, request and technical information as described in our privacy policy.",
                "تبقى المحفوظات والتأملات وإعدادات الصلاة على هذا الهاتف. ولا يتضمن حنين إعلانات أو أدوات لتحليل سلوكك داخل التطبيق. وتعالج خدمات تسجيل الدخول والخدمات المتصلة بالإنترنت بيانات الحساب والطلبات والمعلومات التقنية وفق ما توضحه سياسة الخصوصية."
            )
        )
    }

    private var fontCredits: some View {
        aboutCard(
            symbol: "textformat",
            title: copy("Qur’an typography", "خطوط القرآن"),
            body: copy(
                "Hafs fonts by the King Fahd Glorious Qur’an Printing Complex. IndoPak font by Ayman Siddiqui and R. Siddiqua for QuranWBW.com and Quran.com. The original fonts and notices are preserved for Haneen’s charitable use.",
                "خطوط حفص من مجمع الملك فهد لطباعة المصحف الشريف. وخط IndoPak من إعداد Ayman Siddiqui وR. Siddiqua لصالح QuranWBW.com وQuran.com. حُفظت الخطوط الأصلية وإشعاراتها دون تغيير لاستخدامها في حنين بنية الصدقة الجارية."
            )
        )
    }

    private func aboutCard(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.yqSubheadBold)
                .foregroundStyle(Color.sakinaInk)
            Text(body)
                .font(.yqSubhead)
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
            AppShareLink(language: language) {
                sourceRow(copy("Share Haneen", "شارك حنين"), detail: copy("Pass it on", "انشر الخير"))
            }
            Divider().padding(.leading, 46)
            NavigationLink { ContactSupportView(language: language) } label: {
                sourceRow(copy("Feedback & support", "الملاحظات والدعم"), detail: copy("Get in touch", "تواصل معنا"))
            }
            Divider().padding(.leading, 46)
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                sourceRow(copy("Privacy policy", "سياسة الخصوصية"), detail: copy("Read in Haneen", "اقرأها في حنين"))
            }
            Divider().padding(.leading, 46)
            Link(destination: URL(string: "https://quran.com")!) {
                sourceRow(copy("Qur’an text and tafsir", "نص القرآن والتفسير"), detail: "Quran.com")
            }
            Divider().padding(.leading, 46)
            Link(destination: URL(string: "https://sunnah.com")!) {
                sourceRow(copy("Hadith references", "مراجع الحديث"), detail: "Sunnah.com")
            }
            Divider().padding(.leading, 46)
            Link(destination: URL(string: "https://quranwbw.com")!) {
                sourceRow(copy("IndoPak font", "الخط الهندي"), detail: "QuranWBW.com")
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
                .font(.yqBodyMedium)
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
        Text(copy("Haneen, \(AppLinks.version)", "حنين، \(AppLinks.version)"))
            .font(.caption2)
            .foregroundStyle(Color.sakinaMuted)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
