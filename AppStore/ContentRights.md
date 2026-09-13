# Haneen content provenance and release rights

Reviewed 13 September 2026 against the current working tree. This records the actual bundled files, their acquisition history and the permissions found. It is evidence for the owner's App Store Connect declaration, not a declaration already made on their behalf.

**Third-party content is present.** Two fonts have an embedded conditional distribution grant, and Sunnah.com permits selected educational quotations. The IndoPak font has an explicit written-notice restriction. Permission for the exact permanently bundled Quran.com API snapshots, and EveryAyah streaming/cache use, is not fully established by the records reviewed. “Unconfirmed” here does not mean infringement.

## 1. Bundled fonts

The app registers these three fonts in `project.yml` / `Sakina/Info.plist`. WidgetKit also includes `SakinaWidget/UthmanicHafs.ttf`. Licences below were read directly from each binary's OpenType `name` table, especially name ID 13; these are stronger evidence than a download site's “free font” label.

| File and internal version | Owner/source and evidence | Permission found | Release implication |
| --- | --- | --- | --- |
| `Sakina/Resources/UthmanicHafs.ttf`, KFGQPC HAFS Uthmanic Script 0.18 | King Fahd Glorious Quran Printing Complex. Binary exactly matches [hafs.18.ttf at the pinned acquisition mirror](https://github.com/thetruetruth/quran-data-kfgqpc/blob/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs/font/hafs.18.ttf). | Embedded EULA grants free use, copying and distribution, subject to restrictions on sale, modification, alteration, translation and reverse engineering. It also contains restrictive reproduction wording. This is a publisher-specific grant, not an unrestricted open-source licence. | Preserve the original binary, copyright and full embedded EULA. Do not subset, modify or sell the font itself. Resolve any use beyond that grant with the publisher. |
| `Sakina/Resources/HafsSmart.ttf`, KFGQPC Hafs Smart 0.08 | Same publisher. Exactly matches [hafssmart.8.ttf at the pinned mirror](https://github.com/thetruetruth/quran-data-kfgqpc/blob/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs-smart/font/hafssmart.8.ttf). Acquisition is documented in `scratchpad/gen/fetch_hafs_smart.py`. | Same conditional use/copy/distribution EULA; no modification or standalone sale. | Preserve the binary and notices. The font grant should not automatically be treated as a licence for every separate text database hosted beside it. |
| `Sakina/Resources/IndoPak.ttf`, AlQuran IndoPak by QuranWBW 4.2.1-WL | Ayman Siddiqui / QuranWBW; embedded credits also name Al Qalam, Ghandhara and KFGQPC. Name ID 14 points to QuranWBW. QF's [font-provider register](https://api-docs.quran.com/legal/mushaf-fonts-and-images/) independently identifies QuranWBW as the IndoPak provider. | The embedded notice restricts sale, modification, distribution and development without written notice from QuranWBW. No written authorisation for Haneen was found. | Obtain and retain the relevant written permission/notice, or omit/replace this font before asserting its distribution is authorised. Free download availability and the charitable purpose do not resolve this particular notice. |

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

The [QF Developer Terms](https://api-docs.quran.com/legal/developer-terms/), updated 26 August 2026, permit in-app display under conditions and reserve source-specific rights. Section 3.1.3 limits storage to one week unless QF expressly permits longer retention or the applicable Content Sync exception is used with updates at least every seven days. The [FAQ](https://api-docs.quran.com/docs/tutorials/faq/) confirms this storage rule.

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
| Ibn Kathir (Abridged), English, resource 169; Tafsir Muyassar, Arabic, resource 16 | `Sakina/Mushaf/TafsirService.swift` requests the public legacy `/tafsirs/{id}/by_ayah/{key}` endpoint and keeps plain-text memory/disk caches. These books are not bundled in full. | No edition-specific permission record was found. The same legacy-API scope question applies. The cache currently has no age expiry; confirm permitted retention or make storage comply with the applicable grant. |
| Quran recitation from EveryAyah | `Sakina/Audio/RecitationCache.swift` and `RecitationPlayer.swift` use `https://everyayah.com/data/{folder}/{ayah}.mp3`. The app has 34 reciter/style variants in `Sakina/App/AppSettings.swift`; audio is streamed and cached locally, not bundled in the application. | The [EveryAyah index](https://everyayah.com/) and [audio directory](https://everyayah.com/data/) expose the recordings, but no explicit reuse licence or streaming/cache terms were found in those pages, the recitation page or `recitations.js`. Access working is not a rights grant. Provider/recording permission remains unconfirmed. QF's API terms are not automatically applied to this separate EveryAyah delivery path. |
| Selected hadith and prophetic supplications | Arabic/English selections, references and source links occur in `Shared/CompanionContent.swift`, `Shared/GuidanceCatalog.swift`, `Sakina/Duas/DuaLibrary.swift`, `DailyDuaCatalog.swift` and `RuqyahCatalog.swift`. Bilingual reward summaries and references are in `Shared/Resources/dua-rewards.json`. | [Sunnah.com About, section 8](https://sunnah.com/about) permits individual or selected hadith for teaching/presentation while prohibiting scraping and mass reproduction of whole collections. This supports Haneen's selected educational quotations with their source links; it is not an open licence for the complete database. Preserve the citations and wording. |
| Quran.com / Sunnah.com source buttons | Open the original cited page in the browser | A source link is attribution and context. It should not be confused with permission for separately bundled full translations or a whole database. |

Haneen's authored situation titles, reflections, Arabic interface copy and reward explanations are distinct from quoted scripture or publisher translations. This inventory does not claim scholarly review or publisher endorsement of those authored sections.

## 4. Practical options that preserve a small release scope

### IndoPak: permission, omission or a tested open-font replacement

1. Retain the current font only with evidence addressing its embedded written-notice restriction. The font itself identifies `quranwbw@gmail.com`; no message has been sent.
2. For a release without that permission, omit the optional IndoPak script and its font. Removing only the label or only its `UIAppFonts` entry is insufficient: the binary must also be excluded from app resources. Saved `indopak` preferences need to fall back to Uthmani. Uthmani and Tajweed can remain. No omission has been implemented by this document.
3. [DigitalKhatt's IndoPak font](https://github.com/DigitalKhatt/indopakfont) has an explicit upstream [SIL Open Font License 1.1](https://github.com/DigitalKhatt/indopakfont/blob/main/LICENSE), allowing bundling under its notice and licence conditions. It is based on a 13-line mushaf and is **not a verified drop-in replacement** for QuranWBW's special encoded text. Validate glyph coverage, diacritics, end markers and rendering against its matching text before adopting it. A generic Arabic font fallback would not establish that correctness.

### Independently licensed text sources: viable candidates, not relabels

[Tanzil's Arabic-text licence](https://tanzil.net/docs/Text_License) explicitly permits verbatim application use and distribution under CC BY 3.0 with its stated unmodified-text, attribution, link and notice requirements. Its [translation download terms](https://tanzil.net/trans/) permit non-commercial use; other use requires translator/publisher permission, and applications using more than three listed translations must link back to the translation page. The Arabic CC BY notice does not make all its translations CC BY.

Downloads were compared in memory with all 6,236 bundled ayah keys on 13 September; no app data was changed:

| Alternative download | Exact matches against current bundle | Consequence |
| --- | ---: | --- |
| Tanzil Uthmani v1.1, via the [official download page](https://tanzil.net/download/) | 1,935 / 6,236 Arabic strings | A different digital orthography/encoding. Needs full text, font, alignment and printed-layout checks; cannot be silently substituted or used to relicense the existing file. |
| [Tanzil Saheeh International](https://tanzil.net/trans/en.sahih) | 3,128 / 6,236 English strings | Same named translation, different supplied text. Needs a reviewed edition migration and consistent replacement of selected excerpts, not just a source-label change. |
| [Tanzil Pickthall](https://tanzil.net/trans/en.pickthall) | 6,230 / 6,236 English strings | Closest tested alternative. Differences are at 2:96, 4:1, 5:107, 31:14, 64:13 and 114:3. A verbatim import with its source notice and six reviewed differences is a bounded option for this edition. |

The counts are literal string comparisons, not a claim that non-identical ayat are wrong or that their meanings differ. Trimming leading/trailing whitespace did not increase these counts. A free download price by itself should not be used to infer that every future monetisation model meets a non-commercial licence.

For the present API snapshots, the least disruptive route is an existing written grant covering the specific endpoints, resources, offline storage and distribution. If no such record exists, clarify the legacy/API scope or adopt an approved sync path or independently licensed datasets. No provider has been contacted and no account or service has been changed in this audit.

## 5. Obsolete Heroicons entry and recordkeeping

No Heroicons package, source reference, SVG/PDF asset or licence file remains in the shipping `Sakina`, `Shared`, `SakinaWidget` trees or `project.yml`. Current icon components use Companion artwork and `Image(systemName:)`. The README's claim that `Sakina/Resources/Heroicons-LICENSE.txt` is bundled was therefore removed. Historical design references and unrelated dashboard dependencies do not establish bundled iOS usage.

Before completing a positive content-rights declaration, retain the exact permission/EULA notices supporting the final shipped resources, resolve the explicit IndoPak condition, and record the outcome of the legacy-API storage and EveryAyah permission questions. Re-check this inventory if resources are removed or replaced. No app source or canonical religious text was modified by this review.
