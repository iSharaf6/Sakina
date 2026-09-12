import SwiftUI

struct WidgetCollectionView: View {
    @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }
    private var copy: AppCopy { AppCopy(language: language) }
    @AppStorage("companion.favoriteWidget") private var favorite = CompanionWidgetChoice.prayerCat.rawValue
    @State private var selected: CompanionWidgetChoice?
    private let schedule = PrayerSchedule.placeholder()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(copy("A little Haneen,\nwhere you’ll see it.", "حنين معك،\nعلى شاشتك.")).font(.system(.largeTitle, design: .serif, weight: .medium))
                Text(copy("Ten companions for your Home and Lock Screens. Tap a design to see how to add it. Previews show example prayer times.", "عشرة تصاميم للشاشة الرئيسية وشاشة القفل. اضغط على أي تصميم لمعرفة كيفية إضافته. مواقيت الصلاة في المعاينة أمثلة فقط.")).font(.yqBody).foregroundStyle(Color.yqSecondary)
                ForEach(CompanionWidgetChoice.allCases) { choice in
                    Button { selected = choice; favorite = choice.rawValue } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(choice.title(language)).font(.yqHeadline)
                                Spacer()
                                if favorite == choice.rawValue { Image(systemName: "heart.fill").foregroundStyle(Color.yqAccentDeep) }
                            }
                            CompanionCollectionCard(choice: choice, date: schedule.days[0].events[2].time.addingTimeInterval(-1800), schedule: schedule, preview: true)
                                .padding(20).frame(maxWidth: .infinity).frame(height: choice.isLock ? 110 : 180)
                                .background(Color.yqSurface, in: RoundedRectangle(cornerRadius: 26))
                                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.yqHairline))
                            Text(choice.detail(language)).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }.yqScreen().navigationTitle(copy("Widget collection", "مجموعة الأدوات")).navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { choice in
                ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { CompanionIllustration(artwork: choice.artwork, size: 70); Text(choice.title(language)).font(.yqTitle2) }
                    if choice == .prayerCat {
                        CompanionCollectionCard(choice: choice, date: schedule.days[0].events[2].time.addingTimeInterval(-1800), schedule: schedule, lockScreen: true)
                            .padding(12).frame(width: 180, height: 86).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 18))
                    }
                    Text(choice.isLock || choice == .prayerCat ? copy("For your Lock Screen", "لشاشة القفل") : copy("For your Home Screen", "للشاشة الرئيسية")).font(.yqHeadline)
                    Text(choice.isLock || choice == .prayerCat
                         ? copy("1. Touch and hold your Lock Screen.\n2. Tap Customize, then Lock Screen.\n3. Tap the widget area and find Haneen.\n4. Choose \(choice.title(language)).", "١. اضغط مطولًا على شاشة القفل.\n٢. اختر تخصيص، ثم شاشة القفل.\n٣. اضغط على مساحة الأدوات وابحث عن حنين.\n٤. اختر \(choice.title(language)).")
                         : copy("1. Touch and hold your Home Screen.\n2. Tap Edit, then Add Widget.\n3. Search for Haneen.\n4. Choose \(choice.title(language)) and tap Add Widget.", "١. اضغط مطولًا على الشاشة الرئيسية.\n٢. اختر تحرير، ثم إضافة أداة.\n٣. ابحث عن حنين.\n٤. اختر \(choice.title(language)) واضغط على إضافة أداة."))
                        .font(.yqBody).lineSpacing(8).fixedSize(horizontal: false, vertical: true)
                    Text(copy("The preview uses example prayer times. Your widget uses the location saved in Haneen.", "مواقيت الصلاة في المعاينة أمثلة فقط. تستخدم أداتك الموقع المحفوظ في حنين.")).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                }.padding(24)
                }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
    }
}
