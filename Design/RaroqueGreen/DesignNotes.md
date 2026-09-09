# Raroque green: the fourth pass

Implemented in the native SwiftUI app on 9 September 2026. Display name Yaqeen; Xcode target Sakina. This pass replaces the Sanctuary, WhiteGreen and PracticeAndFeelings passes, which the owner rejected as generic.

## Direction

The brief: copy the feel of Chris Raroque's apps (Luna Budgeting, Amy Food Journal), in white and green, with iconography that does not read as generated; make the app less of a scroll, less of a chore to read, and something people return to; cover the full set of du'a collections and 31 feelings; put an Ottoman geometric pattern behind everything at about ten percent.

What that became:

- **One canvas, one accent.** White (`#FFFFFF`, dark `#0B0F0D`), one saturated green (`#16A34A`, deep text variant `#15803D`, tint `#E6F6EC`), one cool-neutral grey family (ink `#101714`, secondary `#616B66`, tertiary `#98A19C`, hairline `#E6EAE8`, fill `#F3F5F4`). The only other colours are iOS system badge tints.
- **Iconography.** SF Symbols only. Solid rounded-square badges (continuous corners, white glyph) for collections, life groups and tiles; tinted capsule chips for feelings; outline-to-filled symbols in the native tab bar. The Heroicons assets and the eightfold line ornaments on cards were removed.
- **Type.** SF Pro, bold large titles, 20pt bold section headers, 17pt medium row titles, 15pt secondary, 13pt captions, monospaced digits for counts. The rounded design was dropped.
- **Surfaces.** Hairline cards without shadows; one dark hero surface (the next-prayer card, `#0F2A1B`); pills for tags; 16pt buttons; 18pt cards; 22pt reader card.
- **Geometry.** `GeometricField` tiles an eight-point star (two overlapping squares, inner ratio 0.7654) on a square lattice whose spacing equals the star diameter, so the negative space forms the classic cross. Stroke 0.8pt at ten percent green (nine percent in dark mode), drawn once with `Canvas` and rasterised. Cards are opaque, so Arabic never sits on the pattern. `KhatamRosette` (two squares, inner octagon, core octagon) draws itself to completion when a collection is finished.
- **Motion.** Press-in 90ms scale to 0.97, release spring (response 0.32, damping 0.72). Staggered reveal on first appearance (45ms per item, spring response 0.42). Recitation ring fills with a spring per tap; completion morphs into a checkmark and auto-advances after 750ms. Reduce Motion removes offsets and delays. Haptics: light impact per recitation tap, selection on page change and save, success on completion.

## Screens

- **Home** fits one viewport on iPhone 17 Pro: wordmark and Hijri date, greeting by time of day, one search field that routes to Explore, the next-prayer card (or a set-up card), six feeling chips (recently opened first), a seven-day heart strip that appears after the first check-in, and four tiles: the collection for this time of day with a progress ring, today's ayah, continue reading, Qibla. "Breathe" sits in the Today header.
- **Du'as** shows a "Right now" card, the feeling chips, and all fifteen collections as a 3×5 badge grid with counts, "Continue" or "Done today".
- **Feelings** is one screen: a "Recently" row, then six bands (heavy heart, restless mind, finding my way, coming back, in a good place, running on empty), each a wrapping cloud of tinted chips. One tap opens the reader. Suicidal opens a support-first screen.
- **Reader** is paged: segment progress, timing line, tags (repeat count, excerpt, source), title, one card with Arabic, transliteration and meaning, a source-and-context row, cautions where the source needs them, a recitation counter when the source states a count, and Previous/Next. Feelings add a one-line opening and, for the heavy band, a breathe-first row with a helpline link. Finishing draws the rosette and records the collection as done for today.
- **Names** is a swipeable deck of 99 cards (Arabic, transliteration, meaning, one reflection, Qur'an reference where the name occurs) over a searchable 3-column grid.
- **Explore** is five life-group rows with counts, an "ayah for right now" card and a feelings shortcut. A group opens one screen with every stage as a section; pagination is gone.
- **Saved** uses a capsule selector with counts and grouped rows.

## References actually used

- Chris Raroque: "How I Make Apps FEEL 10x Better" and the Greg Isenberg design course transcripts, Builder Notes ("What surprise and delight actually looks like", "When should you reinvent an interface?"), lunabudgeting.com, amyfoodjournal.com, App Store listings, and Cecilia Kim's Luna design-system case study. Rules adopted: one accent on white, badge rows, dark summary card, suggestion chips instead of blank inputs, outline-to-filled tab icons, graded haptics, composed micro-animations, Apple-Notes-style reading surface, "the product does more thinking so the person can do less".
- Mobbin: the MCP connector rejected every query as requiring a paid plan and mobbin.com blocked the research agents, so no Mobbin screens were inspected. The agents instead read App Store screenshot galleries for How We Feel, Finch, stoic, Calm, Daylio, Balance, Sabrly, Headspace, Reflectly, Pillars, Muslim Pro, Tarteel, Sabr, Dua & Azkar, and Tasbih Counter, plus Apple's State of Mind documentation. Patterns adopted: banded chip cloud for feelings, reframe line before content, anchor row for heavy feelings, weekly check-in strip, stacked Arabic/transliteration/meaning, full-width recitation counter, name card deck.
- Geometry: the star-and-cross and khatam constructions were rendered to PNG by a research agent and compared before implementation.

## Content

- 146 readings across the 14 text collections, generated into `Sakina/Duas/DuaLibrary.swift` from `Content/duas/*.json` by `Content/tools/build_library.py`. Each entry was fetched from its canonical page (sunnah.com via the browser pane or a reader proxy; Qur'an text is the Uthmani text from quran.com's API) and then checked by an independent verifier agent, whose corrections were applied.
- Repeat counts appear only where the cited narration states them (3, 7, 33, 100). Grades are copied from the source page. Narrations whose sunnah.com grade is weak were dropped and are listed in the JSON notes (for example Abu Dawud 5069, 5072, 5073, 5081, 5084). One morning wording (Muslim 2723) follows Hisn al-Muslim 77 and says so in its context.
- The 99 names follow the widely used enumeration (at-Tirmidhi 3507); the screen states that the hadith affirming ninety-nine names (Bukhari 2736, Muslim 2677) carries no list and that the listed order is graded weak by some scholars. Reflections are editorial one-liners, not translations.
- Feeling mappings come from the verifier-checked `moods` tags, best-first, with the pre-existing reviewed entries as fallbacks. Opening lines are editorial.

## Verification

- `xcodegen generate`, Debug build and the full test suite on iPhone 17 Pro (iOS 26.5): 29 tests, 0 failures, including new checks that every collection has at least five distinct sourced readings, every feeling resolves, every Arabic field is free of Latin letters, all 99 names are unique, and every SF Symbol name used exists at runtime.
- Screens were opened with the debug launch argument (`-yqScreen <route>`) and captured with `simctl` in light, dark and Arabic: Home, Du'as, feelings, morning/after-salah/sleep readers, a feeling reader, names, Explore, a life group, Saved.
- Not verified: real-device haptics and frame pacing, VoiceOver end to end, and gesture recordings, because the simulator MCP fails on this machine (it reports Xcode as not selected) and screen control for Simulator was declined. Settings, About and the widgets keep their previous layouts with the new palette.
