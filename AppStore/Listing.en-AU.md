# Haneen — App Store listing

English (Australia) draft for the first release. The matching JSON file contains only copy-ready metadata fields. Publication and live App Store Connect settings are handled separately.

## Name
Haneen

## Subtitle
Qur’an, Du’a & Prayer

## Promotional text
Read Qur’an, find a du’a for the moment you’re in, and keep prayer times close with illustrated widgets. In Arabic and English, with no ads or subscriptions.

## Keywords
quran,dua,islam,muslim,dhikr,adhkar,qibla,prayer,adhan,mushaf,tasbih,mosque,hadith,arabic

## Description
Read Qur’an, keep up with prayer, and find words for what you’re feeling. Haneen brings your daily worship together in Arabic and English, with warm illustrations and room to make it your own.

Read the full Qur’an in a traditional mushaf or a flexible digital reader. Tap an ayah to listen, save it, add a note or explore its meaning. Choose the text size, translation and transliteration that suit you, and return to your reading place whenever you’re ready.

Begin with how you feel, or explore moments in life such as marriage, family, work and faith. Find related Qur’an passages, du’as and hadith references alongside morning and evening adhkar and everyday supplications. Reported virtues include their source and conditions, with explanations in Arabic and English.

Keep the essentials close:
• Prayer times with your preferred calculation settings
• A Qibla compass and nearby mosque search
• Ten illustrated widget designs, with Home Screen and Lock Screen options
• Morning and evening adhkar, a dhikr counter and optional reminders
• Du’a translation and transliteration controls
• Saved ayat, private notes and bookmarks
• Arabic and English layouts, with light, dark and system appearance

No ads, subscriptions or in-app purchases. You can use the core app without an account, or choose Apple, Google or email sign-in. Your notes and bookmarks stay on your device; signing in does not upload or sync them.

The Qur’an text is included in the app. An internet connection is needed for streamed recitation, online tafsir, nearby searches and sign-in.

## Review notes
1. No account or demo credentials are required for the core experience. On first launch, tap “Use Haneen without an account” below the Apple, Google and email options. The Home, Explore, Qur’an, Du’as and Saved tabs are available without signing in. There are no in-app purchases, subscriptions or paywalls.
2. To review reading, open Qur’an, select a surah, then tap an ayah for recitation, saving and other actions. Du’as contains morning/evening adhkar and other supplications. Explore contains readings grouped by feelings and life situations.
3. Optional sign-in is available at launch and in Settings → Account. Email uses a sign-in link. Signing in does not sync the local notes/bookmarks library.
4. A signed-in user can delete their account at Settings → Account → Delete account. The reason and written feedback are optional: leave “Prefer not to say” selected and the feedback empty, tap “Delete account”, then confirm. Apple sign-in may request fresh authorisation to revoke the Apple connection. Local notes and bookmarks are separate from the account and remain on the device after account deletion.
5. Location and notification permissions are optional. Prayer times can use a selected city; prayer/Qibla calculations run on the device. Nearby-place searches use Apple Maps and OpenStreetMap Overpass. The Qibla compass needs a physical iPhone with a magnetometer; it cannot show a real compass heading in Simulator.
6. Widgets are added through the iOS widget gallery under Haneen. Prayer widgets need prayer settings configured in the app first. Available sizes differ by widget; Lock Screen options include prayer times. Arabic/English widget copy follows the language chosen in Haneen.
7. Qur’an text is bundled. Recitation streaming, online tafsir, nearby searches and sign-in require internet access. Source links and the privacy policy are at Settings → Sources, privacy & credits. The app does not contain advertising or tracking.

## Public links and contact
- Support: https://isharaf6.github.io/Sakina/app.html
- Privacy policy: https://isharaf6.github.io/Sakina/privacy.html
- Support email: islamsharaf2005@gmail.com

## Submission fields still to complete
Confirm the App Store Connect app record, copyright declaration, content-rights declarations, age rating, availability, screenshots, review contact and final uploaded build. Set the download price to Free if that remains the release plan; price is an App Store Connect setting and cannot be verified from app code. Enter the public URLs above and verify they are live. Use the current release checklist for test status; this metadata draft does not assert that live sign-in, device tests or submission are complete.

## Draft accuracy notes
- Confirmed from the welcome flow and root navigation: core features are available as a guest. No purchase SDK flow or paywall is present; StoreKit is used for the system rating prompt.
- Optional Drive backup is gated by `HaneenGoogleBackupEnabled`, which is absent from the shipping configuration. Editorial content uses a disabled client. Neither feature is advertised in the customer description.
- Widget completion reflects recorded morning/evening adhkar activity, not an inferred streak. The listing does not promise every design in every widget size.
- Qur’an/du’a quotations and third-party translations were not changed for this draft. Source attribution alone does not confirm redistribution rights; content-rights declarations still require the owner’s review.
- Metadata limits were checked against [Apple’s platform version reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) and [product page guidance](https://developer.apple.com/app-store/product-page/). The keyword field uses ASCII, so its byte and character counts are equal.

## Field counts
| Field | Count | Limit |
| --- | ---: | ---: |
| name | 6 | 30 |
| subtitle | 21 | 30 |
| promotionalText | 157 | 170 |
| keywords | 89 | 100 |
| description | 1564 | 4000 |
| reviewNotes | 1953 | 4000 |
