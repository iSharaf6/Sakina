# Haneen Privacy Policy

Updated 17 September 2026

> Release copy for planned 1.0 (5), including account-library sync. Public deployment and revised App Store privacy answers are pending; this file does not certify either.

This policy covers Haneen 1.0, developed by Islam Sharaf.

## The short version

Haneen has no advertising or integration that tracks your reading, feelings or other activity for behavioural analytics. Haneen does not track you across apps or sell personal data. Sign-in and online services separately process the technical information described below.

## Data kept on this iPhone

Daily goals, practice completion, dhikr counters, app preferences and saved prayer location remain on this device and are not included in account sync. Your synced library also has a local copy for offline use. Widgets receive the local progress and prayer information needed for their display through Apple's App Group storage. Prayer information includes calculated times, a city-level label and time zone, without latitude or longitude. Device backups are governed by your Apple device settings.

Optional prayer and reflection reminders are scheduled on your device. You can turn them off in Haneen or iOS Settings.

## Accounts and sign-in

Apple, Google and email sign-in use Supabase Authentication. Supabase stores your account identifier, email address, display name when supplied, and the account/session information needed for sign-in. Apple and Google provider tokens are sent to Supabase to verify your sign-in. Apple and Google share account information according to the permissions you grant; Haneen does not receive your Apple or Google password. An account is required to use Haneen and keep a library that can be restored on another device. Apple, Google and email are available to new and returning users. After signing in and preparing your library, a cached session allows offline use; account verification and cloud sync need a connection.

Authentication requests include technical information such as IP addresses and SDK/platform details. Sign-in providers process security and diagnostic information to operate, protect and troubleshoot their services under their own terms. Google states that its sign-in SDK may use a user identifier to record consented access and an IP address to estimate general location for fraud prevention.

## Your account library

Haneen sends your saved ayat and their favourites, highlights and notes, custom categories and feeling mappings, saved du’a and life-moment identifiers, reflections, and Qur’an, du’a and collection reading positions to Supabase under your account identifier. Sync includes the record identifiers and update information needed to restore and reconcile your library. These choices and words may reveal religious beliefs or other personal information. They are used to save and restore your library, not for advertising or behavioural analytics. Your library is not public or shared with other users.

Changes made offline are kept on your device and retried when you reconnect. Signing out separates that account’s cached library from the next account; it does not delete the account’s cloud copy. Only the signed-in account can access its library through the app’s database access rules.

## Your existing library

When upgrading from a version that kept your library only on this iPhone, Haneen asks whether to add that library to your account or start with your account’s cloud library. It does not automatically attach the old library to whichever account signs in first. The old local backup remains until you choose to import it, after which it belongs to the selected account. Choosing the cloud library does not upload that unclaimed backup.

## Sign-in emails

Supabase sends Haneen's email sign-in messages through Brevo. The delivery provider processes your recipient email address, the sign-in message including its one-time link or code, and delivery or failure records needed to send and troubleshoot the message. These messages are for authentication, not a marketing subscription. Provider-held delivery and security records follow the provider's retention policies.

## Age-range checks

Where Apple requires an age-range check, Haneen asks for the range through Apple's system interface after setup. Haneen uses the response on your device and discards it without saving your age, date of birth or age category, or sending that information to Haneen's servers. Only the check's completion state stays in memory during the current app session. Apple manages the associated Apple Account and parental-consent settings under its own privacy terms.

## Location and nearby places

With your permission, prayer times and Qibla are calculated on your device. Compass readings are temporary, and Apple location services may resolve a place name. Nearby mosque or halal-place searches send precise latitude/longitude and the search category to Apple Maps and the Overpass service at overpass-api.de, which searches OpenStreetMap data. Opening directions sends the destination to the map service you choose. These online services receive ordinary connection information such as your IP address. You can deny or revoke location access in iOS Settings.

## Recitation, tafsir and references

Recitation requests go to EveryAyah and identify the requested reciter and ayah. Opening tafsir requests the selected ayah and tafsir edition from Quran.com's API. These services receive the request and ordinary connection information, including your IP address. Source links you open may take you to Quran.com, Sunnah.com or another cited website, whose privacy terms apply to your visit.

The full morning and evening adhkar recordings by Abu Islam are bundled with Haneen and play offline on your device. Playing them does not contact SoundCloud. An optional source link opens the original recording in SoundCloud or your browser only when you tap it; SoundCloud’s privacy and cookie policies apply to that visit. Haneen does not use a SoundCloud SDK, API or embedded player.

## Optional deletion feedback

If you choose to give a reason or written feedback, it is sent with your authenticated account-deletion request. After account deletion, the feedback is stored in Supabase without your account identifier, together with a random feedback identifier and submission time. It is retained as needed to evaluate feedback and improve the app. The deletion service still authenticates the request, and service logs may contain request/account information. Feedback is optional and never required for deletion; please leave out personal details.

## Your choices and retention

You can remove saved items inside Haneen; changes are synchronised when online. Account and cloud-library data are retained to provide the service until you remove the content or delete your account from Settings → Your space → Account → Delete account. Confirmed account deletion removes the account and its cloud-library records, and clears that account’s cached library on this device. For an Apple-linked account, deletion requests fresh Apple authorization so Haneen can revoke its access before deleting the Supabase account. Signing out alone does not delete your account or its cloud library. Deleting the app removes its local data, subject to device backups; it does not delete your cloud account. Copies on another offline device may remain there until it reconnects or its local data is removed. You can change location and notification permissions in iOS Settings. Provider security logs and other provider-held data follow the applicable service retention policies.

## Service providers and protections

Library transfers use encrypted HTTPS connections and Supabase stores the cloud copy with provider-managed storage protections. This is not end-to-end encryption: Haneen’s service operator and infrastructure providers can process the content to operate the service. Supabase's published data processing addendum limits processing of customer data to customer instructions and specified service purposes, and requires confidentiality and security measures. Apple's and Google's privacy policies describe their data protection, retention and privacy controls. Providers may process data in other countries under their applicable terms. The online policy below links to these documents.

## Contact

Haneen is developed by Islam Sharaf. Questions or deletion assistance: haneen.app.contact@gmail.com. If you contact support, we receive your email address, message and any details you include. Haneen's support form also includes the app and iOS versions. We retain correspondence as needed to respond and resolve the issue.

## Provider policies

- [Supabase data processing addendum](https://supabase.com/legal/customer-resources/data-processing-addendum)
- [Supabase privacy policy](https://supabase.com/privacy)
- [Brevo privacy policy](https://www.brevo.com/legal/privacypolicy/)
- [Apple privacy policy](https://www.apple.com/legal/privacy/)
- [Google privacy policy](https://policies.google.com/privacy)
- [Google iOS sign-in disclosure](https://developers.google.com/identity/sign-in/ios/app-privacy)
- [SoundCloud privacy policy](https://soundcloud.com/pages/privacy)

Public policy: https://isharaf6.github.io/Sakina/privacy.html
