# Haneen 1.0 — App Store privacy submission

Reviewed 13 September 2026 against app code, `PrivacyPolicy.md`, the website source, and the signed 1.0 (1) archive. This is a proposed submission worksheet, not a record of answers already entered in App Store Connect. No account or backend settings were changed.

## Proposed answers

**Does this app collect data? Yes.** Account information and optional deletion feedback are retained off device. **Tracking: No** on the available evidence: neither Haneen nor its bundled privacy manifests declares advertising tracking. There is no advertising, attribution or cross-app tracking integration in the app code.

Apple distinguishes transmission from retention beyond servicing a request. Include applicable third-party collection, and determine linkage by the actual retained data and protections. Merely omitting an account-ID column does not establish anonymity; merely sending an authentication token does not establish retained linkage either. See [Apple’s App privacy details](https://developer.apple.com/app-store/app-privacy-details/).

| Data type | Proposed purpose | Linked to identity? | Evidence and qualification |
|---|---|---|---|
| Name | App Functionality | Yes | Google basic profile/provider account metadata. Apple requests full name, but this implementation does not separately send the returned name to Supabase. |
| Email Address | App Functionality | Yes | Email-link authentication and Apple/Google identity-token sign-in through Supabase. |
| User ID | App Functionality | Yes | Supabase and provider account identifiers. Google’s broader SDK manifest additionally declares Analytics; see the unresolved SDK section below. |
| Coarse Location | App Functionality | Yes, per Google’s SDK declaration | Google documents IP-derived general location for sign-in fraud prevention. This is separate from the nearby-search coordinates. |
| Precise Location | App Functionality | Not linked by Haneen’s request; provider retention/linkage needs confirmation | Nearby search sends full latitude/longitude to Overpass and an exact search region to Apple Maps. No Haneen account ID or auth token accompanies the Overpass request. Keep Precise Location in the proposed label pending confirmation; do not describe these requests as coarse or on-device-only. |
| Other User Content | App Functionality; Analytics if feedback informs feature planning | Verify retained linkage before choosing | Optional deletion reason/text is retained in Supabase. The stored row has no account identifier, but submission is authenticated and includes a timestamp. Check service logs/correlation before claiming “Not linked.” No evidence establishes retained linkage either. |

Do not claim an optional-feedback exemption here: the deletion form does not prominently show the account name alongside the submission. Free-form feedback is Other User Content; do not select every sensitive category a person could voluntarily type. Local reflections, feelings, goals, reading progress and dhikr completion are not uploaded by the shipping configuration.

## Google SDK discrepancy to resolve

The archive includes **GoogleSignIn-iOS 9.2.0**. Its actual `GoogleSignIn_GoogleSignIn.bundle/PrivacyInfo.xcprivacy` declares the following, all linked and all not used for tracking:

| SDK-declared data | SDK-declared purposes |
|---|---|
| Name, Email Address, Phone Number, Coarse Location | App Functionality |
| User ID, Other Data Types | App Functionality and Analytics |
| Device ID, Other Usage Data | Analytics |

This is broader than [Google’s published iOS disclosure guidance](https://developers.google.com/identity/sign-in/ios/app-privacy), which identifies a user identifier for OAuth grants and IP-derived general location for fraud prevention. Haneen invokes basic native sign-in, whose SDK defaults request email/profile. It does not request phone access, extra OIDC claims or configure App Check. No direct phone-number, advertising-ID or vendor-ID collection was found in the invoked app code. SDK token requests do send SDK version and execution-environment logging parameters.

Consequently, **do not assert that Haneen definitely collects phone numbers or device IDs solely from this SDK-wide manifest, and do not silently ignore the manifest either**. Preserve it unchanged. Compare the aggregate archive privacy report with version-specific Google guidance before finalizing the additional categories/purposes. Backend uses cannot be proven from client source alone. The table above is a verified baseline with explicit unresolved items, not a complete final checkbox set while this discrepancy remains.

Evidence: `CompanionAccount.google()` in `Sakina/Account/CompanionAccount.swift`; Google SDK `GIDScopes.m`, `GIDSignInInternalOptions.m`, `GIDSignIn.m`, `GIDSignInPreferences.m`; version pinned in `Sakina.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Feature audit

| Feature | Actual shipping behavior and source |
|---|---|
| Supabase sign-in | Email and verification code, or provider ID/access tokens, go to Supabase Authentication. Provider passwords are not handled by Haneen. Account/session data is retained for authentication. `Sakina/Account/CompanionAccount.swift`. |
| Delete account | Authenticated Edge Function deletes the Supabase account; an Apple-linked account supplies a fresh Apple authorization code for verification/revocation. Local notes/bookmarks remain. `supabase/functions/delete-account/handler.ts`, `index.ts`, `apple.ts`. |
| Optional feedback | A separate stored row contains random ID, creation time, allowed reason and up to 1,000 characters of text. No user-ID column, no automatic expiry. Function source contains no explicit feedback logging. `supabase/migrations/20260911181455_optional_account_exit_feedback.sql`. |
| Google Drive backup | **Disabled**: `HaneenGoogleBackupEnabled` is absent from archived Info.plist. Settings shows local storage, restore/sign-in are gated. Dormant implementation would upload saved situations and reflection text/timestamps to private `drive.appdata`; disconnect does not delete that file. Reassess before enabling. `Sakina/Account/GoogleBackupService.swift`, `Sakina/Views/SettingsView.swift`. |
| Nearby places | Apple `MKLocalSearch` and `https://overpass-api.de/api/interpreter` receive a search center/category. Overpass POST contains full coordinates and a Haneen user agent. The fallback array currently uses only its first endpoint. The actual Overpass operator’s retention policy remains unverified; the generic OSM foundation policy must not be assumed to cover it. `Sakina/Places/NearbyPlacesService.swift`. |
| Prayer/Qibla/widgets | Calculations, compass, saved prayer location and preferences are local; Apple geocoding may resolve place names. App Group widget snapshots contain calculated prayer times, city/time zone, local reading/progress information, not latitude/longitude. `Sakina/Prayer/PrayerTimesService.swift`, `Shared/SharedStore.swift`. |
| Audio and tafsir | EveryAyah receives the requested reciter/ayah URL; Quran.com’s native tafsir API receives edition and ayah. These services receive network information such as IP. Retained reading/listening logs and any additional label category are unverified. Streaming Qur’an audio is not collection of the user’s recorded voice. `Sakina/Audio/RecitationCache.swift`, `Sakina/Mushaf/TafsirService.swift`. |
| Analytics/crashes | No Haneen event analytics, third-party crash reporter, ads SDK, ATT request or APNs token registration found. This does not establish absence of Google/provider-side logs or analytics. Apple’s own collection is distinct from data the developer collects through Apple services. |
| Notifications | Local permission and scheduled `UNCalendarNotificationTrigger` reminders; no server push token. `Sakina/App/CompanionReminders.swift`. |
| Scholar content | **Disabled**: app constructs `ScholarContentStore(client: nil, cache: ... nil)`, and archived scholar Supabase configuration is blank. No scholar-content fetch or previously cached profile load. `Sakina/App/SakinaApp.swift`. |

## Policy and URL corrections before submission

1. Replace the absolute “does not include ... analytics” claim in `PrivacyPolicy.md` with a precise statement about Haneen’s own integrations; explain authentication-service processing without claiming unverified SDK behavior.
2. Remove current-release instructions for connecting/disconnecting Google Drive and references to configured scholar content. Both features are disabled in this archive.
3. Name the exact nearby-search transmission as **precise coordinates**, identify the actual Overpass service, and obtain its applicable privacy/retention information. Do not invent an operator policy URL.
4. Explain the native Quran.com tafsir request as well as EveryAyah audio; current text mainly describes external source links. Confirm provider logging before finalizing any additional retained usage/search data answers.
5. Change the deletion form’s “sent ... without your account identifier” to **“stored without your account identifier.”** Explain authenticated deletion separately. Verify feedback/log retention, and state the actual retention rule; the table currently has no expiry job. Do not promise a deletion period that is not implemented.
6. Reconcile app and website policy text. `scholar-dashboard/public/privacy.html` contains duplicate location sections, advertises the disabled backup, and differs from `AppStore/PrivacyPolicy.md`. Its Sydney-hosting claim needs dashboard confirmation; code alone does not verify project region.
7. Publish the corrected text at the configured [public privacy-policy URL](https://isharaf6.github.io/Sakina/privacy.html), then verify it loads without authentication from the submitted URL. This audit read the local website source; live reachability was not verified. Existing provider links are [Supabase](https://supabase.com/privacy), [Apple](https://www.apple.com/legal/privacy/) and [Google](https://policies.google.com/privacy). Contact remains `islamsharaf2005@gmail.com`. A separate Privacy Choices URL is optional, not currently supplied.

After resolving provider-specific uncertainty, reconcile the App Store answers with the aggregate archive report and Haneen’s own manifest. Do not patch third-party manifests to make the report smaller.
