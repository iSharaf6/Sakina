# Haneen content provenance and release rights

Updated 17 September 2026 against the current working tree. This records the actual bundled files, their acquisition history and the permissions found. The owner has personally completed the Content Rights declaration in App Store Connect. Historical investigations below are retained as provenance, not as a claim that every unresolved question requires an individual permission letter.

**Third-party content is present.** Two fonts have an embedded conditional distribution grant, and Sunnah.com permits selected educational quotations. The IndoPak font is retained unchanged with author-signed package terms supporting charitable distribution with credits, both notices bundled and visible attribution added; see the follow-up below. Permission for the exact permanently bundled Quran.com API snapshots, and EveryAyah streaming/cache use, is not fully established by the records reviewed. “Unconfirmed” here does not mean infringement.

## Current release assessment

- **Public permission evidence exists:** unchanged KFGQPC fonts, credited unchanged charitable IndoPak use, selected educational Sunnah.com quotations, and conditional QF in-app content display. No new bespoke permission is presumed necessary for those uses.
- **Live tafsir retention is fixed in source:** timestamped entries expire after seven days, reads do not extend their lifetime, stale content is not returned offline, and legacy caches are removed. Foreground cleanup handles time spent suspended. This does not refresh frozen Quran/translation bundles.
- **Two focused scope questions remain:** the storage route for the exact frozen legacy-QF datasets, and provider/recording-owner coverage for EveryAyah audio streaming and caching. The current evidence does not establish infringement or prove that nine separate translation-publisher contracts are required.
- **No font-account blocker:** QF's newer font/image permission requires an active Developer Console account when relying on that permission. Haneen's existing font distribution basis is the independent embedded/author notices above; it does not depend on adopting QF's alternative grant.
- **Canonical text is unchanged.** Fresh Tanzil comparisons below found no complete byte-identical translation replacement. Draft provider questions are in section 7; neither has been sent.

## 1. Bundled fonts

The app registers these three fonts in `project.yml` / `Sakina/Info.plist`. WidgetKit also includes `SakinaWidget/UthmanicHafs.ttf`. Licences below were read directly from each binary's OpenType `name` table, especially name ID 13; these are stronger evidence than a download site's “free font” label.

| File and internal version | Owner/source and evidence | Permission found | Release implication |
| --- | --- | --- | --- |
| `Sakina/Resources/UthmanicHafs.ttf`, KFGQPC HAFS Uthmanic Script 0.18 | King Fahd Glorious Quran Printing Complex. Binary exactly matches [hafs.18.ttf at the pinned acquisition mirror](https://github.com/thetruetruth/quran-data-kfgqpc/blob/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs/font/hafs.18.ttf). | Embedded EULA grants free use, copying and distribution, subject to restrictions on sale, modification, alteration, translation and reverse engineering. It also contains restrictive reproduction wording. This is a publisher-specific grant, not an unrestricted open-source licence. | Preserve the original binary, copyright and full embedded EULA. Do not subset, modify or sell the font itself. Resolve any use beyond that grant with the publisher. |
| `Sakina/Resources/HafsSmart.ttf`, KFGQPC Hafs Smart 0.08 | Same publisher. Exactly matches [hafssmart.8.ttf at the pinned mirror](https://github.com/thetruetruth/quran-data-kfgqpc/blob/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs-smart/font/hafssmart.8.ttf). Acquisition is documented in `scratchpad/gen/fetch_hafs_smart.py`. | Same conditional use/copy/distribution EULA; no modification or standalone sale. | Preserve the binary and notices. The font grant should not automatically be treated as a licence for every separate text database hosted beside it. |
| `Sakina/Resources/IndoPak.ttf`, AlQuran IndoPak by QuranWBW 4.2.1-WL | Ayman Siddiqui / QuranWBW; embedded credits also name Al Qalam, Ghandhara and KFGQPC. Name ID 14 points to QuranWBW. QF's [font-provider register](https://api-docs.quran.com/legal/mushaf-fonts-and-images/) independently identifies QuranWBW as the IndoPak provider. | The embedded notice restricts sale, modification, distribution and development without written notice from QuranWBW. A newly located author-signed package README explicitly names 4.2.1-WL and supports charitable distribution with credits. | Assess the public package notice together with the embedded notice; neither is automatically discarded. Preserve the original font and credit Ayman Siddiqui, R. Siddiqua, QuranWBW and Quran.com. For this unchanged free charitable release, the author-issued public package notice is retained together with the embedded notice as the documented distribution basis. No Haneen-specific correspondence is claimed. |

The KFGQPC fonts' embedded publisher URL is [fonts.qurancomplex.gov.sa](https://fonts.qurancomplex.gov.sa/); that site timed out during this review. The binary EULAs remain directly inspectable. The mirror is evidence of acquisition and byte identity, not an independent rights-holder grant. QF's font-provider page also makes clear that its delivery URLs do not add font rights.

SHA-256 of the reviewed app binaries:

```text
UthmanicHafs.ttf  a0636e68e375af9552470d67773936f54d536e6586ce2608311b2fe7f9cbec3a
HafsSmart.ttf     18c5641d1a9433499660122eccc6388bf89b9c8b752e5957aff41a2bed2c976b
IndoPak.ttf       4c8f002e7538ef6351ac676eb0f2c1708ecd17f6f8a5fc4a19dbc8eaf4dddff5
```

## 2. Actual Quran text, layout and translation acquisition

These are frozen local resources, not merely external links. The committed generators use the **public, unauthenticated `https://api.quran.com/api/v4` endpoints** with ordinary HTTP headers. They do not use the authenticated `apis.quran.foundation/content/api/v4` gateway or Content Sync.

| Bundled resource | Actual content | Acquisition evidence |
| --- | --- | --- |
| `Shared/Resources/quran.json` | 114 surah records and 6,236 Arabic ayat, with Saheeh International English text | `scratchpad/gen/fetch_quran.py`: `/chapters` and `/verses/by_chapter/{n}?fields=text_uthmani&translations=20`. Added in `587ce68`, 10 September 2026. |
| `Shared/Resources/translations.json` | Eight additional translations, 6,236 ayah records | `scratchpad/gen/fetch_quran_extras.py`: `/resources/translations`, then `/verses/by_chapter/{n}` with selected resource IDs. Added in `d53a7f9`, 11 September 2026. |
| `Shared/Resources/quran-scripts.json` | Tajweed spans and IndoPak text for 6,236 ayat | Same extras generator, `text_uthmani_tajweed` and `text_indopak`. Current metadata describes projecting tajweed classes onto the canonical Uthmani text. |
| `Sakina/Resources/mushaf-lines.json` | 604 printed-page layouts with QPC Hafs word text and line positions | `scratchpad/gen/fetch_mushaf_lines.py`: `/verses/by_page/{page}?words=true&word_fields=text_qpc_hafs,code_v2&mushaf=1`. Added in `f8f8e3f`, 11 September 2026. One documented end-marker line-position correction is applied; text is not generated. |
| `Sakina/Resources/quran-transliteration.json` | Joined word transliteration for 6,236 ayat | `scratchpad/gen/bundle_transliteration.py`, reading the cached responses from that same public `by_page` request. |
| `Shared/Resources/verses.json` | 71 selected Arabic ayat and Saheeh International English text | File-level source metadata and `Shared/QuranCatalog.swift` identify Quran.com API v4. |
| `Shared/Resources/ruqyah.json` | 20 selected Quran passages, Arabic and Saheeh International English | `scratchpad/gen/fetch_ruqyah.py`, file-level source metadata and `Sakina/Duas/RuqyahCatalog.swift`. |
| `Shared/Resources/hafs-smart.json` | 6,236 KFGQPC Hafs Smart pre-shaped ayah strings | **Separate source:** `scratchpad/gen/fetch_hafs_smart.py` downloads from [the pinned KFGQPC mirror](https://github.com/thetruetruth/quran-data-kfgqpc/tree/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs-smart). Added in `e2b6c9d`, 11 September 2026. Not acquired from a QF API. The mirror links to the [Complex's developer resources](https://qurancomplex.gov.sa/en/techquran/dev/), but no separate data licence file was found at the pinned revision. |

The public-API generator strips HTML footnote markers and tags, decodes entities and collapses whitespace in English translations. Those are documented transformations of a specific digital edition; they should remain part of its provenance record.

### The QF terms question: established facts and remaining scope uncertainty

The [QF Developer Terms](https://api-docs.quran.com/legal/developer-terms/), updated 14 September 2026, permit in-app display under conditions and reserve source-specific rights. Section 3.1.3 limits storage to one week unless QF expressly permits longer retention or the applicable Content Sync exception is used with updates at least every seven days. The [FAQ](https://api-docs.quran.com/docs/tutorials/faq/) confirms this storage rule. The new font/Mushaf-image exception does not itself cover Quran or translation JSON.

**Applicability to these exact legacy endpoints needs confirmation.** The terms broadly define QF APIs and contain no authenticated-only limitation, but the current [v4 reference](https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/content-apis/) documents OAuth headers, unlike Haneen's acquisition scripts. No explicit legacy-endpoint exemption, Haneen-specific storage permission or earlier open-data licence was found. Therefore the one-week rule is a concrete potential mismatch, not a proven finding that a different authenticated API contract necessarily governs these snapshots. Acquisition was after the current terms' stated update date.

Do not resolve this by labelling the current files “Tanzil CC BY” or “MIT”: their recorded sources are the legacy Quran.com API, and alternative downloads are not byte-identical. The separately acquired KFGQPC Hafs Smart data must also be assessed separately.

### All nine bundled translation editions

| Quran.com ID | Edition in the shipping bundle | Language | Independent permission for this exact snapshot |
| --- | --- | --- | --- |
| 20 | Saheeh International | English | Not recorded. Present in full Quran and selected-passage bundles. Tanzil offers its own Saheeh International download under its non-commercial terms, but it is not identical to this snapshot. |
| 85 | M.A.S. Abdel Haleem | English | Not recorded. Do not infer permission from API availability. |
| 22 | A. Yusuf Ali | English | Not recorded for this digital edition; no worldwide public-domain finding is made here. |
| 19 | M. Pickthall | English | Not recorded for this digital edition; a closely matching Tanzil download is available under its published non-commercial terms. |
| 203 | Al-Hilali & Khan | English | Not recorded for this exact API copy. |
| 84 | T. Usmani | English | Not recorded. |
| 95 | A. Maududi, Tafhim commentary | English | Not recorded. |
| 149 | Fadel Soliman, Bridges’ translation | English | Not recorded. The [publisher's catalogue](https://bridges-foundation.org/product-category/books/) identifies the work but is not a redistribution licence. |
| 54 | Maulana Muhammad Junagarhi | Urdu | Not recorded. |

Edition names and IDs above come from `translations.json` and `QuranScripts.swift`, not a new selection. Attempts to retrieve individual live API resource-information pages returned HTTP 403 during this audit. No missing permission has been inferred to mean the work is infringing; the release record simply cannot yet support a blanket clearance claim.

## 3. Tafsir, recitation and hadith

| Content | Actual use | Rights evidence and status |
| --- | --- | --- |
| Ibn Kathir (Abridged), English, resource 169; Tafsir Muyassar, Arabic, resource 16 | `Sakina/Mushaf/TafsirService.swift` requests the public legacy `/tafsirs/{id}/by_ayah/{key}` endpoint. Commentary is cached with a seven-day maximum age; these books are not bundled in full. | QF's conditional in-app display grant is the public basis. The 17 September source fix enforces the ordinary retention limit and refreshes expired entries on demand. It does not claim a separate private publisher letter. |
| Quran recitation from EveryAyah | `Sakina/Audio/RecitationCache.swift` and `RecitationPlayer.swift` use `https://everyayah.com/data/{folder}/{ayah}.mp3`. The app has 34 reciter/style variants in `Sakina/App/AppSettings.swift`; audio is streamed and cached locally, not bundled in the application. | The [EveryAyah index](https://everyayah.com/) and [audio directory](https://everyayah.com/data/) expose the recordings, but no explicit reuse licence or streaming/cache terms were found in those pages, the recitation page or `recitations.js`. Access working is not a rights grant. Provider/recording permission remains unconfirmed. QF's API terms are not automatically applied to this separate EveryAyah delivery path. |
| Selected hadith and prophetic supplications | Arabic/English selections, references and source links occur in `Shared/CompanionContent.swift`, `Shared/GuidanceCatalog.swift`, `Sakina/Duas/DuaLibrary.swift`, `DailyDuaCatalog.swift` and `RuqyahCatalog.swift`. Bilingual reward summaries and references are in `Shared/Resources/dua-rewards.json`. | [Sunnah.com About, section 8](https://sunnah.com/about) permits individual or selected hadith for teaching/presentation while prohibiting scraping and mass reproduction of whole collections. This supports Haneen's selected educational quotations with their source links; it is not an open licence for the complete database. Preserve the citations and wording. |
| Quran.com / Sunnah.com source buttons | Open the original cited page in the browser | A source link is attribution and context. It should not be confused with permission for separately bundled full translations or a whole database. |

Haneen's authored situation titles, reflections, Arabic interface copy and reward explanations are distinct from quoted scripture or publisher translations. This inventory does not claim scholarly review or publisher endorsement of those authored sections.

## 4. Practical options that preserve a small release scope

### IndoPak: permission, omission or a tested open-font replacement

1. The author-signed package notice described in section 6 is now evidence supporting retention for Haneen’s free charitable release with credits and an unchanged font. Do not remove the option solely because the original audit had not yet found that notice. If a specific written reply is needed to resolve the notice relationship, the font identifies `quranwbw@gmail.com`; no message has been sent.
2. If that notice relationship cannot be resolved for release, the bounded fallback is to omit the optional IndoPak script and its font. Removing only the label or only its `UIAppFonts` entry is insufficient: the binary must also be excluded from app resources. Saved `indopak` preferences need to fall back to Uthmani. Uthmani and Tajweed can remain. No omission has been implemented by this document.
3. [DigitalKhatt's IndoPak font](https://github.com/DigitalKhatt/indopakfont) has an explicit upstream [SIL Open Font License 1.1](https://github.com/DigitalKhatt/indopakfont/blob/main/LICENSE), allowing bundling under its notice and licence conditions. It is based on a 13-line mushaf and is **not a verified drop-in replacement** for QuranWBW's special encoded text. Validate glyph coverage, diacritics, end markers and rendering against its matching text before adopting it. A generic Arabic font fallback would not establish that correctness.

### Independently licensed text sources: viable candidates, not relabels

[Tanzil's Arabic-text licence](https://tanzil.net/docs/Text_License) explicitly permits verbatim application use and distribution under CC BY 3.0 with its stated unmodified-text, attribution, link and notice requirements. Its [translation download terms](https://tanzil.net/trans/) permit non-commercial use; other use requires translator/publisher permission, and applications using more than three listed translations must link back to the translation page. The Arabic CC BY notice does not make all its translations CC BY.

Arabic was compared on 13 September; translation downloads were freshly compared with all 6,236 bundled ayah keys on 17 September. No app data was changed:

| Alternative download | Exact matches against current bundle | Consequence |
| --- | ---: | --- |
| Tanzil Uthmani v1.1, via the [official download page](https://tanzil.net/download/) | 1,935 / 6,236 Arabic strings | A different digital orthography/encoding. Needs full text, font, alignment and printed-layout checks; cannot be silently substituted or used to relicense the existing file. |
| [Tanzil Saheeh International](https://tanzil.net/trans/en.sahih) | 3,128 / 6,236 English strings | Same named translation, different supplied text. Needs a reviewed edition migration and consistent replacement of selected excerpts, not just a source-label change. |
| [Tanzil Pickthall](https://tanzil.net/trans/en.pickthall) | 6,230 / 6,236 English strings | Differences at 2:96, 4:1, 5:107, 31:14, 64:13 and 114:3 include wording/typographic problems, not just whitespace. In particular the downloaded 31:14 substitutes a different family-relation word. Do not import blindly to resolve paperwork. |
| [Tanzil Yusuf Ali](https://tanzil.net/trans/en.yusufali) | 6,217 / 6,236 | Nineteen differences; not the exact bundled digital edition. |
| [Tanzil Hilali & Khan](https://tanzil.net/trans/en.hilali) | 1,185 / 6,236 | Substantial edition differences. |
| [Tanzil Maududi](https://tanzil.net/trans/en.maududi) | 5,550 / 6,236 | 686 differences; not an attribution-only substitution. |
| [Tanzil Junagarhi](https://tanzil.net/trans/ur.junagarhi) | 349 / 6,236 | Widespread punctuation/edition differences; not identical. |

The counts are literal string comparisons, not a blanket claim that non-identical ayat are wrong. Even normalising Latin diacritics and whitespace gives only 4,643 Saheeh matches; substantive wording differences remain. Neither Abdel Haleem, T. Usmani nor Bridges was established as the same available download on that page. A free download price does not establish that every future monetisation model meets a non-commercial licence.

For the present API snapshots, the least disruptive route is an existing written grant covering the specific endpoints, resources, offline storage and distribution. If no such record exists, clarify the legacy/API scope or adopt an approved sync path or independently licensed datasets. No provider has been contacted and no account or service has been changed in this audit.

## 5. Obsolete Heroicons entry and recordkeeping

No Heroicons package, source reference, SVG/PDF asset or licence file remains in the shipping `Sakina`, `Shared`, `SakinaWidget` trees or `project.yml`. Current icon components use Companion artwork and `Image(systemName:)`. The README's claim that `Sakina/Resources/Heroicons-LICENSE.txt` is bundled was therefore removed. Historical design references and unrelated dashboard dependencies do not establish bundled iOS usage.

Before completing a positive content-rights declaration, retain the exact permission/EULA notices supporting the final shipped resources, retain and assess both IndoPak notices, and record the outcome of the legacy-API storage and EveryAyah permission questions. Re-check this inventory if resources are removed or replaced. The initial inventory did not modify app source or canonical religious text. The later notice/credit integration is recorded below.


## 6. Follow-up: original-provider evidence checked for the current release

This follow-up changes the IndoPak assessment from “no relevant written authorisation found” to **author-origin public package terms found and retained for this unchanged charitable release**. Haneen’s stated release is free, charitable, without ads or in-app purchases. The font binary and scripture were not changed, and nobody was contacted. The original notices and provenance were added as resources, and visible bilingual font credits were added to the existing About screen.

### IndoPak: an author-signed notice specifically names the bundled version

The [package’s `(Important) Readme.txt`](https://github.com/marwan/indopak-quran-text/blob/1e2042e4159281194ba91bb80aa1f6716e01ec26/%28Important%29%20Readme.txt) is signed Ayman Siddiqui and dated 10.09.2022. Its special-font section explicitly lists `AlQuran-IndoPak-by-QuranWBW.v.4.2.1-WL.ttf`, matching the version and variant in Haneen’s binary. It identifies the work as charitable and says:

> DO NOT SELL, MANIPULATE, DISTRIBUTE WITHOUT CREDITS OR TAMPER IN ANY FORM OR MANNER.

That is meaningful evidence for credited, unchanged charitable distribution, not just a free-download label. The [current README](https://github.com/marwan/indopak-quran-text/blob/43e1abddc63b77d8bcedcaf9c2869718fb896869/README.md) retains the same condition and directs developers to QUL for maintained files. The account also maintains the [current QuranWBW website source](https://github.com/marwan/quranwbw), strengthening its connection to the provider named in the embedded notice.

The historical package notice is stronger than an unrelated mirror’s licence label, but it does not explicitly explain whether its public permission is the written notice contemplated by the font’s internal EULA. The internal wording says notice **by** QuranWBW, rather than a duty to send notification **to** QuranWBW. It would be inaccurate to silently rewrite that as “just email them and proceed.” Conversely, it would also be inaccurate to assume the internal notice automatically overrides an author-issued public package grant.

The historical package tree now contains 4.2.2 font binaries while its signed documentation lists 4.2.1. Separately, Haneen’s 4.2.1-WL font was verified **byte-identical to Quran.com’s own [pinned TTF](https://github.com/quran/quran.com-frontend-next/blob/74eb4e20f4e78cc11c055a3e130136e8dbb7743e/public/fonts/quran/hafs/nastaleeq/indopak/indopak-nastaleeq-waqf-lazim-v4.2.1.ttf)**, SHA-256 `4c8f002e7538ef6351ac676eb0f2c1708ecd17f6f8a5fc4a19dbc8eaf4dddff5`. This connects the named version to an unchanged publisher-served binary. No font swap was performed.

**Recorded release decision:** retain the existing font for the established free charitable release under the author-issued public package notice, with attribution and no modification or sale. `Sakina/Resources/IndoPak-Author-Notice.txt` is an exact copy of the signed notice (SHA-256 `2f7d40fd219bfd361d5722eaf1c33d810698e77ad4e5c6a629bf343ed15f5cdd`); `IndoPak-Embedded-Notice.txt` preserves name ID 13, and `IndoPak-Provenance.txt` records both sources. The existing About screen now visibly credits the named font creators and links to QuranWBW. This is a scoped public-notice basis, not an unrestricted open-source licence or a claim of a private written reply.

The [current QUL font page](https://qul.tarteel.ai/resources/font/242) documents application integration and points to `normal-v4.2.2/with-waqf-lazmi/font.ttf`. The CDN returned HTTP 403 during the binary check, so this review cannot report that file’s current embedded licence. QUL’s [FAQ](https://qul.tarteel.ai/faq#are-the-resources-in-qul-copyrighted-do-i-need-to-include-attribution-to-an-individual-or-organization-when-using-them) keeps resource-specific author terms in force; its general download instructions are not a replacement licence.

**Optional clarification for a broader use or stricter notice interpretation:** Does the author-signed charitable/credited-distribution package notice authorise bundling and using unmodified 4.2.1-WL in a free iOS app, including App Store distribution, without an individual written reply? Is that public notice the written notice referred to in the font, or is an additional step required? This question is about reconciling actual notices, not requesting a paid commercial licence for a free app.

### Quran.com: continuity confirmed; no new indefinite-storage grant

QF’s [official migration guide](https://api-docs.quran.com/docs/quickstart/migration/) explicitly identifies `api.quran.com/api/v4` as its older unauthenticated API and says covered routes retain their query and response contracts after authentication/base-URL migration. This establishes service continuity more clearly than the prior audit did. It does **not** state a legacy exemption or grant permanent storage of prior snapshots.

The [current Developer Terms](https://api-docs.quran.com/legal/developer-terms/) and [FAQ](https://api-docs.quran.com/docs/tutorials/faq/) provide useful positive permission: in-app Quranic experiences are allowed, including free or monetised applications, subject to the content and storage conditions. No separate commercial licence is required merely because an app has a commercial model. That does not remove resource-specific terms or the one-week/approved-sync storage requirement. Updating only the API hostname or re-downloading once would not resolve permanent bundled storage.

The [Quran.com end-user terms](https://quran.com/terms-and-conditions), section 1.4, permit individual non-commercial informational copying/distribution, but sections 2.2–2.3 also restrict multi-user redistribution, automated collection and non-personal copying. They are not an unambiguous replacement grant for Haneen’s full frozen API datasets. No new grant of indefinite offline storage covering all nine exact bundled translation snapshots was located. QF’s conditional in-app display licence is itself relevant permission evidence; this report does not assume nine separate direct publisher contracts are required when a valid provider licence already covers the use. The [Bridges publisher’s PDF product page](https://bridges-foundation.org/product/bridges-translation-of-quran/) specifically reserves copying of its sold PDF; that applies to the PDF product and does not establish whether the separate Quran.com API edition is authorised or unauthorised.

**Precise remaining owner/provider question:** Is there an existing grant for Haneen’s legacy endpoint snapshots, including their named translation IDs, perpetual in-app offline storage, and the separately downloaded Hafs Smart data? If not, the direct clarification needed from QF is which storage/licensing route covers those exact resources. Access credentials or a free charitable price are not themselves an offline-storage grant.

### EveryAyah: a real timing licence is narrower than audio rights

The first-party [timing-files disclaimer](https://everyayah.com/data/timings_files/000_disclaimer.txt) permits use of those timings with a provider link and points to `versebyversequran.com/site/license`; that full-licence page could not be retrieved during this review. The notice speaks about timing files. It is not a grant for all recordings and does not resolve the app’s separate per-ayah audio streams and cache. The current [Maher Al-Muaiqly folder](https://everyayah.com/data/Maher_AlMuaiqly_64kbps/) exposes audio but no matching `info` or `license` entry was found there. Claims in third-party apps or mirror dataset cards were not adopted as rights-holder grants.

**Precise remaining owner/provider question:** Is there a retained EveryAyah or recording-owner permission covering unmodified streaming and user-device caching of Haneen’s selected reciter folders in a free iOS app? No such record was found by this bounded check.

### Minimal release path based on the evidence now available

- The current IndoPak option is retained unchanged on the author-issued public-notice basis above, with both notices bundled and visible credits added. No font omission or replacement is currently needed for the established free charitable scope; reassess if selling/modifying the font or changing that scope.
- Resolve the API snapshots’ storage route and EveryAyah audio permission through an existing owner-held record or direct provider clarification. These are independent of the font question. Merely dropping IndoPak would not answer them.
- If no grants can be established, the technical fallback is a separately scoped, verified source migration or removal of only the uncertain content paths. The existing Tanzil/approved-sync candidates above require real integration and validation; do not re-label current files or silently substitute Quran text during release preparation.

This audit supplies the evidence and exact questions. It does not assert that unknown rights imply infringement, and it does not supply an unsupported affirmative declaration for the unchanged complete content bundle.

## 7. Unsent provider clarification drafts

These drafts are prepared for the owner. No message has been sent, and no reply or new permission is claimed.

### Quran Foundation — exact offline-storage scope

Verified destination: `developers@quran.com`, the developer contact listed by Quran Foundation's [published documentation](https://qf-api-docs.pages.dev/docs/quickstart/). Sending approval is pending; no correspondence has been sent.

Subject: Haneen: storage permission for a free charitable Quran app

Hello Quran Foundation team,

I am preparing Haneen, a free iPhone app for Quran reading, prayer and supplications. It has no advertisements, payments or subscriptions. It includes attribution and edition names and does not offer a dataset, download API or separate content package.

The current app contains snapshots fetched on 10–11 September 2026 through your legacy `api.quran.com/api/v4` endpoints: Uthmani and IndoPak text, tajweed spans, 604-page QPC word/line layouts, word transliteration, and translations 20, 85, 22, 19, 203, 84, 95, 149 and 54. Selected Quran passages also appear in guidance and widgets. Those resources are presently bundled for offline use, rather than using Content Sync. On-demand tafsir 169/16 now has a seven-day maximum cache age.

Could you confirm whether the public display grant and a permitted storage route cover these exact legacy snapshots in an integrated free app? If indefinite offline bundling needs express permission, may Haneen retain these resources, or must we adopt Content Sync and weekly updates? Please identify any resource-specific exception or attribution required, particularly for those translation IDs. I am not requesting a licence to sell or redistribute the data separately.

Thank you.

This question deliberately excludes the separately sourced KFGQPC Hafs Smart dataset and independently licensed font binaries: QF cannot be assumed to grant rights to unrelated copies. Their provenance is recorded above.

### EveryAyah — streaming and local playback cache

Verified destination: [Submit a support request](https://quran.zendesk.com/hc/en-us/requests/new), reached through the Contact Us link on [EveryAyah's own page](https://everyayah.com/old_index.html). This provider-linked help centre is used rather than an invented EveryAyah email address. Sending approval is pending.

Subject: Permission scope for EveryAyah playback in Haneen

Hello EveryAyah team,

I am preparing Haneen, a free charitable iPhone app with no advertisements, purchases or subscriptions. Its Quran player requests your original, unmodified per-ayah MP3 files directly from `https://everyayah.com/data/`. It keeps a reclaimable playback cache on the user's own device, capped at 300 MB and trimmed to 260 MB. Recordings are not included in the app download, resold, rehosted, edited or exposed through a separate audio service. Users can clear the cache. The app names the selected reciter and credits the source.

Does your provider/recording permission allow this streaming and local caching use? Please send the applicable recording licence or written confirmation, including required attribution, any retention limit and any excluded reciter folders. The timing-files notice links to a full licence page that I could not retrieve, so I am not treating that timing notice as permission for the recordings themselves.

Thank you.

Exact current folder selection, extracted from `Reciter` in `Sakina/App/AppSettings.swift` on 17 September 2026; attach this list to the request and assess the response against it:

```text
Alafasy_128kbps
Husary_128kbps
Abdul_Basit_Murattal_192kbps
Abdurrahmaan_As-Sudais_192kbps
Saood_ash-Shuraym_128kbps
MaherAlMuaiqly128kbps
Minshawy_Murattal_128kbps
Hudhaify_128kbps
Abu_Bakr_Ash-Shaatree_128kbps
ahmed_ibn_ali_al_ajamy_128kbps
Hani_Rifai_192kbps
Yasser_Ad-Dussary_128kbps
Nasser_Alqatami_128kbps
Ghamadi_40kbps
Muhammad_Ayyoub_128kbps
Muhammad_Jibreel_128kbps
Mohammad_al_Tablaway_128kbps
Abdullah_Basfar_192kbps
Muhsin_Al_Qasim_128kbps
Abdullaah_3awwaad_Al-Juhaynee_128kbps
Salaah_AbdulRahman_Bukhatir_128kbps
Ali_Jaber_64kbps
Fares_Abbad_64kbps
khalefa_al_tunaiji_64kbps
Ayman_Sowaid_64kbps
Yaser_Salamah_128kbps
Sahl_Yassin_128kbps
Akram_AlAlaqimy_128kbps
Ibrahim_Akhdar_32kbps
mahmoud_ali_al_banna_32kbps
Abdul_Basit_Mujawwad_128kbps
Minshawy_Mujawwad_192kbps
Mustafa_Ismail_48kbps
Husary_Muallim_128kbps
```
