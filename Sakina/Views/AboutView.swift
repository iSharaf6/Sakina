import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scholarStore: ScholarContentStore
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    private var scholarProfile: ScholarProfile { scholarStore.profile }

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
                        scholarlyReview
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
            YaqeenBrandIcon(size: 96)

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
                "Bookmarks, reflections, and prayer preferences stay on this iPhone unless you deliberately connect a backup option shown in Settings. Prayer coordinates never enter the widget payload. Yaqeen has no advertising, analytics, or tracking.",
                "تبقى المحفوظات والتأملات وتفضيلات الصلاة على هذا الهاتف ما لم تربط بنفسك خيار نسخ احتياطي يظهر في الإعدادات. ولا تدخل إحداثيات الصلاة في بيانات الأداة. ولا يستخدم يقين الإعلانات أو التحليلات أو التتبع."
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

    private var scholarlyReview: some View {
        NavigationLink {
            ScholarProfileView()
        } label: {
            HStack(spacing: 14) {
                ScholarAvatarView(profile: scholarProfile, size: 58, language: language)

                VStack(alignment: .leading, spacing: 4) {
                    Text(copy("Scholarly review", "المراجعة الشرعية"))
                        .font(.headline)
                        .foregroundStyle(Color.sakinaInk)
                    Text(scholarProfile.displayName(language))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.sakinaInk)
                    if let title = scholarProfile.title(language) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(Color.sakinaMuted)
                    }
                    Label(scholarTrustText, systemImage: scholarTrustSymbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.sakinaMuted)
                }

                Spacer(minLength: 8)
                Image(systemName: language == .arabic ? "chevron.left" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.sakinaMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sakinaElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.sakinaHairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            scholarStore.isShowingLocalPlaceholder
                ? copy(
                    "Opens local placeholder details that are not verified online",
                    "يفتح بيانات محلية مؤقتة غير موثّقة عبر الإنترنت"
                )
                : copy("Opens the verified public scholar profile", "يفتح الملف العام الموثّق للمراجع")
        )
    }

    private var scholarTrustText: String {
        switch scholarStore.profileSource {
        case .localPlaceholder:
            return copy("Local placeholder · unverified", "عنصر محلي مؤقت · غير موثّق")
        case .cachedVerified:
            return copy("Previously verified · saved", "سبق توثيقه · محفوظ")
        case .liveVerified:
            return copy("Verified public profile", "ملف عام موثّق")
        }
    }

    private var scholarTrustSymbol: String {
        scholarStore.isShowingLocalPlaceholder ? "exclamationmark.circle" : "checkmark.seal.fill"
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
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                sourceRow(copy("Privacy policy", "سياسة الخصوصية"), detail: copy("Read in Yaqeen", "اقرأها في يقين"))
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
