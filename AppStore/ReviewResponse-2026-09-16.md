# Haneen — response to Guideline 2.1 information request

Prepared 16 September 2026 for Haneen 1.0 (2). Build 2 is not yet uploaded, and App Store Connect still contains the previous notes for build 1. This is a local draft, not a claim that physical-device checks or the recording are complete. Email delivery configuration remains pending. Before sending, finish those prerequisites, replace the draft/pending lines with verified recording and selected-build details, and verify all evidence links. Public source references are not a blanket rights certificate.

## Copy-ready response / App Review notes

```text
DRAFT for Haneen 1.0 (2), not yet uploaded. App Store Connect still has the previous notes for build 1.

1. Physical-device demonstration
Physical-device recording is being prepared and will be attached before resubmission. It will show launch, setup, core features, registration, sign-in and deletion. Email delivery setup and physical account-flow checks remain pending.

2. Purpose, audience and value
Haneen is a free Arabic/English Islamic companion for Qur'an reading, sourced duas/hadith and daily prayer/dhikr. It includes readings by feeling/life situation, adhkar, counters, goals, private notes, prayer times, Qibla, nearby places and widgets. It is not a medical or counselling service.

3. Setup and feature access
At launch, select "Use Haneen without an account". All core features are available as a guest; no credentials, membership, invitation or payment are required.
Open Qur'an, choose a surah, and tap an ayah for Listen, Save and More. More opens translation, tafsir, highlights and notes. Du'as contains collections; Home > All feelings opens related readings. Explore contains life situations and nearby searches. Saved > My ayat opens saved ayat/notes.
For prayer times, use Home > Use my location and allow location access. Calculation settings are in Settings. Home > Qibla uses the iPhone compass. Reading, duas and local saving remain available if location is denied. Notifications are optional. Add widgets using the iOS widget gallery; configure prayer times first.
Settings > Account offers Apple, Google and email. New and returning users both choose Continue with email, then open the email link on this iPhone or enter its code and tap Verify & continue. No password or separate Sign up choice is needed. Account > Delete account offers optional feedback; leave "Prefer not to say" and feedback blank, tap Delete account and confirm. Apple-linked deletion may request fresh Apple authorisation. Signing out/deleting the account leaves the separate local library on the iPhone.

4. External services and data
Supabase Authentication supports Apple, Google and email sign-in and account deletion. Account identity/session data and optional deletion feedback go to Supabase; sign-in does not upload notes or bookmarks. EveryAyah supplies streamed/cached recitation. Quran.com's API supplies online tafsir. Nearby searches send location/category to Apple Maps and OpenStreetMap Overpass (overpass-api.de). Apple location services resolve place names. Other source links open cited websites. Full morning/evening adhkar by Abu Islam are bundled for offline playback. Optional SoundCloud source links open externally only when tapped; no SoundCloud SDK or API is used.
Qur'an text and the dua/hadith catalog are bundled. Notes, reading progress, preferences and dhikr counts are local. Prayer calculations use the on-device Adhan library; reminders are local notifications. No payments, subscriptions, ads, public UGC, messaging or runtime AI service. Illustrations are static; sharing uses the iOS share sheet.

5. Regional differences
Features are the same across regions. Users choose Arabic/English. Prayer times vary by location, time zone and calculation settings; nearby results and online availability depend on provider coverage. There are no regional paid tiers.

6. Content documentation
Sources and font credits are in Settings > Sources, privacy & credits. Relevant public documentation:
Quran Foundation terms: https://api-docs.quran.com/legal/developer-terms/
Selected hadith: https://sunnah.com/about
IndoPak author notice: https://github.com/marwan/indopak-quran-text/blob/1e2042e4159281194ba91bb80aa1f6716e01ec26/%28Important%29%20Readme.txt
These are public source/terms references, not a claim that every third-party use has been cleared.
Privacy: https://isharaf6.github.io/Sakina/privacy.html
Support: islamsharaf2005@gmail.com
```

## Internal evidence and submission checks

- Guest access and five tabs: `Sakina/App/CompanionOnboarding.swift` and `Sakina/App/SakinaApp.swift`.
- Account registration, email links/codes, Apple/Google ID tokens, optional deletion feedback and Apple reauthorisation: `Sakina/Account/CompanionAccount.swift`. Do not claim these were tested on a physical device just because the code implements them.
- Prayer setup is location-based in the exposed UI: `Sakina/Views/HomeView.swift` and `Sakina/Views/SettingsView.swift`. A service method supports coordinates supplied manually, but no manual-city picker is exposed in the current interface. The prior review notes' manual-city statement should be replaced, not repeated.
- Ayah actions and saved library: `Sakina/Mushaf/AyahActionSheet.swift`, `Sakina/Mushaf/AyahLibrary.swift`, `Sakina/Views/LibraryView.swift`.
- Full morning/evening adhkar recordings by Abu Islam: `Sakina/Resources/Adhkar/adhkar-morning.mp3` and `adhkar-evening.mp3`, presented through `Sakina/Audio/AdhkarRecording.swift` and `Sakina/Duas/DuasView.swift`. Audio is bundled for local/offline playback; optional source links open SoundCloud externally only when tapped. No SoundCloud SDK, API or embedded player is used in the app. Source URLs, file hashes, measured durations and the developer’s report of creator permission are recorded in `AppStore/AdhkarAudioProvenance.md`. Per-dua chapter matching is not asserted by these notes; verify the exact selected build and recorded player controls before submitting.
- Online providers: `Sakina/Mushaf/TafsirService.swift`, `Sakina/Audio/RecitationCache.swift`, `Sakina/Places/NearbyPlacesService.swift`, `Sakina/Prayer/PrayerLocationService.swift`. Overpass uses `overpassEndpoints.prefix(1)`, so only `overpass-api.de` is contacted; two other declared endpoints are dormant.
- Local prayer calculations: `Sakina/Prayer/PrayerTimesService.swift`; local notifications: `Sakina/App/CompanionReminders.swift`.
- Google Drive backup requires `HaneenGoogleBackupEnabled == true`; the release configuration does not enable that key. Do not describe the account as synchronising notes. `Sakina/Account/GoogleBackupService.swift` contains future/disabled backup code.
- Scholar content is disabled at the root with a nil client and no disk cache. Do not present the separate private editorial dashboard as a shipped feature or public UGC platform.
- No runtime AI provider/API or payment flow was found in the app/shared/widget source and dependencies. `StoreKit` use in `SupportView.swift` requests an App Store rating, not a purchase. Static development-generated illustrations do not constitute an AI chat/generation feature in the app.
- Regional behaviour was checked in localisation, prayer settings and location code. No storefront/country feature gate was found. This does not promise that third-party networks are reachable in every country.
- The feature and backend descriptions must match the exact build selected in App Store Connect. The video is still required even though no credentials are needed for guest review.
