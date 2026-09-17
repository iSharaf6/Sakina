# Haneen — App Store listing

English (Australia), planned **1.0 (5)**, updated 17 September 2026. Local draft only; not saved in App Store Connect by this task. Mandatory account access and synced library replace all earlier guest/local-only descriptions. See [ReleaseReadiness-1.0-5.md](ReleaseReadiness-1.0-5.md) for unresolved review access, recording and policy publication.

## Name

Haneen

## Subtitle

Quran, Dua & Prayer Times

## Promotional text

Read Qur’an, find a du’a for the moment you’re in, and keep prayer times close with illustrated widgets. In Arabic and English, with no ads or subscriptions.

## Keywords

dhikr,tasbih,counter,azkar,qibla,compass,widget,muslim,offline,reader,ruqyah,morning,evening,anxiety

## Description

Read Qur’an, keep up with prayer, and find words for what you’re feeling. Haneen brings your daily worship together in Arabic and English, with warm illustrations and room to make it your own.

Read the full Qur’an in a traditional mushaf or a flexible digital reader. Tap an ayah to listen, save it, add a note or explore its meaning. Choose the text size, translation and transliteration that suit you, and return to your reading place whenever you’re ready.

Begin with how you feel, or explore moments in life such as marriage, family, work and faith. Find related Qur’an passages, du’as and hadith references alongside morning and evening adhkar and everyday supplications. Reported virtues include their source and conditions, with explanations in Arabic and English.

Keep the essentials close:
• Prayer times with your preferred calculation settings
• A Qibla compass and nearby mosque search
• Ten illustrated widget designs, with Home Screen and Lock Screen options
• Morning and evening adhkar with full offline recordings by Abu Islam and selected individual excerpts
• A dhikr counter and optional reminders
• Du’a translation and transliteration controls
• An account library for saved ayat, notes, reflections and reading positions
• Arabic and English layouts, with light, dark and system appearance

No ads, subscriptions or in-app purchases. Sign in with Apple, Google or email to use Haneen and restore your personal library across devices. Saved readings, notes, reflections, categories and reading positions sync to your account. On upgrading, you choose whether to add an existing local library to that account. Daily goals, dhikr counters and prayer settings remain on each device.

The Qur’an text and morning/evening adhkar recordings are included in the app. After signing in and preparing your library, a saved session lets you read bundled content offline; edits sync when you reconnect. An internet connection is needed for sign-in, cloud restore/sync, streamed recitation, online tafsir and nearby searches.

## Review notes

Haneen 1.0 (5) — App Review information DRAFT

1. Evidence and reviewer access
VIDEO EVIDENCE PENDING: Apple's Guideline 2.1 request asks for a physical-iPhone walkthrough on the latest released OS, including launch, registration, returning sign-in and deletion. No waiver has been received.
REVIEWER ACCESS: this build requires an account. Tap Continue with email, enter haneen.app.contact+review@gmail.com, then enter the password given in App Review Information > Sign-In Information and tap Sign in. The password field appears only for this review address; every other email receives a one-time link or code. OWNER STEP PENDING: create this user in Supabase and enter its password in App Store Connect before submitting.

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

## Public links and contact

- Support: https://isharaf6.github.io/Sakina/app.html
- Privacy: https://isharaf6.github.io/Sakina/privacy.html
- Email: haneen.app.contact@gmail.com

## Submission accuracy

The sign-in-required field, repeatable reviewer authentication, build selection, updated privacy labels/public pages and requested physical-device recording must be completed before submission. A genuine cloud library does not guarantee acceptance of mandatory login under Apple 5.1.1(v). No new console save, deployment, archive, test result or release is claimed by this draft. Content-rights evidence remains a separate review item.

The draft does not advertise the disabled scholar-content/Google Drive features. Its cloud library is the new Supabase account service. Offline language refers to bundled reading/audio after sign-in and library preparation; cloud authentication/restoration needs a connection. No E2EE, streak or all-widgets-in-all-sizes claim is made.

Search terms reflect real features and routines, not measured ranking performance. Anxiety refers to spiritual reading, not medical treatment. [Apple’s search guidance](https://developer.apple.com/app-store/search/) recommends relevant terms and measurement after launch. Limits are from [Apple’s version-information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

## Field counts

| Field | Characters | Limit |
|---|---:|---:|
| name | 6 | 30 |
| subtitle | 25 | 30 |
| promotionalText | 157 | 170 |
| keywords | 100 | 100 |
| description | 2037 | 4000 |
| reviewNotes | 3781 | 4000 |
