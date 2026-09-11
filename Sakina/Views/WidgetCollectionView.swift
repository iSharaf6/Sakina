import SwiftUI

struct WidgetCollectionView: View {
    @AppStorage("companion.favoriteWidget") private var favorite = CompanionWidgetChoice.prayerCat.rawValue
    @State private var selected: CompanionWidgetChoice?
    private let schedule = PrayerSchedule.placeholder()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("A little Haneen,\nwhere you’ll see it.").font(.system(.largeTitle, design: .serif, weight: .medium))
                Text("Ten companions for your Home and Lock Screens. Tap a design to see how to add it. Previews show example prayer times.").font(.yqBody).foregroundStyle(Color.yqSecondary)
                ForEach(CompanionWidgetChoice.allCases) { choice in
                    Button { selected = choice; favorite = choice.rawValue } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(choice.title).font(.yqHeadline)
                                Spacer()
                                if favorite == choice.rawValue { Image(systemName: "heart.fill").foregroundStyle(Color.yqAccentDeep) }
                            }
                            CompanionCollectionCard(choice: choice, date: schedule.days[0].events[2].time.addingTimeInterval(-1800), schedule: schedule, preview: true)
                                .padding(20).frame(maxWidth: .infinity).frame(height: choice.isLock ? 110 : 180)
                                .background(Color.yqSurface, in: RoundedRectangle(cornerRadius: 26))
                                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.yqHairline))
                            Text(choice.detail).font(.yqCaption).foregroundStyle(Color.yqSecondary)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }.yqScreen().navigationTitle("Widget collection").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { choice in
                ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { CompanionIllustration(artwork: choice.artwork, size: 70); Text(choice.title).font(.yqTitle2) }
                    if choice == .prayerCat {
                        CompanionCollectionCard(choice: choice, date: schedule.days[0].events[2].time.addingTimeInterval(-1800), schedule: schedule, lockScreen: true)
                            .padding(12).frame(width: 180, height: 86).background(Color.yqFill, in: RoundedRectangle(cornerRadius: 18))
                    }
                    Text(choice.isLock || choice == .prayerCat ? "For your Lock Screen" : "For your Home Screen").font(.yqHeadline)
                    Text(choice.isLock || choice == .prayerCat
                         ? "1. Touch and hold your Lock Screen.\n2. Tap Customize, then Lock Screen.\n3. Tap the widget area and find Haneen.\n4. Choose \(choice.title)."
                         : "1. Touch and hold your Home Screen.\n2. Tap Edit, then Add Widget.\n3. Search for Haneen.\n4. Choose \(choice.title) and tap Add Widget.")
                        .font(.yqBody).lineSpacing(8).fixedSize(horizontal: false, vertical: true)
                    Text("The preview uses example prayer times. Your widget uses the location saved in Haneen.").font(.yqCaption).foregroundStyle(Color.yqSecondary)
                }.padding(24)
                }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
    }
}
