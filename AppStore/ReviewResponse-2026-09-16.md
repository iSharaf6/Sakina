# Haneen — response to Guideline 2.1 information request

Updated 17 September 2026 for planned **Haneen 1.0 (5)**. Current release gates: [ReleaseReadiness-1.0-5.md](ReleaseReadiness-1.0-5.md). This is an unsent local replacement draft. It is not evidence of a new upload, selected build, console save or public deployment. Earlier live notes described guest access and must be replaced before submission.

Production email now delivers, and a returning email code created a session successfully; sign-out returned HTTP 204. That backend check does not establish a completed physical-iPhone account lifecycle. Apple's actual 14 September Guideline 2.1 message still requests physical-device recording, and no waiver has been received. Keep this response unsent until the selected build and physical evidence are ready. Replace `VIDEO EVIDENCE PENDING` only with verified evidence. The owner declined sending the prepared content-provider permission questions; they remain unsent and the scope questions unconfirmed.

## Response text / App Review notes

```text
Haneen 1.0 (5) — App Review information DRAFT

1. Evidence and reviewer access
VIDEO EVIDENCE PENDING: Apple's Guideline 2.1 request asks for a physical-iPhone walkthrough on the latest released OS, including launch, registration, returning sign-in and deletion. No waiver has been received.
REVIEWER ACCESS PENDING: this build requires an account. Provide verified, repeatable reviewer access in App Review Information before submission; no demo credentials are supplied by this draft. Do not rely on the previous guest-access instructions.

2. Purpose and accounts
Haneen is a free Arabic/English companion for Qur'an, sourced duas/hadith and prayer/dhikr. It is not a medical or counselling service. Apple, Google and email are offered to new and returning users. Email uses a one-time link or code, without a password or separate Sign up selector.
Accounts provide a restorable library across devices: saved ayat with notes/highlights/favourites, categories and feeling mappings, saved duas/moments, reflections and Quran/dua/collection reading positions. Supabase stores these under the account ID with per-user access rules. Transfers use HTTPS; the library is not end-to-end encrypted. No public user posts or messaging exist.
After sign-in and library setup, a cached session allows offline reading; edits queue and retry when online. An existing local library is imported only after the user chooses to add it to that account; choosing the cloud library leaves the old unclaimed backup on-device.

3. Walkthrough
Qur'an > choose a surah > tap an ayah for Listen, Save and More (translation, tafsir, highlights and notes). Settings > Your space shows the library, reading place and daily goals. Test a harmless saved note across two signed-in devices, then an offline edit and reconnection.
Du'as > Morning/Evening offers full offline Abu Islam recordings, seeking and skips. Fifteen readings have individual excerpts; playback does not advance repetition counts. Audio continues in the in-app player and iOS media controls.
Home > All feelings and Explore > life topics open related readings. Home > prayer times/Qibla uses optional location; nearby searches send coordinates to providers. Reading works if location is denied. Notifications are optional. Widgets are added through iOS.
Sources/privacy is available before sign-in, and from Settings > Your space > Sources & privacy. Settings also contains About Haneen, sharing, support and optional ratings.

4. Sign-out and deletion
Settings > Your space > Account > Sign out returns to sign-in and isolates that account's cache. It does not delete cloud data.
Delete account accepts blank optional feedback and requires confirmation. Apple-linked deletion may request fresh Apple authorisation. Successful deletion removes the account/cloud library and its cache on this device. Other offline devices may retain cached copies until reconnection or local removal. The app returns to sign-in.

5. Services and regional behaviour
Supabase: authentication, library sync and optional deletion feedback. Brevo: sign-in emails. EveryAyah: Quran audio. Quran.com: tafsir. Apple Maps/Overpass: nearby searches. Apple: geocoding, account/age checks. Adhkar recordings are bundled; optional SoundCloud links open externally, with no SDK or embedded player.
Goals, practice completion, dhikr counters, prayer location/preferences and review timing remain local. No payments, subscriptions, ads or runtime AI. Ratings use StoreKit without score filtering. Mainland China is excluded. Apple-required regional age checks process the response on-device without storing/uploading age data.

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
- The feature and backend descriptions must match the exact build selected in App Store Connect. The video remains requested. Mandatory sign-in means reviewer authentication must now be provided and verified; the old guest-review instructions no longer apply.

## Regional age check — current implementation

`Sakina/App/AgeAssurance.swift` first checks Apple's eligibility on iOS 26.2 and later; an ineligible account skips the age prompt. On iOS 26.4 and later, an eligible account is then checked for the declared-age-range regulatory requirement. Checks run after onboarding/presented screens close. An age-range response is processed only in memory and discarded; no age, birth date or age category is saved or uploaded by Haneen. A required check must complete to continue; an eligible parent-approved child is not rejected solely for being under 13. Apple handles initial-download parental consent and launch revocation. This is not a claim that device/Sandbox account scenarios have passed.


## Build 5 account change — not yet verified for release

The review response must demonstrate the working Supabase account library and its restoration, rather than simply assert that backup makes required sign-in compliant. Apple 5.1.1(v) still governs whether significant account features justify the gate. The library uses account access rules and encrypted transport, not end-to-end encryption. Privacy labels must now add linked Sensitive Info and Product Interaction for App Functionality and expand Other User Content’s functional basis. The public policy and store answers remain pending publication. No demo credentials or video have been fabricated.
