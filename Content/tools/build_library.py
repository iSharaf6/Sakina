import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from names import NAMES, NOTE_EN, NOTE_AR
from openings import OPENINGS

CONTENT = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'duas')
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'Sakina', 'Duas', 'DuaLibrary.swift')
FILES = ['morning-evening.json', 'night-prayer.json', 'praise-remembrance.json', 'others-healing-return.json', 'quran-sunnah.json']
MOODS = ["angry","anxious","urgeToSin","confident","confused","content","depressed","doubtful","grateful","greedy","guilty","happy","hurt","indecisive","hypocritical","jealous","lazy","lonely","lost","nervous","overwhelmed","regret","sad","scared","suicidal","tired","unloved","weak","bored","impatient","hopeful","grieving","seekingForgiveness"]
COLLECTIONS = ["morning","evening","sleep","tahajjud","salah","afterSalah","ummah","healing","praise","salawat","quran","sunnah","istighfar","anytime"]
# Pre-existing reviewed entries used as fallbacks for feelings.
FALLBACK = {
 "angry": ["prophetic-anger-refuge","quran-guidance","quran-steadfast-hearts"],
 "anxious": ["prophetic-anxiety-and-debt","quran-steadfast-hearts","quran-distress-yunus"],
 "urgeToSin": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "confident": ["quran-gratitude-and-good-deeds","prophetic-help-to-worship","quran-family-comfort"],
 "confused": ["quran-guidance","quran-steadfast-hearts","quran-need-any-good"],
 "content": ["quran-gratitude-and-good-deeds","prophetic-help-to-worship","quran-family-comfort"],
 "depressed": ["quran-need-any-good","quran-burdens-and-mercy","quran-guidance"],
 "doubtful": ["quran-guidance","quran-steadfast-hearts","quran-need-any-good"],
 "grateful": ["quran-gratitude-and-good-deeds","prophetic-help-to-worship","quran-family-comfort"],
 "greedy": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "guilty": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "happy": ["quran-gratitude-and-good-deeds","prophetic-help-to-worship","quran-family-comfort"],
 "hurt": ["quran-need-any-good","quran-burdens-and-mercy","quran-guidance"],
 "indecisive": ["prophetic-istikhara","quran-guidance","quran-steadfast-hearts"],
 "hypocritical": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "jealous": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "lazy": ["prophetic-help-to-worship","prophetic-anxiety-and-debt","quran-need-any-good"],
 "lonely": ["quran-need-any-good","quran-steadfast-hearts","quran-guidance"],
 "lost": ["quran-guidance","quran-steadfast-hearts","quran-need-any-good"],
 "nervous": ["prophetic-anxiety-and-debt","quran-steadfast-hearts","quran-distress-yunus"],
 "overwhelmed": ["quran-burdens-and-mercy","prophetic-anxiety-and-debt","quran-distress-yunus"],
 "regret": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
 "sad": ["quran-need-any-good","quran-burdens-and-mercy","quran-guidance"],
 "scared": ["prophetic-anxiety-and-debt","quran-steadfast-hearts","quran-distress-yunus"],
 "suicidal": ["quran-need-any-good","quran-burdens-and-mercy","quran-guidance"],
 "tired": ["prophetic-help-to-worship","prophetic-anxiety-and-debt","quran-need-any-good"],
 "unloved": ["quran-need-any-good","quran-burdens-and-mercy","quran-guidance"],
 "weak": ["prophetic-help-to-worship","prophetic-anxiety-and-debt","quran-need-any-good"],
 "bored": ["prophetic-help-to-worship","prophetic-anxiety-and-debt","quran-need-any-good"],
 "impatient": ["prophetic-anxiety-and-debt","quran-steadfast-hearts","quran-distress-yunus"],
 "hopeful": ["quran-need-any-good","quran-guidance","quran-righteous-offspring"],
 "grieving": ["prophetic-calamity","quran-burdens-and-mercy","quran-need-any-good"],
 "seekingForgiveness": ["quran-repentance-adam","prophetic-master-repentance","quran-distress-yunus"],
}
# Existing daily entries kept where the library has no equivalent (matched by canonical URL).
EXTRAS = {"morning": ("prepend", "daily-waking", "https://sunnah.com/bukhari:6324"),
          "sleep": ("append", "daily-sleep", "https://sunnah.com/bukhari:6324"),
          "tahajjud": ("append", "daily-tahajjud", "https://sunnah.com/bukhari:1120"),
          "salah": ("prepend", "daily-salah", "https://sunnah.com/bukhari:817")}
KIND = {"quranic": ".quranic", "prophetic": ".prophetic", "remembrance": ".remembrance"}

entries = []
for f in FILES:
    p = os.path.join(CONTENT, f)
    if not os.path.exists(p):
        print("skip missing", f); continue
    for e in json.load(open(p))['entries']:
        entries.append(e)
ids = [e['id'] for e in entries]
assert len(ids) == len(set(ids)), "duplicate ids"
by_id = {e['id']: e for e in entries}

def s(v):
    if v is None: return "nil"
    v = str(v).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return '"' + v + '"'

lines = []
lines.append("import Foundation\n")
lines.append("// Generated from the verified content JSON by scratchpad/gen/build_library.py. Do not edit by hand.\n")
lines.append("// Every entry was fetched from its canonical source page; Qur'an text is the Uthmani text from quran.com.\n")
lines.append("enum DuaLibrary {")
lines.append("""    private static func e(_ id: String, _ title: String, _ titleAR: String, _ arabic: String, _ translit: String,
                          _ meaning: String, _ meaningAR: String, _ context: String, _ contextAR: String,
                          _ kind: GuidanceSupplicationKind, _ collection: String, _ collectionAR: String, _ number: String,
                          _ grade: String, _ gradeAR: String, _ url: String, _ excerpt: Bool,
                          _ repeatCount: Int?, _ timing: String?, _ timingAR: String?, _ caution: String?, _ cautionAR: String?) -> GuidanceSupplication {
        GuidanceSupplication(
            id: id, titleEnglish: title, titleArabic: titleAR, arabic: arabic, transliteration: translit,
            meaningEnglish: meaning, meaningArabic: meaningAR, contextEnglish: context, contextArabic: contextAR,
            kind: kind, applicability: .init(level: .direct, explanationEnglish: context, explanationArabic: contextAR),
            source: .init(id: "lib-\\(id)", kind: kind == .quranic ? .quran : .hadith, collectionEnglish: collection,
                          collectionArabic: collectionAR, number: number, gradeEnglish: grade, gradeArabic: gradeAR,
                          canonicalURL: url, textForm: excerpt ? .excerpt : .complete),
            cautionEnglish: caution, cautionArabic: cautionAR, repeatCount: repeatCount, timingEnglish: timing, timingArabic: timingAR)
    }
""")
CHUNK = 12
parts = [entries[i:i+CHUNK] for i in range(0, len(entries), CHUNK)]
lines.append("    static let entries: [GuidanceSupplication] = " + " + ".join(f"part{i+1}" for i in range(len(parts))))
for i, part in enumerate(parts):
    lines.append(f"\n    private static let part{i+1}: [GuidanceSupplication] = [")
    for e in part:
        args = [s(e['id']), s(e['titleEnglish']), s(e['titleArabic']), s(e['arabic']), s(e['transliteration']),
                s(e['meaningEnglish']), s(e['meaningArabic']), s(e['contextEnglish']), s(e['contextArabic']),
                KIND[e['kind']], s(e['sourceCollectionEnglish']), s(e['sourceCollectionArabic']), s(e['sourceNumber']),
                s(e['gradeEnglish']), s(e['gradeArabic']), s(e['canonicalURL']), "true" if e['textForm'] == 'excerpt' else "false",
                str(e['repeatCount']) if e.get('repeatCount') else "nil", s(e.get('timingEnglish')), s(e.get('timingArabic')),
                s(e.get('cautionEnglish')), s(e.get('cautionArabic'))]
        lines.append("        e(" + ", ".join(args) + "),")
    lines.append("    ]")

# Collections
col_map = {}
for c in COLLECTIONS:
    primary = [e['id'] for e in entries if c in e['collections'] and e['id'].lower().startswith(c.lower() + '-')]
    others = [e['id'] for e in entries if c in e['collections'] and e['id'] not in primary]
    ordered = primary + others
    if c == 'quran': ordered = [i for i in ordered if by_id[i]['kind'] == 'quranic']
    if c == 'sunnah': ordered = [i for i in ordered if by_id[i]['kind'] != 'quranic']
    if c in EXTRAS:
        where, extra, url = EXTRAS[c]
        if not any(by_id[i]['canonicalURL'] == url for i in ordered):
            ordered = [extra] + ordered if where == 'prepend' else ordered + [extra]
    col_map[c] = ordered
lines.append("\n    /// Ordered entry ids per collection. Primary entries first, cross-listed entries after.")
lines.append("    static let collections: [String: [String]] = [")
for c in COLLECTIONS:
    lines.append(f"        {s(c)}: [" + ", ".join(s(i) for i in col_map[c]) + "],")
lines.append("    ]")

# Moods
lines.append("\n    /// Best-first entry ids for each feeling.")
lines.append("    static let moods: [String: [String]] = [")
for m in MOODS:
    picked = [e['id'] for e in entries if m in (e.get('moods') or [])][:5]
    for fb in FALLBACK.get(m, []):
        if len(picked) >= 6: break
        if fb not in picked: picked.append(fb)
    lines.append(f"        {s(m)}: [" + ", ".join(s(i) for i in picked) + "],")
lines.append("    ]")

# Openings
lines.append("\n    static let openings: [DuaMood: (english: String, arabic: String)] = [")
for m in MOODS:
    en, ar = OPENINGS[m]
    lines.append(f"        .{m}: (english: {s(en)}, arabic: {s(ar)}),")
lines.append("    ]")

# Names
lines.append("\n    static let namesNoteEnglish = " + s(NOTE_EN))
lines.append("    static let namesNoteArabic = " + s(NOTE_AR))
nparts = [NAMES[i:i+20] for i in range(0, len(NAMES), 20)]
lines.append("    static let names: [DivineName] = " + " + ".join(f"names{i+1}" for i in range(len(nparts))))
for i, part in enumerate(nparts):
    lines.append(f"    private static let names{i+1}: [DivineName] = [")
    for (idx, nid, ar, tr, en, arGloss, refEn, refAr, ref) in part:
        lines.append(f"        DivineName(id: {s(nid)}, arabic: {s(ar)}, transliteration: {s(tr)}, meaning: {s(en)}, verse: {s(ref or '')}, meaningArabic: {s(arGloss)}, reflectionEnglish: {s(refEn)}, reflectionArabic: {s(refAr)}),")
    lines.append("    ]")
lines.append("}")
open(OUT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("entries", len(entries), "names", len(NAMES))
for c in COLLECTIONS: print(f"  {c}: {len(col_map[c])}")
