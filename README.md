# Yaqeen · يقين

**Certainty in every step.** Yaqeen is a bilingual iOS companion for finding Qur’anic guidance, carefully sourced hadith, and du’a in a specific season of life.

The app is organised around the question a person is actually carrying. Instead of browsing abstract chapters, the flow is:

```text
Life group → stage → feeling or situation → Qur’an / Hadith / Du’a
```

For example: **Marriage → Before marriage → Looking for a spouse**.

## Experience

The 84 situations are arranged into five human-centred groups:

- **Marriage** — before marriage, growing together, hard seasons, separation and grief
- **Family & Parenthood** — children, the home, absence, and longing
- **Faith & Worship** — connection, prayer, gratitude, and returning to Allah
- **Worry & Hardship** — fear, healing, loneliness, worth, and comparison
- **Work & Provision** — daily needs, work, debt, contentment, and decisions

Each guidance page separates its material into clear source tabs:

- **Qur’an:** Uthmani-script ayat, English meaning, verse-by-verse recitation, a short pastoral note, and a link to tafsir for the exact ayah
- **Hadith:** Arabic and English text, collection and number, grading metadata, source link, and an explanation of whether the hadith is directly applicable or a supporting principle
- **Du’a:** Arabic, optional transliteration, meaning, context, source metadata, and clearly marked excerpts where the du’a comes from a longer text

The notes are orientation, not tafsir, a fatwa, or professional counselling. Sensitive relationship situations can show an additional safety notice; reconciliation language is never intended to encourage someone to remain in danger.

## Features

- A one-screen Home: next prayer in a dark hero card, six feeling chips that open a du’a in one tap, a seven-day heart strip, and today’s collection, ayah, last reading and Qibla as badge tiles
- A Du’a & dhikr tab with 15 collections (146 source-verified readings across morning, evening, before sleep, tahajjud, in salah, after salah, ummah, ruqyah & illness, praise, salawat, Qur’anic, Sunnah, istighfar, dhikr and the 99 names), a 31-feeling chip cloud, and search across feelings, titles, Arabic, sources and names
- A paged reader that shows Arabic, pronunciation and meaning together, a tap-to-count recitation ring wherever the source states a count, source-and-context sheets, and a completion mark that remembers what you finished today
- White canvas with a green accent, original pencil-style collection artwork and a cream-and-charcoal cat, quiet utility icons, hairline cards, springy press feedback, graded haptics, and an eight-point star-and-cross field drawn behind every screen at ten percent
- An optional 30-second nature breathing pause, available offline; it is not presented as a prescribed religious practice
- Branded Yaqeen interface in forest green and warm ivory, built with native SwiftUI navigation, Dynamic Type, dark mode, reduced-motion support, and Arabic-aware layout
- English and Arabic app modes, including right-to-left navigation in Arabic
- Home screen with the next prayer, countdown, and today’s Fajr, sunrise, Dhuhr, Asr, Maghrib, and Isha times
- Location-based prayer calculations using Adhan, with calculation-method, Asr-method, and high-latitude preferences
- Ayah of the day and direct access to the life groups
- Search across English and Arabic situation and group names
- A verified-scholar profile and published, bilingual scholarly insight cards when the optional public content service is configured
- Three reciters, adjustable Qur’an text size, optional English meaning, and optional du’a transliteration
- Saved situations and private reflections stored locally with SwiftData
- Optional Google Drive backup and restore for saved situations and reflections
- Daily reminder notifications
- Home Screen widgets for Ayah of the Day, a Pinned Situation, and the full prayer schedule
- Lock Screen prayer widgets in inline, circular, and rectangular families
- A private Qibla compass using the device heading and current location

Prayer widgets use the most recent schedule prepared by the main app. Open **Settings → Prayer times → Set from my location** at least once before adding the widget.

## Requirements

- Xcode 16 or later
- iOS 17 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- An Apple Development Team and registered App Group for a signed device build
- Optional: a Supabase project for the verified-scholar editorial workflow
- Optional: Node.js 22+ for the private scholar dashboard and guidance-manifest generator
- Optional: a Google OAuth iOS client if Google backup is required

The Swift Package dependencies are declared in `project.yml`:

- [Adhan Swift](https://github.com/batoulapps/adhan-swift) 1.5+
- [Google Sign-In for iOS](https://github.com/google/GoogleSignIn-iOS) 9.0+
- [Supabase Swift](https://github.com/supabase/supabase-swift) 2.46+

## Build and run

From the repository root:

```bash
brew install xcodegen       # only if XcodeGen is not installed
xcodegen generate
open Sakina.xcodeproj
```

Choose the **Sakina** scheme, select an iPhone simulator or signed device, and run. The target retains the internal Sakina name and bundle identifier for migration compatibility; the installed app is displayed as **Yaqeen**.

Whenever targets, packages, entitlements, build settings, or generated plist values change, regenerate the Xcode project:

```bash
xcodegen generate
```

Run the integrity test suite with an installed simulator name from your Xcode version:

```bash
xcodebuild test \
  -project Sakina.xcodeproj \
  -scheme Sakina \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

If that simulator is unavailable, replace `iPhone 17 Pro` with a device reported by `xcrun simctl list devices available`.

## Configure verified-scholar content

The public app works without this service: it labels the locally supplied name, portrait, and links as an unverified placeholder and shows no scholar insight prose. Only a profile returned by the verified public endpoint (or a previously endpoint-verified profile saved for offline use) is presented as verified. A successful empty profile response clears that saved public profile and its insights. Once configured, the app reads only public profiles and published insights. Drafts and editorial accounts remain inside the separate, access-controlled dashboard.

1. Create a Supabase project and apply the migrations under `supabase/migrations/`.
2. Deploy the Edge Functions and synchronise `supabase/manifests/guidance-manifest.json` using the instructions in `supabase/README.md`.
3. Invite the scholar and an administrator through Supabase Auth, assign their roles, create the profile, upload the supplied portrait, then explicitly verify and publish the profile.
4. Copy `Config/ScholarBackend.example.xcconfig` to the ignored `Config/ScholarBackend.xcconfig` and add the project URL and publishable key. Use that file as the local/CI build configuration (for command-line builds, pass `-xcconfig Config/ScholarBackend.xcconfig`), or set the same `YAQEEN_SCHOLAR_SUPABASE_URL` and `YAQEEN_SCHOLAR_SUPABASE_PUBLISHABLE_KEY` values in your release build settings. Never put a secret/service-role key in the app.
5. Copy `scholar-dashboard/.env.example` to `scholar-dashboard/.env.local`, add the same public browser values, then run:

   ```bash
   cd scholar-dashboard
   npm install
   npm run dev
   ```

The dashboard has no public registration. A valid invited Auth session and an `admin` or `scholar` row are required in production. Development demo data is available only when Vite is running in development without Supabase configuration; a production build fails closed when configuration is absent.

The source-of-truth workflow is:

```text
App catalog → generated manifest → private review queue → Arabic draft
→ generated English draft → human translation review → admin publication
→ read-only public iOS content
```

## Configure Google backup

The repository intentionally contains no OAuth client values. Google backup UI remains hidden until real credentials are supplied; no shared client secret or production OAuth credential is committed.

1. Create or select a project in [Google Cloud Console](https://console.cloud.google.com/).
2. Configure the OAuth consent screen and enable the [Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com).
3. Create an **iOS OAuth client** for bundle ID `com.islamsharaf.sakina`.
4. Add these build settings in `project.yml` under the `Sakina` target:

   ```yaml
   GOOGLE_CLIENT_ID: 123-example.apps.googleusercontent.com
       GOOGLE_REVERSED_CLIENT_ID: com.googleusercontent.apps.123-example
   ```

5. Add `GIDClientID: $(GOOGLE_CLIENT_ID)` to the target's `info.properties`,
   then add a second `CFBundleURLTypes` entry whose scheme is
   `$(GOOGLE_REVERSED_CLIENT_ID)`.

6. Run `xcodegen generate` again, then rebuild the app.

At sign-in, Yaqeen requests the narrow `https://www.googleapis.com/auth/drive.appdata` scope. A backup is stored as `yaqeen-private-backup.json` in Google Drive’s hidden `appDataFolder`; it does not appear among the user’s normal Drive files.

Backup remains local-first and is not a multi-device real-time sync engine:

- While signed in, saving or deleting a situation or reflection triggers a best-effort private backup.
- **Back up now** lets the user explicitly replace the private backup with the current library.
- **Restore & merge** merges that backup into the device, preferring the newer version of a reflection with the same sync ID.
- Signing out leaves local SwiftData records on the device.
- Disconnecting revokes this app’s Google access when Google’s revoke endpoint is available. It does not delete the existing Drive backup.

Google Sign-In setup details are available in Google’s [iOS integration guide](https://developers.google.com/identity/sign-in/ios/start-integrating), and the storage model is described in the [Drive app data guide](https://developers.google.com/workspace/drive/api/guides/appdata).

## Signing, App Groups, and widgets

Set the same Apple Development Team on the app and widget targets. Register and retain this App Group on both targets:

```text
group.com.islamsharaf.sakina
```

The App Group carries only widget-facing state: the pinned situation and a coordinate-free prayer schedule. The schedule contains a display label, time zone, calculation settings, and calculated times; raw latitude and longitude are not copied into shared widget storage.

## Privacy

- Reflections and saved situations are local-first and stored in the app’s SwiftData store.
- Google Drive is contacted only after the user signs in; library changes then trigger backup, and restore remains explicit.
- Location permission is requested contextually when the user asks Yaqeen to set or refresh prayer times.
- Coordinates are used on-device to calculate prayer times and are not included in the shared widget schedule or Google backup.
- Qur’an recitation streams from EveryAyah; audio files are not bundled.
- When configured, the public app fetches only a verified scholar profile and published insight content from Supabase. Bookmarks, reflections, searches, prayer location, and Google backup data are not sent to the scholar service.
- No analytics or advertising SDK is configured in this project.
- Du’a favorites and the last-read du’a ID stay in local UserDefaults. They are separate from the optional Google backup of saved situations and reflections.

## Content integrity

`Shared/Resources/verses.json` contains 71 ayat used across all 84 situations. The Arabic is Quran.com API v4 Uthmani text. The visible English is the Saheeh International text with API HTML footnote markers removed for display. Do not casually retype or normalise the Arabic glyphs.

The unit tests verify that:

- every situation resolves all of its ayah references;
- verse keys, Arabic, translation, and audio IDs agree;
- every situation appears exactly once in the new group-and-stage navigation;
- the reviewed Qur’an payload still matches its frozen SHA-256 checksum.

Hadith and du’a live in a separate curated catalog with canonical source URLs, text-form metadata, applicability labels, and structural validation. Guidance pages link outward to the exact Quran.com tafsir or canonical hadith source so the reader can continue with fuller scholarship.

## Project structure

| Path | Purpose |
|---|---|
| `Shared/GuidanceCatalog.swift` | User-facing life groups, stages, prompts, and Arabic situation labels |
| `Shared/QuranCatalog.swift` | The 84 situations, source metadata, verse references, and contextual notes |
| `Shared/CompanionContent.swift` | Vetted hadith, du’a, applicability metadata, source links, and safety notices |
| `Shared/Resources/verses.json` | Reviewed embedded Qur’an payload |
| `Shared/PrayerSchedule.swift` | Coordinate-free schedule models shared with WidgetKit |
| `Sakina/Prayer/` | Location request, Adhan calculation settings, and schedule generation |
| `Sakina/Qibla/` | On-device Qibla bearing and heading interface |
| `Sakina/Scholar/` | Public verified profile, published insight client, local published-content cache, and SwiftUI presentation |
| `Sakina/Account/GoogleBackupService.swift` | Google Sign-In and manual Drive `appDataFolder` backup/restore |
| `Sakina/Views/` | Home, Explore, guidance detail, Saved, Settings, and About interfaces |
| `SakinaWidget/SakinaWidgets.swift` | Ayah, pinned-situation, Home Screen prayer, and Lock Screen prayer widgets |
| `SakinaTests/ContentIntegrityTests.swift` | Navigation and Qur’an payload integrity checks |
| `SakinaTests/ScholarContentTests.swift` | Public scholar configuration, decoding, keying, and cache tests |
| `scholar-dashboard/` | Invite-only React dashboard for scholar and administrator editorial work |
| `supabase/` | Database migrations, RLS policies, Edge Functions, manifests, and backend deployment notes |
| `scripts/generate-guidance-manifest.mjs` | Deterministic app-catalog to review-queue manifest generator |
| `Design/Scholar/` | Accepted dashboard concepts and implementation design specification |
| `Design/YaqeenAppIcon-1024.png` | Master Yaqeen icon artwork |
| `project.yml` | XcodeGen source of truth for targets, packages, plist values, and entitlements |

## Current interface

The latest white-and-green redesign uses Mobbin reading/discovery references and Chris Raroque’s interaction principles. See `Design/PracticeAndFeelings/DesignNotes.md` for the current design, content scope and verification. Earlier visual passes remain in `Design/WhiteGreen/` for history.

## Attribution

- [Heroicons](https://github.com/tailwindlabs/heroicons) 2.2.0 is bundled under its MIT license; see `Sakina/Resources/Heroicons-LICENSE.txt`.
- The locally bundled forest photograph was created with the built-in image generator; provenance and the revised design references are in `Design/Sanctuary/DesignNotes.md`.
- KFGQPC HAFS Uthmanic Script is bundled for Qur’anic Arabic.
- Qur’an text and visible translation data are sourced from the [Quran.com API](https://api-docs.quran.com/docs/category/quran.com-api).
- Recitation audio streams from [EveryAyah](https://everyayah.com/).
- Prayer times are calculated on-device with [Adhan Swift](https://github.com/batoulapps/adhan-swift).
