# Haneen — response to Guideline 2.1 information request

Prepared 17 September 2026 for Haneen 1.0 (2). This is the replacement response text for the corrected build, not evidence that it has been uploaded or selected. The copy below matches the current unified email flow and bundled audio; its 3,961-character notes are saved in App Store Connect, while the review response is still unsent. No physical-device test, production email delivery test or completed video is claimed.

Before sending: confirm the corrected build is selected, verify production email delivery and the account lifecycle on the physical iPhone, attach the real walkthrough, and replace the `VIDEO EVIDENCE PENDING` paragraph with its verified attachment/link and timestamps. Brevo custom SMTP was saved and rechecked on 17 September, but the delivery test returned SMTP 535 (authentication failed). The owner is correcting the SMTP credentials; successful delivery remains unverified. Keep the response draft unsent until those checks are complete. Public source references do not certify third-party rights.

## Response text / App Review notes

```text
Haneen 1.0 (2) — App Review information

1. Physical-device demonstration
VIDEO EVIDENCE PENDING: attach the requested physical-iPhone walkthrough before resubmission, showing launch, setup, core features, registration, returning sign-in and deletion. The recording and device checks are not yet complete.

2. Purpose and access
Haneen is a free Arabic/English Islamic companion for Qur'an, sourced duas/hadith and prayer/dhikr routines. At launch, select "Use Haneen without an account". All core features are available as a guest, without credentials, membership, invitation or payment. It is not a medical or counselling service.

3. Feature walkthrough
Open Qur'an, choose a surah and tap an ayah for Listen, Save and More. More opens translation, tafsir, highlights and notes. Saved > My ayat opens saved ayat/notes.
Du'as contains collections, including Morning and Evening. Both have a full offline Abu Islam recording, play/pause, seeking and 15-second skips. Fifteen matched readings also offer an individual excerpt, including Surah an-Nas. Excerpt playback does not advance the repetition counter.
Home > All feelings opens related readings. Explore contains life situations and nearby mosque/halal-place searches.
For prayer times, use Home > Use my location and allow location access. Settings contains calculation settings. Home > Qibla uses the physical iPhone compass. Reading, duas and local saving work if location is denied. Notifications are optional. Add widgets through the iOS widget gallery after configuring prayer times.

4. Optional accounts and deletion
Settings > Account offers Apple, Google and email. New and returning email users enter an email and tap Continue with email, then open the email link on this iPhone or enter its code and tap Verify & continue. No password or separate Sign up choice is needed. The welcome email sheet uses Continue and Sign in for the same process.
Account > Delete account offers optional feedback: leave Prefer not to say selected and feedback blank, tap Delete account and confirm. Apple-linked deletion may request fresh Apple authorisation. Signing out/deleting the account leaves the separate local library on the iPhone. Sign-in does not upload or sync notes/bookmarks.

5. Services, data and regions
Supabase Authentication handles account identity/session data and optional deletion feedback. Brevo delivers sign-in emails. EveryAyah supplies streamed/cached Quran recitation; Quran.com's API supplies online tafsir. Nearby searches send location/category to Apple Maps and OpenStreetMap Overpass (overpass-api.de). Apple location services resolve place names.
Quran text, the dua/hadith catalog and morning/evening recordings are bundled. Adhkar playback is offline; optional SoundCloud source links open externally only when tapped. No SoundCloud SDK, API or embedded player is used.
Notes, progress, settings and dhikr counts are local. Prayer calculations use Adhan on-device; reminders are local notifications. There are no payments, subscriptions, ads, public UGC, messaging or runtime AI service. Sharing uses the iOS share sheet; illustrations are static.
Mainland China is excluded. In Apple-required regions, a system age-range check may appear after setup. Haneen processes the response on-device without storing or uploading age data. Other features are the same in offered regions. Users choose Arabic/English. Prayer times depend on location/time zone/settings; online provider availability varies. There are no regional paid tiers.

6. Content and contact
Sources and font credits: Settings > Sources, privacy & credits.
Quran Foundation terms: https://api-docs.quran.com/legal/developer-terms/
Hadith references: https://sunnah.com/about
Abu Islam permitted the developer to include his recordings and is credited in the player.
Privacy: https://isharaf6.github.io/Sakina/privacy.html
Support: https://isharaf6.github.io/Sakina/app.html
Contact: islamsharaf2005@gmail.com
```

## Internal evidence and submission checks

- Guest access and five tabs: `Sakina/App/CompanionOnboarding.swift` and `Sakina/App/SakinaApp.swift`.
- Account registration, email links/codes, Apple/Google ID tokens, optional deletion feedback and Apple reauthorisation: `Sakina/Account/CompanionAccount.swift`. Do not claim these were tested on a physical device just because the code implements them.
- Prayer setup is location-based in the exposed UI: `Sakina/Views/HomeView.swift` and `Sakina/Views/SettingsView.swift`. A service method supports coordinates supplied manually, but no manual-city picker is exposed in the current interface. The prior review notes' manual-city statement should be replaced, not repeated.
- Ayah actions and saved library: `Sakina/Mushaf/AyahActionSheet.swift`, `Sakina/Mushaf/AyahLibrary.swift`, `Sakina/Views/LibraryView.swift`.
- Full morning/evening adhkar recordings by Abu Islam: `Sakina/Resources/Adhkar/adhkar-morning.mp3` and `adhkar-evening.mp3`, presented through `Sakina/Audio/AdhkarRecording.swift` and `Sakina/Duas/DuasView.swift`. Audio is bundled for local/offline playback; optional source links open SoundCloud externally only when tapped. No SoundCloud SDK, API or embedded player is used in the app. Source URLs, file hashes, measured durations and the developer’s report of creator permission are recorded in `AppStore/AdhkarAudioProvenance.md`. Fifteen matched per-dua excerpts are mapped in `AdhkarAudioSections.json`; each plays one recitation without changing the counter. Verify the selected build and physical player controls before submitting.
- Online providers: `Sakina/Mushaf/TafsirService.swift`, `Sakina/Audio/RecitationCache.swift`, `Sakina/Places/NearbyPlacesService.swift`, `Sakina/Prayer/PrayerLocationService.swift`. Overpass uses `overpassEndpoints.prefix(1)`, so only `overpass-api.de` is contacted; two other declared endpoints are dormant.
- Local prayer calculations: `Sakina/Prayer/PrayerTimesService.swift`; local notifications: `Sakina/App/CompanionReminders.swift`.
- Google Drive backup requires `HaneenGoogleBackupEnabled == true`; the release configuration does not enable that key. Do not describe the account as synchronising notes. `Sakina/Account/GoogleBackupService.swift` contains future/disabled backup code.
- Scholar content is disabled at the root with a nil client and no disk cache. Do not present the separate private editorial dashboard as a shipped feature or public UGC platform.
- No runtime AI provider/API or payment flow was found in the app/shared/widget source and dependencies. `StoreKit` use in `SupportView.swift` requests an App Store rating, not a purchase. Static development-generated illustrations do not constitute an AI chat/generation feature in the app.
- Mainland China is excluded from store availability. Other core features are consistent across offered regions; Apple may require the regional age-range check described below. Provider availability still varies by country.
- The feature and backend descriptions must match the exact build selected in App Store Connect. The video is still required even though no credentials are needed for guest review.

## Regional age check — current implementation

`Sakina/App/AgeAssurance.swift` first checks Apple's eligibility on iOS 26.2 and later; an ineligible account skips the age prompt. On iOS 26.4 and later, an eligible account is then checked for the declared-age-range regulatory requirement. Checks run after onboarding/presented screens close. An age-range response is processed only in memory and discarded; no age, birth date or age category is saved or uploaded by Haneen. A required check must complete to continue; an eligible parent-approved child is not rejected solely for being under 13. Apple handles initial-download parental consent and launch revocation. This is not a claim that device/Sandbox account scenarios have passed.
