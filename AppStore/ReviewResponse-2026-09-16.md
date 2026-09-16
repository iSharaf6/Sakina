# Haneen — response to Guideline 2.1 information request

Prepared 16 September 2026 from the current release source. This is a draft, not a claim that a physical-device recording or new device test has been completed. Replace the two evidence placeholders and verify their access before sending. The rights packet is being prepared separately; do not describe a licence or permission as obtained unless that packet supports it.

## Copy-ready response / App Review notes

```text
Thank you for reviewing Haneen. The requested information follows.

1. Physical-device demonstration
[PENDING: video link/attachment, physical iPhone model, iOS version and Haneen version/build.]
The recording must show launch, first-use setup, core features, optional account creation/sign-in, sign-out and account deletion. Haneen has no public user-generated-content platform or paid flows.

2. Purpose, audience and value
Haneen is a free Arabic/English daily Islamic companion for Qur'an reading, sourced supplications/hadith references, and prayer/dhikr routines. It combines a full Qur'an reader, readings by feeling/life situation, morning/evening adhkar, a dhikr counter, goals, private saved readings/notes, prayer times, Qibla, nearby places and widgets. It is not a medical or counselling service.

3. Setup and feature access
At launch, select "Use Haneen without an account". All core features are available as a guest; no credentials, membership, invitation or payment are required.
Open Qur'an, choose a surah, and tap an ayah for Listen, Save and More. More opens translation, tafsir, highlights and notes. Du'as contains the collections; Home > All feelings and Explore > Start with a feeling open relevant readings. Explore also contains life-situation readings and nearby mosque/halal-place searches. Saved > My ayat opens saved ayat and notes.
For prayer times, use Home > Use my location, or Settings > Prayer times > Location > Set, and allow location access. Prayer calculation settings are in Settings. Home > Qibla uses the physical iPhone's compass. Reading, du'as and local saving remain available if location is denied. Notifications are optional. Add widgets using the iOS widget gallery; configure prayer times first for prayer widgets.
Optional accounts are at Settings > Account: Apple, Google, or email sign-in link. New and returning email users use Sign up/Sign in respectively. No password is created. Account > Delete account offers optional feedback; leave "Prefer not to say" and feedback blank, tap Delete account and confirm. Apple-linked deletion may request fresh Apple authorisation. Signing out/deleting the account leaves the separate local library on the iPhone.

4. External services and data
Supabase Authentication supports Apple, Google and email sign-in and account deletion. Account identity/session data and optional deletion feedback go to Supabase; sign-in does not upload notes or bookmarks. EveryAyah supplies streamed/cached recitation. Quran.com's API supplies online tafsir. Nearby searches send location/category to Apple Maps and OpenStreetMap Overpass (overpass-api.de). Apple location services resolve place names. Source links open Quran.com, Sunnah.com and other cited sites.
Qur'an text and the dua/hadith catalog are bundled. Notes, reading progress, preferences and dhikr counts are local. Prayer calculations use the on-device Adhan library; reminders are local notifications. There are no payments, subscriptions, ads, public posts/comments, chat, user-to-user messaging or runtime AI service. Static illustrations are bundled assets. The system share sheet exports only what the user chooses.

5. Regional differences
Features are the same across regions. Users choose Arabic/English. Prayer times vary by location, time zone and calculation settings; nearby results and online availability depend on provider coverage. There are no regional paid tiers.

6. Content documentation
[PENDING: actual attached rights/source documentation filename and an accurate description of what it establishes.]
In-app source links and privacy information: Settings > Sources, privacy & credits.
Privacy: https://isharaf6.github.io/Sakina/privacy.html
Support: islamsharaf2005@gmail.com
```

## Internal evidence and submission checks

- Guest access and five tabs: `Sakina/App/CompanionOnboarding.swift` and `Sakina/App/SakinaApp.swift`.
- Account registration, email links/codes, Apple/Google ID tokens, optional deletion feedback and Apple reauthorisation: `Sakina/Account/CompanionAccount.swift`. Do not claim these were tested on a physical device just because the code implements them.
- Prayer setup is location-based in the exposed UI: `Sakina/Views/HomeView.swift` and `Sakina/Views/SettingsView.swift`. A service method supports coordinates supplied manually, but no manual-city picker is exposed in the current interface. The prior review notes' manual-city statement should be replaced, not repeated.
- Ayah actions and saved library: `Sakina/Mushaf/AyahActionSheet.swift`, `Sakina/Mushaf/AyahLibrary.swift`, `Sakina/Views/LibraryView.swift`.
- Online providers: `Sakina/Mushaf/TafsirService.swift`, `Sakina/Audio/RecitationCache.swift`, `Sakina/Places/NearbyPlacesService.swift`, `Sakina/Prayer/PrayerLocationService.swift`. Overpass uses `overpassEndpoints.prefix(1)`, so only `overpass-api.de` is contacted; two other declared endpoints are dormant.
- Local prayer calculations: `Sakina/Prayer/PrayerTimesService.swift`; local notifications: `Sakina/App/CompanionReminders.swift`.
- Google Drive backup requires `HaneenGoogleBackupEnabled == true`; the release configuration does not enable that key. Do not describe the account as synchronising notes. `Sakina/Account/GoogleBackupService.swift` contains future/disabled backup code.
- Scholar content is disabled at the root with a nil client and no disk cache. Do not present the separate private editorial dashboard as a shipped feature or public UGC platform.
- No runtime AI provider/API or payment flow was found in the app/shared/widget source and dependencies. `StoreKit` use in `SupportView.swift` requests an App Store rating, not a purchase. Static development-generated illustrations do not constitute an AI chat/generation feature in the app.
- Regional behaviour was checked in localisation, prayer settings and location code. No storefront/country feature gate was found. This does not promise that third-party networks are reachable in every country.
- The feature and backend descriptions must match the exact build selected in App Store Connect. The video is still required even though no credentials are needed for guest review.
