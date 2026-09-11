import SwiftUI

/// A separately sourced virtue, not an inference from a du’a’s wording or mood.
/// Conditions stay beside the benefit, including the complete passage and count.
struct DuaReward: Decodable {
    let entryIDs: [String]
    let summaryEnglish: String
    let summaryArabic: String
    let conditionsEnglish: String
    let conditionsArabic: String
    let sourceURL: String
    let sourceEnglish: String
    let sourceArabic: String
    let gradeEnglish: String
    let gradeArabic: String

    func summary(_ language: AppLanguage) -> String { language.pick(summaryEnglish, summaryArabic) }
    func conditions(_ language: AppLanguage) -> String { language.pick(conditionsEnglish, conditionsArabic) }
    func source(_ language: AppLanguage) -> String { language.pick(sourceEnglish, sourceArabic) }
    func grade(_ language: AppLanguage) -> String { language.pick(gradeEnglish, gradeArabic) }
}

enum DuaRewardCatalog {
    static let all: [DuaReward] = {
        guard let url = Bundle.main.url(forResource: "dua-rewards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([DuaReward].self, from: data) else {
            assertionFailure("The sourced du’a virtues could not be loaded")
            return []
        }
        return entries
    }()
    private static let byID = Dictionary(uniqueKeysWithValues: all.flatMap { reward in reward.entryIDs.map { ($0, reward) } })
    static func reward(for id: String) -> DuaReward? { byID[id] }
}

struct DuaRewardCard: View {
    let reward: DuaReward
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.pick("Reward & virtue", "الأجر والفضل"), systemImage: "sparkle")
                .font(.yqSubheadBold)
                .foregroundStyle(Color.yqAccentDeep)
            rewardText(summary: reward.summaryArabic, conditions: reward.conditionsArabic, direction: .rightToLeft)
            Divider()
            rewardText(summary: reward.summaryEnglish, conditions: reward.conditionsEnglish, direction: .leftToRight)
            Divider()
            if let url = URL(string: reward.sourceURL) {
                Link(destination: url) {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(reward.source(language)).font(.yqSubheadBold)
                            Text(reward.grade(language)).font(.yqCaption)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Image(systemName: "arrow.up.right").font(.subheadline.weight(.semibold))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .foregroundStyle(Color.yqAccentDeep)
                .accessibilityHint(language.pick("Read the narration supporting this virtue", "اقرأ الدليل على هذا الفضل"))
            }
        }
        .padding(18)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yqAccentTint, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.yqAccentDeep.opacity(0.16), lineWidth: 1) }
        .environment(\.layoutDirection, language.layoutDirection)
    }
    private func rewardText(summary: String, conditions: String, direction: LayoutDirection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary).font(.yqBody).foregroundStyle(Color.yqInk).lineSpacing(4)
            Text(conditions).font(.yqSubhead).foregroundStyle(Color.yqSecondary).lineSpacing(3)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.layoutDirection, direction)
    }

}
