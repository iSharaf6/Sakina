# A small pause, not a catalogue

Implemented in the native SwiftUI app on 8–9 September 2026. The display name remains Yaqeen; the Xcode target remains Sakina.

## Direction

The brief was to remove the work of scanning long, sideways filters and reading stacked articles. The app now offers a finite choice, opens a focused reading, and remembers where the person left off. White, deep green, clear rounded typography and restrained eightfold geometry carry the identity. No cartoon mascot, emoji mood illustrations, confetti, points or streak penalties were introduced.

The Ottoman-inspired ornament is constructed from eightfold rotational geometry. The repeating field uses approximately 9% opacity; standalone linework is stronger. The same shape becomes a reading-progress mark and draws to completion when the person finishes. It does not measure religious achievement. Native navigation, short reading transitions and subtle press feedback provide motion without an animation dependency or added network work. Reduce Motion disables spatial reading transitions and the rosette trace.

## What changed

- **Home:** an explicit description of what the app does, a time-of-day reading invitation, four approachable feelings, all-feelings access, an optional breathing pause and the last reading. Existing prayer setup, Qur’an, Qibla and settings remain.
- **Du’a & dhikr:** three stationary modes: My day, My heart and Collections. No sideways mood rail. Search accepts feeling words, source references, collections and names/meanings.
- **My heart:** six families expose all 30 requested unique emotions, plus the three existing entries (hopeful, grieving, seeking forgiveness). A feeling opens a reading immediately. The suicidal entry opens a support-first screen with a route to local help, then optional reading.
- **My day:** six everyday entries plus a clock-based suggestion. The suggestion is not a calculation of prayer time. Each collection resumes at the last passage on this device, and finishing clears its resume position.
- **Collections:** 15 requested categories, arranged into four expandable groups. Morning, evening, before sleep, tahajjud, salah, after salah, ummah, ruqyah and illness, praises of Allah, salawat, Qur’anic du’as, Sunnah du’as, istighfar, dhikr for all times, and names of Allah.
- **Reading:** one intact source text at a time. Arabic, meaning and pronunciation occupy the same surface. A native menu can jump to another passage. Save/share and source/context remain available. Long passages scroll without shortening the Arabic. Finishing has a clear endpoint.
- **Explore:** five broad areas, then a short stage choice. Each stage shows at most four moments per page. Quick guidance offers six concise prompts per page, retaining all 17 entries and search. Qur’an and hadith are shown one passage at a time; meanings replace the Arabic view when requested. Context and reflection expand on demand. Essential relationship-safety information remains visible, with the complete original notices available in a disclosure.
- **Accessibility:** native controls and back navigation; semantic light/dark colors; Arabic RTL; text selection in the du’a reader; single-column choices at accessibility sizes. On large accessibility text, the reading header scrolls with the passage and the action can wrap. Decorative geometry is hidden from accessibility.

## References actually inspected

The AppLlama design and simulator-review workflow was read and used. AppLlama MCP tooling was not available in this session, so research used public browser pages. No gated Mobbin flows were bypassed.

**Mobbin was the main visual source.** Public screens inspected included Stoic's Morning Preparation, Koans detail and breathing article; ClassPass Warmup Run; Khan Academy Counting Unit; Open Live Class and Meditate; Quizlet's focused card; Fitbit's sleep program; Nike Training Club detail; Imprint's book and chapter-content screens; and Ten Percent Happier's Basics detail. These were screen references, not a claim to have traversed the full private apps.

- [Stoic morning screen](https://mobbin.com/explore/screens/839dd8c6-fd52-486a-a599-39f5242de9ba): a finite invitation with an obvious beginning.
- [Mobbin lesson-detail gallery](https://mobbin.com/explore/mobile/screens/class-lesson-detail): focused content, progressive disclosure, and reachable next/start actions. Imprint and Quizlet informed the one-reading surface; Stoic informed the small daily invitation.
- [Chris Raroque — What surprise and delight actually means](https://notes.chrisraroque.com/p/what-surprise-and-delight-actually): using context to save the person effort, and letting the identity support the experience. This inspired automatic resume and meaningful completion rather than a mascot.
- [Chris Raroque — How I Make Apps FEEL 10x Better](https://www.youtube.com/watch?v=8mMH6Pq8qnE): transcript reviewed in the earlier white-and-green pass. Earlier public Luna, Amy and Pillars references are recorded under `../WhiteGreen/Research/`.
- [Islamestic nature reference](https://www.islamestic.com/nature/): supplied by the user. A fetch in this pass timed out; the existing nature-based breathing experience was retained.

No Mobbin artwork or screenshots were copied into product assets. The geometry is native vector drawing.

## Content scope and source checks

The library now has 30 selected du’a/dhikr entries, including 12 additions for daily practice. Collections are selections, not exhaustive ritual manuals. Timing and repetition follow the individual source. Only the source-backed three repetitions of after-prayer istighfar are displayed as a count.

The **Names of Allah section currently contains 14 names directly drawn from Qur’an 59:22–24**, explicitly labelled as a selection from Surah Al-Hashr. It is not presented as a complete list of 99. English meanings are short explanatory renderings, with Arabic explanations in Arabic mode. Searching a meaning can jump directly to the matching name.

Arabic excerpts and their corresponding source passages were checked against:

- [Bukhari 6324](https://sunnah.com/bukhari:6324): waking and sleep.
- [Tirmidhi 3391](https://sunnah.com/tirmidhi:3391): morning and evening. This narration's particular endings are retained: morning `وإليك المصير`, evening `وإليك النشور`; the context notes the variant.
- [Bukhari 1120](https://sunnah.com/bukhari:1120): a labelled excerpt of the night-prayer supplication. The complete praise and narration remain at the source.
- [Bukhari 817](https://sunnah.com/bukhari:817): bowing and prostration.
- [Muslim 591](https://sunnah.com/muslim:591): after-salah forgiveness and peace.
- [Bukhari 5743](https://sunnah.com/bukhari:5743): prayer for healing. The source's third-person pronoun is retained; the app supports du’a alongside medical care.
- [Bukhari 3370](https://sunnah.com/bukhari:3370): salawat.
- [Bukhari 6406](https://sunnah.com/bukhari:6406): two phrases of praise, in the cited narration's order.
- [Qur’an 59:10](https://quran.com/59/10): prayer for fellow believers.
- [Qur’an 59:22–24](https://quran.com/59/22-24): the names selection.
- [Bukhari 6306](https://sunnah.com/bukhari:6306): existing foremost prayer for forgiveness, relevant morning and evening.

Original source links, source grades, excerpt labels, context and applicable cautions are preserved. Feeling associations are editorial suggestions for reflection, not claims of a prescribed recitation for a particular emotion or a promised outcome. Reading counts are navigation, not invented dhikr prescriptions. Source comparison is not a claim of independent scholarly certification.

## Verification

- **27 unit tests passed, zero failures or skips.** New cases cover all requested feelings, source-backed collection resolution, invalid saved data, resume/completion isolation between collections, and the names selection. The tests exposed a case-sensitive mood-alias bug, which was fixed before rerunning successfully.
- Successful **Release build and simulator launch**, including the final build at 2026-09-08 14:12 UTC. Tests use Debug to support `@testable import`.
- Manually exercised on iPhone 17 Pro Max: day → collection → Arabic/meaning → next → finish → return; resume at the second reading; native edge-back; saved reading reopen; names next/search by meaning/select; urgent-support route; six feeling families → feeling → direct reader; collection directory; Quick guidance pages 1–3; Explore stage pagination; Qur’an/hadith switching and hadith passage pagination; source sheet and dismissal.
- iPhone SE checked at normal size, XXXL and accessibility-large, including a readable full sleep prayer and wrapping final action. Arabic RTL and dark mode were visually inspected on SE. The Reduce Motion setting was enabled for a relaunch and navigation pass; restored afterward. Simulator checks do not establish real-device frame rate, tactile haptic quality, or VoiceOver audit completeness.
- The 62-second `final-flow.mp4` was played at normal speed in QuickTime and inspected at reading and transition states. Completion was scrubbed at 28.4, 28.8 and 29.2 seconds: the incomplete rosette visibly draws into the complete mark, without clipping. The video predates only the final accessibility grid/copy refinements, which do not change its recorded default-size route.

## Review artifacts

- `final-flow.mp4`: actual simulator recording, not a generated mockup.
- `heart.png`, `reader.png`, `completion.png`: primary feeling and reading flow.
- `day.png`, `names.png`, `quick-guidance.png`, `stages.png`, `guidance.png`: discovery and source content.
- `se-reader.png`, `se-large-type.png`, `se-accessibility-dark.png`, `arabic-dark.png`: small-screen and localization checks.

The app remains local and uncommitted. No distribution or deployment was performed.
