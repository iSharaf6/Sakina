# Haneen — response to Guideline 2.1 information request

Updated 17 September 2026 for planned **Haneen 1.0 (3)**. Current state: [ReleasePolish-2026-09-17.md](ReleasePolish-2026-09-17.md). This draft is not evidence that build 3 has been uploaded, selected or submitted. The contact email and earlier notes were updated live; the build-3 copy below is a local draft until separately saved in App Store Connect.

Production email now delivers, and a returning email code created a session successfully; sign-out returned HTTP 204. That backend check does not establish a completed physical-iPhone account lifecycle. Apple's actual 14 September Guideline 2.1 message still requests physical-device recording, and no waiver has been received. Keep this response unsent until the selected build and physical evidence are ready. Replace `VIDEO EVIDENCE PENDING` only with verified evidence. The owner declined sending the prepared content-provider permission questions; they remain unsent and the scope questions unconfirmed.

## Response text / App Review notes

```text
Haneen 1.0 (3) — App Review information

1. Physical-device demonstration
VIDEO EVIDENCE PENDING: attach the requested physical-iPhone walkthrough on the latest released OS, showing launch, setup, core use, registration, returning sign-in and account deletion. Recording and physical-device account checks are not yet complete.

2. Purpose and access
Haneen is a free Arabic/English Islamic companion for Qur'an, sourced duas/hadith and daily prayer/dhikr. Choose "Use Haneen without an account" at launch. All core features work as a guest, without credentials, membership, invitation or payment. It is not a medical or counselling service.

3. Feature walkthrough
Qur'an > choose a surah > tap an ayah for Listen, Save and More. More opens translation, tafsir, highlights and notes. Saved > My ayat opens saved ayat/notes.
Du'as > Morning or Evening offers a full offline Abu Islam recording, play/pause, seeking and 15-second skips. Fifteen matched readings have individual excerpts, including Surah an-Nas. Playback does not advance the repetition counter.
Audio continues after leaving its reader, with an in-app mini-player and iOS media controls showing Haneen artwork. Settings > About Haneen includes the creator and grandparents' dedication; Settings also offers optional sharing, feedback and rating.
Home > All feelings opens related readings. Explore contains life situations and nearby mosque/halal-place searches.
For prayer times, Home > Use my location; Settings contains calculation options. Home > Qibla uses the physical compass. Reading and local saving still work if location is denied. Notifications are optional. Add widgets through the iOS gallery after setting a location.

4. Optional accounts and deletion
Settings > Account offers Apple, Google and email. New and returning email users enter their email, tap Continue with email, then open its link on this iPhone or enter its code and tap Verify & continue. No password or separate Sign up selector. The welcome email sheet uses Continue and Sign in for this same process.
Account > Delete account: feedback is optional. Leave Prefer not to say and the feedback blank, tap Delete account, then confirm. Apple-linked deletion may require fresh Apple authorisation. Sign-out/deletion keeps the separate local library; sign-in does not upload or sync notes/bookmarks.

5. Services, data and regions
Supabase handles identity/session data and optional deletion feedback; Brevo delivers sign-in emails. EveryAyah supplies streamed/cached Quran audio; Quran.com's API supplies online tafsir. Nearby searches send location/category to Apple Maps and OpenStreetMap Overpass (overpass-api.de). Apple location services resolve place names.
Quran text, dua/hadith content and morning/evening recordings are bundled. Optional SoundCloud source links open externally only when tapped; no SoundCloud SDK, API or embedded player is used.
Notes, progress, preferences, dhikr counts and review-prompt timing are local. Prayer calculations use Adhan on-device; reminders are local notifications. No payments, subscriptions, ads, public UGC, messaging or runtime AI. Sharing uses the iOS share sheet; ratings use StoreKit without score filtering.
Mainland China is excluded. In Apple-required regions, a system age-range check may appear after setup. Its response is processed on-device, not stored or uploaded. Core features are otherwise the same across offered regions. Users choose Arabic/English. Prayer times depend on location/time zone/settings; online availability varies.

6. Content and contact
Sources/font credits: Settings > Sources, privacy & credits.
Quran Foundation: https://api-docs.quran.com/legal/developer-terms/
Hadith: https://sunnah.com/about
The developer reports Abu Islam's permission to include his recordings; the player credits him.
Privacy: https://isharaf6.github.io/Sakina/privacy.html
Support: https://isharaf6.github.io/Sakina/app.html
Contact: haneen.app.contact@gmail.com
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
- No runtime AI provider/API or payment flow was found in the app/shared/widget source and dependencies. `StoreKit` use in `CompletionReviewPrompt.swift` requests an App Store rating, not a purchase. The explicit Settings rating button opens the App Store review URL. Static development-generated illustrations do not constitute an AI chat/generation feature in the app.
- Mainland China is excluded from store availability. Other core features are consistent across offered regions; Apple may require the regional age-range check described below. Provider availability still varies by country.
- The feature and backend descriptions must match the exact build selected in App Store Connect. The video is still required even though no credentials are needed for guest review.

## Regional age check — current implementation

`Sakina/App/AgeAssurance.swift` first checks Apple's eligibility on iOS 26.2 and later; an ineligible account skips the age prompt. On iOS 26.4 and later, an eligible account is then checked for the declared-age-range regulatory requirement. Checks run after onboarding/presented screens close. An age-range response is processed only in memory and discarded; no age, birth date or age category is saved or uploaded by Haneen. A required check must complete to continue; an eligible parent-approved child is not rejected solely for being under 13. Apple handles initial-download parental consent and launch revocation. This is not a claim that device/Sandbox account scenarios have passed.
