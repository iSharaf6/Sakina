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
                        dedication
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
                "Bookmarks, reflections, and prayer preferences stay on this iPhone unless you deliberately connect a backup option shown in Settings. Prayer coordinates never enter the widget payload. Haneen has no advertising, analytics, or tracking.",
                "تبقى المحفوظات والتأملات وإعدادات الصلاة على هذا الهاتف ما لم تفعّل بنفسك خيار النسخ الاحتياطي المتاح في الإعدادات. ولا تُشارك إحداثيات موقعك مع أداة الصلاة. ولا يستخدم حنين الإعلانات أو التحليلات أو التتبّع."
            )
        )
    }

    private var dedication: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(uiImage: CompanionImage.image(.dedication))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 220)
                .accessibilityHidden(true)

            Text(copy("For those who came before us", "وفاءً لمن سبقونا"))
                .font(.yqSubheadBold)
                .foregroundStyle(Color.sakinaInk)
            Text(copy(
                "Haneen was created with the intention of sadaqah jariyah for my late grandparents, on both my mother’s and father’s sides.",
                "أُنشئ حنين بنية الصدقة الجارية عن أجدادي وجدّاتي المتوفَّين من جهة أمي وأبي."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.sakinaMuted)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)

            Text(copy(
                "May Allah forgive them, have mercy on them, and make the good this app brings a lasting benefit for them. Ameen.",
                "اللهم اغفر لهم وارحمهم، واجعل ما ينفع به هذا التطبيق في ميزان حسناتهم. آمين."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.sakinaInk)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.sakinaHairline, lineWidth: 1))
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
        Text(copy("Haneen, 1.0", "حنين، 1.0"))
            .font(.caption2)
            .foregroundStyle(Color.sakinaMuted)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
