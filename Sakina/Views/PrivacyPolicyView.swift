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
                            "Haneen has no advertising or integration that tracks your reading, feelings or other activity for behavioural analytics. Haneen does not track you across apps or sell personal data. Sign-in and online services separately process the technical information described below.",
                            "لا يعرض حنين إعلانات، ولا يستخدم أدوات تتتبّع قراءتك أو مشاعرك أو نشاطك الآخر لتحليل سلوكك. ولا يتتبّعك عبر التطبيقات أو يبيع بياناتك الشخصية. وتعالج خدمات تسجيل الدخول والخدمات المتصلة بالإنترنت المعلومات التقنية الموضّحة أدناه."
                        )
                    )
                    section(
                        symbol: "iphone",
                        title: copy("Data kept on this iPhone", "بيانات تبقى على هذا الهاتف"),
                        body: copy(
                            "Daily goals, practice completion, dhikr counters, app preferences and saved prayer location remain on this device and are not included in account sync. Your synced library also has a local copy for offline use. Widgets receive the local progress and prayer information needed for their display through Apple's App Group storage. Prayer information includes calculated times, a city-level label and time zone, without latitude or longitude. Device backups are governed by your Apple device settings.\n\nOptional prayer and reflection reminders are scheduled on your device. You can turn them off in Haneen or iOS Settings.",
                            "تبقى أهدافك اليومية وإتمام الأذكار والعدّادات وتفضيلات التطبيق وموقع الصلاة المحفوظ على هذا الجهاز، ولا تشملها مزامنة الحساب. وتوجد أيضًا نسخة محلية من مكتبتك المتزامنة لاستخدامها دون اتصال. وتتلقى الأدوات بيانات التقدّم والصلاة اللازمة للعرض من التخزين المحلي عبر مساحة التخزين المشتركة App Group من Apple. وتشمل بيانات الصلاة المواقيت المحسوبة واسم المدينة والمنطقة الزمنية، دون إحداثيات خط العرض أو خط الطول. وتخضع النسخ الاحتياطية للجهاز لإعدادات جهاز Apple لديك.\n\nتُجدول تذكيرات الصلاة والتأمل الاختيارية على جهازك. ويمكنك إيقافها في حنين أو من إعدادات iOS."
                        )
                    )
                    section(
                        symbol: "person.crop.circle",
                        title: copy("Accounts and sign-in", "الحسابات وتسجيل الدخول"),
                        body: copy(
                            "Apple, Google and email sign-in use Supabase Authentication. Supabase stores your account identifier, email address, display name when supplied, and the account/session information needed for sign-in. Apple and Google provider tokens are sent to Supabase to verify your sign-in. Apple and Google share account information according to the permissions you grant; Haneen does not receive your Apple or Google password. An account is required to use Haneen and keep a library that can be restored on another device. Apple, Google and email are available to new and returning users. After signing in and preparing your library, a cached session allows offline use; account verification and cloud sync need a connection.\n\nAuthentication requests include technical information such as IP addresses and SDK/platform details. Sign-in providers process security and diagnostic information to operate, protect and troubleshoot their services under their own terms. Google states that its sign-in SDK may use a user identifier to record consented access and an IP address to estimate general location for fraud prevention.",
                            "يستخدم تسجيل الدخول عبر Apple أو Google أو البريد الإلكتروني خدمة Supabase Authentication. وتحفظ Supabase معرّف حسابك وبريدك الإلكتروني واسمك المعروض عند إتاحته، ومعلومات الحساب والجلسة اللازمة لتسجيل الدخول. وتُرسل رموز المصادقة الصادرة عن Apple وGoogle إلى Supabase للتحقق من تسجيل دخولك. وتشارك Apple وGoogle معلومات الحساب وفق الأذونات التي تمنحها، ولا يتلقى حنين كلمة مرور حسابك لدى أيٍّ منهما. يلزم حساب لاستخدام حنين والاحتفاظ بمكتبة يمكن استعادتها على جهاز آخر. ويمكن للمستخدمين الجدد والعائدين الدخول عبر Apple أو Google أو البريد الإلكتروني. وبعد تسجيل الدخول وتجهيز مكتبتك، تتيح الجلسة المحفوظة استخدامها دون اتصال؛ أما التحقق من الحساب والمزامنة السحابية فيحتاجان إلى اتصال.\n\nتتضمن طلبات المصادقة معلومات تقنية، مثل عنوان IP وتفاصيل مكتبة تسجيل الدخول والمنصّة. ويعالج موفّرو تسجيل الدخول معلومات الأمان وتشخيص الأعطال لتشغيل خدماتهم وحمايتها ومعالجة مشكلاتها وفق شروطهم. وتوضح Google أن مكتبة تسجيل الدخول لديها قد تستخدم معرّف المستخدم لتسجيل أذونات الوصول التي وافق عليها، وعنوان IP لتقدير الموقع العام ومنع الاحتيال."
                        )
                    )
                    section(
                        symbol: "icloud",
                        title: copy("Your account library", "مكتبة حسابك"),
                        body: copy(
                            "Haneen sends your saved ayat and their favourites, highlights and notes, custom categories and feeling mappings, saved du’a and life-moment identifiers, reflections, and Qur’an, du’a and collection reading positions to Supabase under your account identifier. Sync includes the record identifiers and update information needed to restore and reconcile your library. These choices and words may reveal religious beliefs or other personal information. They are used to save and restore your library, not for advertising or behavioural analytics. Your library is not public or shared with other users.\n\nChanges made offline are kept on your device and retried when you reconnect. Signing out separates that account’s cached library from the next account; it does not delete the account’s cloud copy. Only the signed-in account can access its library through the app’s database access rules.",
                            "يرسل حنين إلى Supabase، تحت معرّف حسابك، الآيات المحفوظة وما يرتبط بها من مفضّلات وتظليل وملاحظات، والتصنيفات المخصّصة وربط الآيات بالمشاعر، ومعرّفات الأدعية والمواقف المحفوظة، والتأملات، ومواضع القراءة في القرآن والأدعية والمجموعات. وتشمل المزامنة معرّفات السجلات ومعلومات التحديث اللازمة لاستعادة مكتبتك وتسوية التغييرات. وقد تكشف هذه الاختيارات والكلمات عن معتقدات دينية أو معلومات شخصية أخرى. وتُستخدم لحفظ مكتبتك واستعادتها، لا للإعلانات أو تحليل سلوكك. ولا تُنشر مكتبتك أو تُشارك مع مستخدمين آخرين.\n\nتُحفظ التغييرات التي تجريها دون اتصال على جهازك، وتُعاد محاولة مزامنتها عند عودة الاتصال. وعند تسجيل الخروج، تُفصل نسخة مكتبة ذلك الحساب عن الحساب التالي، ولا تُحذف نسختها السحابية. وتسمح قواعد الوصول إلى قاعدة البيانات للحساب المسجّل دخوله بالوصول إلى مكتبته الخاصة فقط."
                        )
                    )
                    section(
                        symbol: "square.and.arrow.up",
                        title: copy("Your existing library", "مكتبتك الحالية"),
                        body: copy(
                            "When upgrading from a version that kept your library only on this iPhone, Haneen asks whether to add that library to your account or start with your account’s cloud library. It does not automatically attach the old library to whichever account signs in first. The old local backup remains until you choose to import it, after which it belongs to the selected account. Choosing the cloud library does not upload that unclaimed backup.",
                            "عند التحديث من إصدار كان يحتفظ بمكتبتك على هذا الهاتف فقط، يسألك حنين إن كنت ترغب في إضافتها إلى حسابك أو البدء بمكتبة حسابك السحابية. ولا يربط المكتبة القديمة تلقائيًا بأول حساب يسجّل الدخول. وتبقى النسخة المحلية القديمة حتى تختار استيرادها، وعندئذ تصبح مرتبطة بالحساب الذي اخترته. أما اختيار المكتبة السحابية فلا يرفع النسخة القديمة غير المرتبطة بحساب."
                        )
                    )
                    section(
                        symbol: "envelope",
                        title: copy("Sign-in emails", "رسائل تسجيل الدخول"),
                        body: copy(
                            "Supabase sends Haneen's email sign-in messages through Brevo. The delivery provider processes your recipient email address, the sign-in message including its one-time link or code, and delivery or failure records needed to send and troubleshoot the message. These messages are for authentication, not a marketing subscription. Provider-held delivery and security records follow the provider's retention policies.",
                            "تُرسل Supabase رسائل تسجيل الدخول إلى حنين عبر Brevo. ويعالج موفّر الإرسال عنوان بريدك الإلكتروني ورسالة تسجيل الدخول، بما فيها الرابط أو الرمز المخصّص للاستخدام مرة واحدة، وسجلات نجاح التسليم أو فشله اللازمة لإرسال الرسالة ومعالجة مشكلات وصولها. وهذه الرسائل للتحقق من تسجيل الدخول، ولا تعني الاشتراك في رسائل تسويقية. وتخضع سجلات التسليم والأمان التي يحتفظ بها الموفّر لسياسات الاحتفاظ الخاصة به."
                        )
                    )
                    section(
                        symbol: "person.crop.circle.badge.checkmark",
                        title: copy("Age-range checks", "التحقق من الفئة العمرية"),
                        body: copy(
                            "Where Apple requires an age-range check, Haneen asks for the range through Apple's system interface after setup. Haneen uses the response on your device and discards it without saving your age, date of birth or age category, or sending that information to Haneen's servers. Only the check's completion state stays in memory during the current app session. Apple manages the associated Apple Account and parental-consent settings under its own privacy terms.",
                            "في المناطق التي تتطلب فيها Apple التحقق من الفئة العمرية، يطلب حنين هذه المعلومات عبر واجهة النظام بعد إعداد التطبيق. ويعالج حنين الإجابة على جهازك ثم يتخلّص منها، دون حفظ عمرك أو تاريخ ميلادك أو فئتك العمرية أو إرسال هذه المعلومات إلى خوادم حنين. ولا تبقى في الذاكرة خلال جلسة الاستخدام الحالية إلا حالة اكتمال التحقق. وتدير Apple إعدادات حساب Apple وموافقة وليّ الأمر ذات الصلة وفق شروط الخصوصية الخاصة بها."
                        )
                    )
                    section(
                        symbol: "location",
                        title: copy("Location and nearby places", "الموقع والأماكن القريبة"),
                        body: copy(
                            "With your permission, prayer times and Qibla are calculated on your device. Compass readings are temporary, and Apple location services may resolve a place name. Nearby mosque or halal-place searches send precise latitude/longitude and the search category to Apple Maps and the Overpass service at overpass-api.de, which searches OpenStreetMap data. Opening directions sends the destination to the map service you choose. These online services receive ordinary connection information such as your IP address. You can deny or revoke location access in iOS Settings.",
                            "بعد موافقتك على استخدام الموقع، تُحسب مواقيت الصلاة واتجاه القبلة على جهازك. وتكون قراءات البوصلة مؤقتة، وقد تستخدم خدمات موقع Apple الإحداثيات لتحديد اسم المكان. وعند البحث عن مساجد أو أماكن تقدّم طعامًا حلالًا بالقرب منك، تُرسل إحداثيات الموقع الدقيقة وفئة البحث إلى خرائط Apple وخدمة Overpass على overpass-api.de للبحث في بيانات OpenStreetMap. وعند فتح الاتجاهات، تُرسل الوجهة إلى خدمة الخرائط التي تختارها. وتتلقى هذه الخدمات معلومات الاتصال المعتادة، مثل عنوان IP. ويمكنك رفض إذن الموقع أو سحبه من إعدادات iOS."
                        )
                    )
                    section(
                        symbol: "book",
                        title: copy("Recitation, tafsir and references", "التلاوة والتفسير والمراجع"),
                        body: copy(
                            "Recitation requests go to EveryAyah and identify the requested reciter and ayah. Opening tafsir requests the selected ayah and tafsir edition from Quran.com's API. These services receive the request and ordinary connection information, including your IP address. Source links you open may take you to Quran.com, Sunnah.com or another cited website, whose privacy terms apply to your visit.\n\nThe full morning and evening adhkar recordings by Abu Islam are bundled with Haneen and play offline on your device. Playing them does not contact SoundCloud. An optional source link opens the original recording in SoundCloud or your browser only when you tap it; SoundCloud’s privacy and cookie policies apply to that visit. Haneen does not use a SoundCloud SDK, API or embedded player.",
                            "تُرسل طلبات التلاوة إلى EveryAyah، وتتضمن القارئ الذي تختاره والآية المطلوبة. وعند فتح التفسير، تُطلب الآية وطبعة التفسير المختارتان من خدمة Quran.com. وتتلقى هذه الخدمات الطلب ومعلومات الاتصال المعتادة، ومنها عنوان IP. وقد تنقلك روابط المصادر التي تفتحها إلى Quran.com أو Sunnah.com أو موقع مرجعي آخر، وتخضع زيارتك لسياسة الخصوصية الخاصة بذلك الموقع.\n\nيتضمن حنين التسجيلين الكاملين لأذكار الصباح والمساء بصوت المنشد أبي إسلام، ويمكن تشغيلهما على جهازك دون اتصال بالإنترنت. ولا يتصل تشغيلهما بخدمة SoundCloud. ويتوفر رابط اختياري للمصدر يفتح التسجيل الأصلي في SoundCloud أو متصفحك عند الضغط عليه فقط؛ وتسري على تلك الزيارة سياسات الخصوصية وملفات تعريف الارتباط لدى SoundCloud. ولا يستخدم حنين مكتبة برمجية أو واجهة برمجة تطبيقات أو مشغّلًا مضمّنًا من SoundCloud."
                        )
                    )
                    section(
                        symbol: "text.bubble",
                        title: copy("Optional deletion feedback", "ملاحظات اختيارية عند حذف الحساب"),
                        body: copy(
                            "If you choose to give a reason or written feedback, it is sent with your authenticated account-deletion request. After account deletion, the feedback is stored in Supabase without your account identifier, together with a random feedback identifier and submission time. It is retained as needed to evaluate feedback and improve the app. The deletion service still authenticates the request, and service logs may contain request/account information. Feedback is optional and never required for deletion; please leave out personal details.",
                            "إذا اخترت ذكر سبب الحذف أو كتابة ملاحظات، فتُرسل مع طلب حذف حسابك باستخدام جلسة تسجيل دخولك. وبعد حذف الحساب، تُحفظ الملاحظات في Supabase دون معرّف حسابك، مع معرّف عشوائي للملاحظات ووقت إرسالها. ونحتفظ بها ما دامت هناك حاجة إليها لتقييم الملاحظات وتحسين التطبيق. وتتحقق خدمة الحذف من هويتك، وقد تتضمن سجلات الخدمة معلومات عن الطلب أو الحساب. والملاحظات اختيارية وليست شرطًا للحذف، لذا يرجى عدم تضمين تفاصيل شخصية."
                        )
                    )
                    section(
                        symbol: "trash",
                        title: copy("Your choices and retention", "خياراتك والاحتفاظ بالبيانات"),
                        body: copy(
                            "You can remove saved items inside Haneen; changes are synchronised when online. Account and cloud-library data are retained to provide the service until you remove the content or delete your account from Settings → Your space → Account → Delete account. Confirmed account deletion removes the account and its cloud-library records, and clears that account’s cached library on this device. For an Apple-linked account, deletion requests fresh Apple authorization so Haneen can revoke its access before deleting the Supabase account. Signing out alone does not delete your account or its cloud library. Deleting the app removes its local data, subject to device backups; it does not delete your cloud account. Copies on another offline device may remain there until it reconnects or its local data is removed. You can change location and notification permissions in iOS Settings. Provider security logs and other provider-held data follow the applicable service retention policies.",
                            "يمكنك حذف العناصر المحفوظة داخل حنين، وتُزامَن التغييرات عند الاتصال. وتُحفظ بيانات الحساب والمكتبة السحابية لتقديم الخدمة حتى تحذف المحتوى أو تحذف حسابك من الإعدادات ← مساحتك ← الحساب ← حذف الحساب. وبعد تأكيد الحذف، يُحذف الحساب وسجلات مكتبته السحابية، وتُمسح نسخة مكتبة ذلك الحساب المحفوظة على هذا الجهاز. وإذا كان الحساب مرتبطًا بـ Apple، يُطلب تفويض جديد منها ليتمكّن حنين من إلغاء وصوله قبل حذف حساب Supabase. ولا يؤدي تسجيل الخروج وحده إلى حذف الحساب أو مكتبته السحابية. ويزيل حذف التطبيق بياناته المحلية، مع احتمال بقائها في نسخ الجهاز الاحتياطية، لكنه لا يحذف حسابك السحابي. وقد تبقى نسخة على جهاز آخر غير متصل حتى يتصل أو تُحذف بياناته المحلية. ويمكنك تغيير أذونات الموقع والإشعارات من إعدادات iOS. وتخضع سجلات الأمان وغيرها من البيانات التي يحتفظ بها موفّرو الخدمات لسياسات الاحتفاظ الخاصة بكل خدمة."
                        )
                    )
                    section(
                        symbol: "lock.shield",
                        title: copy("Service providers and protections", "موفّرو الخدمات وحماية البيانات"),
                        body: copy(
                            "Library transfers use encrypted HTTPS connections and Supabase stores the cloud copy with provider-managed storage protections. This is not end-to-end encryption: Haneen’s service operator and infrastructure providers can process the content to operate the service. Supabase's published data processing addendum limits processing of customer data to customer instructions and specified service purposes, and requires confidentiality and security measures. Apple's and Google's privacy policies describe their data protection, retention and privacy controls. Providers may process data in other countries under their applicable terms. The online policy below links to these documents.",
                            "تُرسل المكتبة عبر اتصالات HTTPS مشفّرة، وتحفظ Supabase النسخة السحابية بوسائل حماية التخزين التي يديرها الموفّر. وهذا ليس تشفيرًا بين الطرفين؛ إذ يمكن لمشغّل خدمة حنين وموفّري البنية التحتية معالجة المحتوى لتشغيل الخدمة. وينصّ ملحق معالجة البيانات المنشور من Supabase على معالجة بيانات العملاء وفق تعليماتهم ولأغراض الخدمة المحدّدة، ويلزمها بالسرية وتدابير الأمان. وتوضح سياستا الخصوصية لدى Apple وGoogle كيفية حماية البيانات والاحتفاظ بها وخيارات الخصوصية. وقد يعالج الموفّرون البيانات في دول أخرى وفق شروطهم. وتتضمن السياسة على الإنترنت أدناه روابط هذه الوثائق."
                        )
                    )
                    section(
                        symbol: "envelope",
                        title: copy("Contact", "التواصل"),
                        body: copy(
                            "Haneen is developed by Islam Sharaf. Questions or deletion assistance: haneen.app.contact@gmail.com. If you contact support, we receive your email address, message and any details you include. Haneen's support form also includes the app and iOS versions. We retain correspondence as needed to respond and resolve the issue.",
                            "طوّر إسلام شرف تطبيق حنين. للاستفسار عن الخصوصية أو طلب المساعدة في الحذف، راسل haneen.app.contact@gmail.com. وعند التواصل مع الدعم، نتلقى عنوان بريدك ورسالتك وأي تفاصيل تذكرها. ويتضمن نموذج الدعم في حنين أيضًا إصدارَي التطبيق وiOS. ونحتفظ بالمراسلات بقدر الحاجة إلى الرد ومعالجة المشكلة."
                        )
                    )

                    Link(copy("Read the online privacy policy", "قراءة سياسة الخصوصية على الإنترنت"), destination: URL(string: "https://isharaf6.github.io/Sakina/privacy.html")!)
                        .font(.yqSubhead)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(copy("Updated 17 September 2026", "آخر تحديث: 17 سبتمبر 2026"))
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
            CompanionIllustration(artwork: .privacy, size: 80)
            Text(copy("Privacy, in plain language", "الخصوصية بلغة واضحة"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.sakinaInk)
            Text(copy(
                "This policy describes the data behavior of Haneen 1.0.",
                "تصف هذه السياسة طريقة تعامل حنين 1.0 مع البيانات."
            ))
            .font(.yqSubhead)
            .foregroundStyle(Color.sakinaMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section(symbol: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
}
