# Arabic language review — 12 September 2026

Reviewed the app’s authored Arabic interface, daily goals, life-situation labels, 33 feeling titles/openings, 99 divine-name reflections, 146 generated supplication meaning paraphrases, account/onboarding, reminder settings, nearby places, Qibla and widget copy.

Examples corrected:
- `ابدأ بـ:` → `هدفك الأول:` before the first daily goal.
- `صغيرة، يومية، لك` → `أهداف بسيطة تختارها ليومك`.
- `33 شعورًا، وضغطة واحدة إلى دعاء` → `اختر من بين 33 شعورًا، واقرأ دعاءً يناسب حالك`.
- Reader titles now have complete Arabic forms per feeling instead of prefixing `حين تشعر أنك` to incompatible phrases.
- Interface middle-dot separators now use `،` in Arabic and commas in English. Imported tafsir HTML entity decoding remains intact.

Arabic cardinal labels use zero/singular/dual/few/many/other forms following [Unicode CLDR Arabic plural rules](https://www.unicode.org/cldr/charts/48/supplemental/language_plural_rules.html#ar), with regression coverage at 0, 1, 2, 3, 10, 11, 33, 99, 100, 103 and 111.

A meaning paraphrase for Qur’an 10:85 had reversed the explanation of being a trial for the oppressors. Corrected against [al-Sa‘di’s tafsir](https://quran.ksu.edu.sa/tafseer/saadi/sura10-aya85.html). The guidance/soundness paraphrase was checked against [Muslim 2725a](https://sunnah.com/muslim:2725a). Generated Arabic edits were mirrored into their source Python/JSON files.

All 146 generated canonical Arabic passages and divine-name fields remain unchanged. The spelling of the calamity supplication was also compared with [Muslim 918a](https://sunnah.com/muslim:918a) and preserved as supplied by that source. This was a language correction pass, not a new scholarly endorsement of every reflection.

Arabic Home and Explore screens were checked in the simulator, including the goal card, marriage categories and feeling entry. The guidance manifest was regenerated for the corrected authored Arabic labels and contexts. There is no automatic publication of the deferred contributor queue.

System/service-generated error descriptions can still follow the device/service language. No authentication, notification scheduling or permission behavior was intentionally changed.

Validation: 61 iOS tests passed, including Arabic plural-boundary regression checks; 103 guidance manifest items and backend invariants passed. All 40 canonical `arabic:` fields in CompanionContent match the preceding release byte-for-byte. Auth manager behavior was compared independently and is unchanged after localization wrappers are excluded.
