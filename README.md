# Sakina, سَكِينَة

**Quranic first aid for the chapters of life.** 84 situations across seven themed chapters, from seeking marriage to money worries, each opening the exact ayah with the Uthmani script, the Saheeh International translation as served by Quran.com, recitation, bookmarks, private journaling, widgets, and a link to full scholarly tafsir.

Named for the tranquility Allah describes placing between spouses in Surah Ar Rum 30:21.

## Run it

```bash
open Sakina.xcodeproj
```

Select the **Sakina** scheme and an iPhone simulator, then Run. Requires Xcode 16 or newer (built and verified with Xcode 26.6), iOS 17 and up.

If you edit `project.yml` (targets, plist, entitlements), regenerate with:

```bash
xcodegen generate
```

## The seven chapters

I The Search, II The Bond, III The Storm, IV The Family and The Decree, V The Heart, VI The Trials, VII The Provision.

## Features

* Search field on home ("How is your heart today?") filtering all 84 situations instantly
* Ayah of the day, deterministic per date, on home and as a widget
* Verse pages: mushaf typeface Arabic, translation, surah plate, and a conservative "why this ayah" note with a visible reminder that it is not tafsir
* One tap to the full tafsir for that exact ayah on Quran.com
* Recitation streamed verse by verse, choice of three reciters in settings
* Bookmarks and private reflections stored with SwiftData, gathered in the Library
* Shareable verse cards rendered in the app's ink and gold design
* Daily reminder notification at a chosen time, tapping it opens that day's verse
* Two home screen widgets: Ayah of the Day and Pinned Situation, both deep linking into the app
* Arabic text size control, full dark mode, reduced motion support

## Structure

| Path | What it is |
|---|---|
| `Shared/QuranCatalog.swift` | Verse and Situation models, the 84 situations, chapters, and verse notes |
| `Shared/Resources/verses.json` | All 71 ayat, fetched verbatim from the Quran.com API v4. Do not hand edit. |
| `Shared/SharedStore.swift` | App Group storage for widget pinning and the daily verse |
| `Sakina/` | App target: views, theme, settings, SwiftData models, audio player |
| `SakinaWidget/` | WidgetKit extension with both widgets |
| `Design/AppIcon-1024.png` | Master icon (ink gradient plus gold khatam star) |

## Notes

* **Real device and App Store:** set your Development Team on both targets and keep the App Group `group.com.islamsharaf.sakina` registered under your team. For App Store submission, add the 1024px icon through an asset catalog (the repo ships legacy icon PNGs because compiling asset catalogs needs the simulator runtime matching your Xcode SDK).
* **iCloud sync:** SwiftData can sync `Bookmark` and `JournalEntry` through CloudKit once the app is signed with your developer account. Steps: add the iCloud capability with a CloudKit container to the Sakina target in Xcode, then create the model container with `ModelConfiguration(cloudKitDatabase: .automatic)` in `SakinaApp.swift`. Until then all data stays on device.
* **Typeface:** KFGQPC HAFS Uthmanic Script by the King Fahd Glorious Quran Printing Complex, bundled in both targets.
* **Audio** streams from everyayah.com (Alafasy, Husary, Abdul Basit). No audio is bundled.
* **Content integrity:** Arabic and translations are embedded exactly as served by the Quran.com API, and every quotation inside the verse notes was machine checked against that text. The notes are brief reflections on plain meaning with only well established citations (Sahih al Bukhari, Jami at Tirmidhi). They are not tafsir, the app says so on every verse page, and every verse page links to real tafsir on Quran.com.
