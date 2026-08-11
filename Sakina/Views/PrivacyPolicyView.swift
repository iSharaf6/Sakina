import SwiftUI

struct PrivacyPolicyView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    policyHeader
                    section(
                        symbol: "hand.raised",
                        title: copy("The short version", "الخلاصة"),
                        body: copy(
                            "Yaqeen has no advertising, analytics, cross-app tracking, or sale of personal data. Your bookmarks, reflections, and preferences are local by default.",
                            "لا يستخدم يقين الإعلانات أو التحليلات أو التتبع بين التطبيقات، ولا يبيع البيانات الشخصية. وتبقى محفوظاتك وتأملاتك وتفضيلاتك على جهازك افتراضيًا."
                        )
                    )
                    section(
                        symbol: "iphone",
                        title: copy("Data on this iPhone", "البيانات على هذا الهاتف"),
                        body: copy(
                            "Bookmarks, written reflections, language, prayer settings, and notification preferences are stored on your device. The prayer widget receives calculated times, a city-level label, and a time zone through Apple’s App Group storage; it never receives your latitude or longitude.",
                            "تُحفظ المحفوظات والتأملات المكتوبة واللغة وإعدادات الصلاة والإشعارات على جهازك. وتتلقى أداة الصلاة الأوقات المحسوبة واسمًا على مستوى المدينة والمنطقة الزمنية عبر مساحة App Group من Apple، ولا تتلقى خط العرض أو خط الطول."
                        )
                    )
                    section(
                        symbol: "location",
                        title: copy("Location and Qibla", "الموقع والقبلة"),
                        body: copy(
                            "Location is requested only after you choose a location-based feature. It is used to calculate prayer times and the Qibla direction. Qibla readings are transient. Prayer calculations happen on device; Apple’s location services may provide the city-level place name. Yaqeen does not retain coordinates in its shared widget data.",
                            "لا يُطلب الموقع إلا بعد اختيارك ميزة تعتمد عليه. ويُستخدم لحساب مواقيت الصلاة واتجاه القبلة. قراءات القبلة مؤقتة، وتتم حسابات الصلاة على الجهاز، وقد توفر خدمات موقع Apple اسم المكان على مستوى المدينة. ولا يحتفظ يقين بالإحداثيات ضمن بيانات الأداة المشتركة."
                        )
                    )
                    section(
                        symbol: "icloud.and.arrow.up",
                        title: copy("Optional backup", "النسخ الاحتياطي الاختياري"),
                        body: copy(
                            "Some configured editions can offer an optional Google sign-in and private Google Drive app-data backup. Nothing is sent unless that option is visible and you choose to connect it. The backup contains bookmarks and reflections, not prayer coordinates. You can disconnect it from Settings.",
                            "قد تتيح بعض الإصدارات المهيأة تسجيلًا اختياريًا عبر Google ونسخة خاصة في مساحة بيانات التطبيق على Google Drive. ولا يُرسل شيء إلا إذا ظهر هذا الخيار واخترت ربطه. وتحتوي النسخة على المحفوظات والتأملات دون إحداثيات الصلاة، ويمكنك فصلها من الإعدادات."
                        )
                    )
                    section(
                        symbol: "network",
                        title: copy("Network services", "خدمات الشبكة"),
                        body: copy(
                            "When configured, Yaqeen reads public verified-scholar profiles and published scholarly insights from Supabase; it does not send your bookmarks, reflections, searches, prayer location, or backup data there. Recitation audio is streamed from EveryAyah. Source links you open may take you to Quran.com, Sunnah.com, or a cited reference. These services receive normal network information and apply their own privacy terms.",
                            "عند تهيئة الخدمة، يقرأ يقين ملفات المراجعين الشرعيين العامة الموثّقة والإضاءات الشرعية المنشورة من Supabase، ولا يرسل إليه محفوظاتك أو تأملاتك أو عمليات البحث أو موقع الصلاة أو بيانات النسخ الاحتياطي. ويُبث صوت التلاوة من EveryAyah. وقد تنقلك روابط المصادر إلى Quran.com أو Sunnah.com أو مرجع مذكور، وتتلقى هذه الخدمات معلومات الشبكة المعتادة وتطبق سياسات الخصوصية الخاصة بها."
                        )
                    )
                    section(
                        symbol: "trash",
                        title: copy("Your choices", "خياراتك"),
                        body: copy(
                            "You can remove bookmarks and reflections in the app, disable notifications in iOS Settings, deny location access, and disconnect any configured backup. Deleting the app removes its local data, subject to your device backups.",
                            "يمكنك حذف المحفوظات والتأملات داخل التطبيق، وتعطيل الإشعارات من إعدادات iOS، ورفض إذن الموقع، وفصل أي نسخة احتياطية مهيأة. ويؤدي حذف التطبيق إلى إزالة بياناته المحلية مع مراعاة نسخ جهازك الاحتياطية."
                        )
                    )

                    Text(copy("Effective 11 August 2026", "سارية من 11 أغسطس 2026"))
                        .font(.caption)
                        .foregroundStyle(Color.sakinaMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
        }
        .navigationTitle(copy("Privacy", "الخصوصية"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var policyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.sakinaInk)
            Text(copy("Privacy, in plain language", "الخصوصية بلغة واضحة"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.sakinaInk)
            Text(copy(
                "This policy describes the data behavior of Yaqeen 1.0.",
                "تصف هذه السياسة طريقة تعامل يقين 1.0 مع البيانات."
            ))
            .font(.subheadline)
            .foregroundStyle(Color.sakinaMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
}
