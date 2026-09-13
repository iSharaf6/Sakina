# Haneen permission requests — drafts, not sent

Prepared 13 September 2026. These requests cover the two remaining evidence gaps for the existing release. They do not request broad publisher contracts or a paid commercial licence. No email, support request or provider account action has been made.

## Verified recipients

| Request | Recipient / route | First-party evidence |
| --- | --- | --- |
| Quran Foundation API storage | `developers@quran.com` | QF’s [Developer Terms, sections 11–12](https://api-docs.quran.com/legal/developer-terms/) list its notice/contact address. The same [QF-hosted documentation deployment](https://qf-api-docs.pages.dev/legal/developer-terms/) renders the address in plain text. |
| EveryAyah audio | `support@quran.zendesk.com`, asking the support desk to route it to the EveryAyah maintainer if needed | EveryAyah’s own [older index](https://everyayah.com/old_index.html) links “Contact us” to this support centre. Its [official contact article](https://quran.zendesk.com/hc/en-us/articles/206503405-Contact-us) publishes the email; the linked [request form](https://quran.zendesk.com/hc/en-us/requests/new) is also available. This is the verified provider-linked route, not a newly invented direct EveryAyah address. The article dates from 2015; current delivery or maintainer responsibility has not been tested. |

## 1. Quran Foundation

**To:** developers@quran.com  
**Subject:** Haneen — permission for offline legacy Quran API content

Assalamu alaikum,

Haneen is a free, noncommercial iOS app being prepared for public App Store release as sadaqah jariyah. It has no advertising or in-app purchases.

The current build bundles offline snapshots obtained on 10–11 September 2026 from `https://api.quran.com/api/v4`: all 6,236 ayat, Uthmani and IndoPak text, tajweed annotations, Mushaf 1 word/page layout and word transliteration. It also includes translation IDs 20, 85, 22, 19, 203, 84, 95, 149 and 54, obtained through `verses/by_chapter` and `verses/by_page`. Quran.com and the translation editions are credited; HTML and footnote markup are removed for native text display.

These resources remain in the installed app for offline reading, without a seven-day expiry or Content Sync integration. Tafsir IDs 169 and 16 are requested on demand through the legacy API and cached without an age expiry.

Do the current section 3.1.3 storage terms apply to these legacy-endpoint snapshots? If so, may Haneen have express permission to bundle and retain the listed content for offline in-app use in its free public App Store release? If permission requires a different refresh or Content Sync arrangement, please confirm the applicable requirement for these resources.

Jazakum Allahu khayran.

## 2. EveryAyah

**To:** support@quran.zendesk.com  
**Subject:** EveryAyah — streaming and device-cache permission for Haneen

Assalamu alaikum,

EveryAyah’s contact link led me to this support desk. Please route this to its maintainer if needed.

Haneen is a free, noncommercial iOS app being prepared for public App Store release as sadaqah jariyah, with no advertising or in-app purchases.

The app plays selected reciters’ unchanged per-ayah MP3 files from `https://everyayah.com/data/{reciter-folder}/{SSSAAA}.mp3`. Recordings are not included in the App Store download or hosted on our servers. The reader also downloads played and nearby upcoming ayat into an on-device cache: eviction starts above 300 MiB and trims it to 260 MiB, removing the least recently used files. iOS can reclaim this cache and it is excluded from device backups. It has no fixed time expiry. Up to three background prefetches run at once.

May Haneen stream and cache these recordings in this way for its free public App Store release? Please confirm any required attribution, reciter-specific restrictions or cache limits, or direct me to an existing permission covering this use.

Jazakum Allahu khayran.

## What requires a reply, and what does not

- **QF:** its existing terms already grant conditional in-app display. The concrete question is the longer storage in this build. Section 3.1.3 requires express longer-storage permission or the applicable Content Sync route with updates at least every seven days. The clause explaining where to send notices is not itself a “notify and proceed” storage exception. The official [legacy migration guide](https://api-docs.quran.com/docs/quickstart/migration/) confirms endpoint continuity without stating a legacy storage exemption.
- **EveryAyah:** no general audio permission or mandatory notification rule was found in the checked first-party pages. This request fills missing permission evidence; it is not based on a discovered rule requiring every app to email them. Its [timing-file notice](https://everyayah.com/data/timings_files/000_disclaimer.txt) requires a backlink for those timing files, which does not establish the rights for every MP3 recording.
- **IndoPak:** no extra request is drafted. Its author-issued charitable distribution notice, unchanged verified binary and bundled/visible credits are recorded in [ContentRights.md](ContentRights.md).

The cache description was checked against `Sakina/Audio/RecitationCache.swift`: its bound is storage size, not retention time. Snapshot provenance and resource IDs are recorded in `AppStore/ContentRights.md`. Sending these drafts would not itself grant permission; retain any response with the release record.

**Minimal owner decision:** “May I send these two prepared permission requests to the verified contacts?” If the owner already has relevant written permissions, retain and assess those instead of sending duplicate requests. This is the only proposed communication approval; no broad request to approach all translators is needed.
