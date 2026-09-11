import Foundation
let outputDirectory = CommandLine.arguments[1]
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let entries = CompanionContentCatalog.supplications + DailyDuaCatalog.entries + DuaLibrary.entries + RuqyahCatalog.quran + RuqyahCatalog.added
try encoder.encode(entries).write(to: URL(fileURLWithPath: "\(outputDirectory)/haneen-duas.json"))
struct ReviewEntry: Codable {
 let id: String; let title: String; let context: String; let verses: [String]; let hadiths: [GuidanceHadith]; let duas: [GuidanceSupplication]
}
let reviews = SituationCatalog.all.map { s in
 ReviewEntry(id:s.id,title:s.localizedTitle(.arabic),context:s.localizedWhyNote(.arabic),verses:s.verseKeys,hadiths:CompanionContentCatalog.hadiths(for:s),duas:CompanionContentCatalog.supplications(for:s))
}
try encoder.encode(reviews).write(to: URL(fileURLWithPath: "\(outputDirectory)/haneen-situations.json"))

struct ReviewGroup: Codable { let title: String; let stages: [ReviewStage] }
struct ReviewStage: Codable { let title: String; let ids: [String] }
let groups = GuidanceCatalog.groups.map { g in ReviewGroup(title:g.titleArabic,stages:g.stages.map { ReviewStage(title:$0.titleArabic,ids:$0.situationIDs) }) }
try encoder.encode(groups).write(to: URL(fileURLWithPath:"\(outputDirectory)/haneen-groups.json"))
struct ReviewMood: Codable { let id: String; let title: String; let ids: [String] }
try encoder.encode(DuaMood.allCases.map { ReviewMood(id:$0.id,title:$0.title(.arabic),ids:$0.supplicationIDs) }).write(to: URL(fileURLWithPath:"\(outputDirectory)/haneen-moods.json"))
