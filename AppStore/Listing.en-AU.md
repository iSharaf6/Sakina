# Haneen — App Store listing

English (Australia) copy for Haneen 1.0 (2), updated 17 September 2026. The JSON contains the same customer-facing fields and replacement review instructions. The video-evidence marker must be resolved before the notes are submitted. This file does not assert that the build or metadata is live.

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
• Saved ayat, private notes and bookmarks
• Arabic and English layouts, with light, dark and system appearance

No ads, subscriptions or in-app purchases. You can use the core app without an account, or choose Apple, Google or email sign-in. Your notes and bookmarks stay on your device; signing in does not upload or sync them.

The Qur’an text and morning/evening adhkar recordings are included in the app. An internet connection is needed for streamed recitation, online tafsir, nearby searches and sign-in.

## Review notes
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

## Public links and contact
- Support: https://isharaf6.github.io/Sakina/app.html
- Privacy policy: https://isharaf6.github.io/Sakina/privacy.html
- Support email: islamsharaf2005@gmail.com

## Submission fields still to complete
Before sending, select the corrected build, verify review contact details, finish any account/program declarations, and attach the requested physical-device recording. Confirm production email delivery and the account lifecycle on that build. The saved description is for build 2; do not pair it with the old build 1. Verify the public policy and support copy after publication. Store status and completed tests must be established separately.

## Draft accuracy notes
- Confirmed from the welcome flow and root navigation: core features are available as a guest. No purchase SDK flow or paywall is present; StoreKit is used for the system rating prompt.
- Optional Drive backup is gated by `HaneenGoogleBackupEnabled`, which is absent from the shipping configuration. Editorial content uses a disabled client. Neither feature is advertised in the customer description.
- Widget completion reflects recorded morning/evening adhkar activity, not an inferred streak. The listing does not promise every design in every widget size.
- Qur’an/du’a quotations and third-party translations were not changed for this draft. Source attribution alone does not confirm redistribution rights; content-rights declarations still require the owner’s review.
- Metadata limits were checked against [Apple’s platform version reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) and [product page guidance](https://developer.apple.com/app-store/product-page/). The keyword field uses ASCII, so its byte and character counts are equal.
- Search metadata uses the subtitle for Quran, dua and prayer times, reserving keywords for specific features and routines: dhikr/tasbih counter, Qibla compass, widgets, offline reading, ruqyah, morning/evening adhkar and feeling-based readings. The anxiety term describes spiritual readings for that feeling, not a treatment claim. This is a relevance-based launch hypothesis, without measured keyword demand or ranking guarantees. [Apple’s search guidance](https://developer.apple.com/app-store/search/) recommends avoiding subtitle duplicates and measuring search impressions, conversion and downloads after release.

## Field counts
| Field | Count | Limit |
| --- | ---: | ---: |
| name | 6 | 30 |
| subtitle | 25 | 30 |
| promotionalText | 157 | 170 |
| keywords | 100 | 100 |
| description | 1679 | 4000 |
| reviewNotes | 3961 | 4000 |
