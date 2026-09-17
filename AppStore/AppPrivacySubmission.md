# Haneen 1.0 — App Store privacy submission

Updated 17 September 2026 for planned **Haneen 1.0 (5)** with mandatory accounts and account-library backup/sync. **The revised 13-category declaration is a local worksheet only: App Store Connect publication is PENDING.** The 11-category label previously published on 13 September described the earlier local-library build and is no longer sufficient for this release. Public policy deployment and client/device sync verification remain pending. The coordinator reports that the sync migration was deployed and rollback-isolated RLS checks passed; that does not publish store answers or certify the release binary. Do not pair this metadata with an earlier binary.

## Recommended submission answers

**Data collection: Yes. Tracking: No for every selected type.** No advertising, attribution or cross-app tracking integration was found. Google's exact bundled manifest also declares no tracking. Do not choose “Data Not Collected.”

Use the following supplier-inclusive set for this build. The Google rows follow the SDK author's version-specific declaration, not an assertion that Haneen's Swift code reads each field. The distinction and remaining service-side limits are explained below.

| App Store data type | Select these purposes | Linked to identity | Basis |
|---|---|---|---|
| Name | App Functionality | Yes | Google basic profile/account metadata and Google's manifest. Apple requests full name, but Haneen does not separately upload Apple's returned name. |
| Email Address | App Functionality | Yes | Supabase email/Apple/Google account authentication and support replies. |
| Phone Number | App Functionality | Yes | GoogleSignIn 9.2.0 supplier declaration. Haneen has no phone field or phone scope; see the supplier scope note below. |
| User ID | App Functionality, Analytics | Yes | Supabase/provider account identifiers; Analytics is Google's declared purpose, not a Haneen reading-events integration. |
| Device ID | Analytics | Yes | GoogleSignIn 9.2.0 supplier declaration; no Haneen IDFA/IDFV collection found. |
| Coarse Location | App Functionality | Yes | Google's manifest and its documented IP-derived general location for fraud prevention. |
| Precise Location | App Functionality | Yes — conservative classification | Nearby Overpass requests contain full coordinates and network identifiers without an anonymization stage. Haneen itself does not attach its account ID. Service retention and any narrower classification remain unverified. |
| Other Usage Data | Analytics | Yes | GoogleSignIn 9.2.0 supplier declaration. |
| Other Data Types | App Functionality, Analytics | Yes | GoogleSignIn 9.2.0 supplier declaration. |
| Other User Content | App Functionality, Analytics | Yes | **App Functionality:** synced notes, reflections, custom categories, highlights and saved-library content are stored under the account ID to restore the library. **Analytics:** existing deletion-feedback use to evaluate suggestions; this purpose does not imply analysis of private library content. Feedback is transmitted in an authenticated request before storage without account ID, with provider-log separation unverified. |
| Customer Support | App Functionality, Analytics | Yes | User-submitted support/problem/idea messages reach the support mailbox with the sender's email. The app appends the app and iOS versions. Generic device model and app language were removed from the support message on 17 September. Customer support is functional; suggestions used to plan improvements fall within Analytics. |
| Sensitive Info | App Functionality | Yes | **New for sync.** Saved Islamic readings, feeling mappings and reflections may reveal religious beliefs or other sensitive circumstances. Their transfer/storage is inherent in this personal religious library, even without a separate religion field. Used to back up/restore the library, not for marketing or behavioural profiling. |
| Product Interaction | App Functionality | Yes | **New for sync.** Qur’an/du’a/collection reading positions and saved-content selections are retained under the account ID so the reader can continue on another device. This is functional state, not an events-analytics stream. |

Do not select Third-Party Advertising, Developer Advertising/Marketing, Product Personalization or Other Purposes on current evidence. Account-library content and reading positions now leave the device and must be disclosed. Goals, practice completion, dhikr counters, app preferences and saved prayer location remain outside account sync; processing those only on-device does not add collection through the sync feature. Streaming Qur'an files is not collection of the user's recorded voice. The new Sensitive Info row is based on the religious library’s actual purpose and content, not hypothetical text in a generic support form.

The feedback/support purposes follow the current policy's stated use for support and improving Haneen. If the owner later uses those records for a different purpose, update the answers. No blanket optional-feedback exemption is being claimed: the deletion form does not prominently display the account name alongside its submission.

Apple's [App privacy details](https://developer.apple.com/app-store/app-privacy-details/) defines collection by retention beyond servicing the request, requires applicable partner collection, distinguishes local processing, and requires protections before collection for an unlinked classification. The conservative location/feedback rows avoid making an unverified “not linked” promise; they are not proof of actual provider log contents. Apple's [purpose definitions](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes) include feature planning under Analytics and support/security under App Functionality.

## GoogleSignIn 9.2.0: resolved submission basis, bounded certainty

`Package.resolved` pins **9.2.0**, revision `08d8dcecafb575f98879ffdbb8302c1b9ad65d19`. The local source and bundled manifest declare all eight Google rows above as linked and not tracking. Use [the manifest at that exact revision](https://github.com/google/GoogleSignIn-iOS/blob/08d8dcecafb575f98879ffdbb8302c1b9ad65d19/GoogleSignIn/Sources/Resources/PrivacyInfo.xcprivacy), rather than an unpinned main-branch file. The [9.2.0 release notes](https://github.com/google/GoogleSignIn-iOS/releases/tag/9.2.0) do not provide a feature-specific privacy exception.

[Google's current public iOS disclosure page](https://developers.google.com/identity/sign-in/ios/app-privacy) is **unversioned**, last updated 19 May 2025 when checked. It names the OAuth user identifier and IP-derived general location for fraud prevention. It does not explain or retract the broader manifest's Phone Number, Device ID, Other Usage Data, Other Data Types or Analytics declarations. It must not be described as a 9.2-specific exemption.

Haneen calls `GIDSignIn.sharedInstance.signIn(withPresenting:)`, then passes the returned ID/access tokens to Supabase. Default scopes are email/profile. No phone scope, extra claims, App Check configuration, or invoked phone/advertising-ID/vendor-ID collection was found. SDK token requests include SDK version and execution-environment parameters. Disabled Google Drive code does not justify adding Drive-content collection.

**Decision:** retain the SDK author's declared collection in the submission. Client-source inspection cannot establish every Google authentication-page or server-side use, so absence of a field in Haneen's callback is insufficient to override the supplier declaration. This is a defensible supplier-based disclosure of data that may be collected, not a measurement that all eight types are collected on every sign-in. A narrower label would require Google to identify which declarations do not apply to this exact default integration. Do not modify the signed SDK manifest to reduce the label. Apple describes using SDK manifests in [its privacy-manifest guidance](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests).

Evidence paths: `Sakina/Account/CompanionAccount.swift`; `build/DerivedData/SourcePackages/checkouts/GoogleSignIn-iOS/GoogleSignIn/Sources/{GIDScopes.m,GIDSignInInternalOptions.m,GIDSignIn.m,GIDSignInPreferences.m,Resources/PrivacyInfo.xcprivacy}`; `Sakina.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Feature audit

| Feature | Actual shipping behavior and source |
|---|---|
| Supabase sign-in | Email and verification code, or provider ID/access tokens, go to Supabase Authentication. Provider passwords are not handled by Haneen. Account/session data is retained for authentication. `Sakina/Account/CompanionAccount.swift`. |
| Account-library sync | Planned build-5 path: saved ayat (notes/favourites/highlights), categories/feeling mappings, saved du’a and moment IDs, reflections, and Qur’an/du’a/collection reading positions are stored in Supabase under the authenticated user. RLS limits account access; HTTPS/provider storage protections are not end-to-end encryption. The initial upgrade asks whether to import an existing local library. Cloud-only selection leaves an unclaimed backup local. Offline changes queue/retry; sign-out isolates each account’s cache. Deploy/test evidence remains a release gate. |
| Delete account | Authenticated Edge Function deletes the Supabase account; an Apple-linked account supplies a fresh Apple authorization code for verification/revocation. Cloud-library records are linked to the auth user with cascading deletion. Confirmed deletion clears this device’s account cache and associated imported legacy backup. Another offline device can retain its cache until it reconnects or its local data is removed; this is not a global remote wipe. `supabase/functions/delete-account/handler.ts`, `index.ts`, `apple.ts`; verify the new sync migration and service before upload. |
| Optional feedback | A separate stored row contains random ID, creation time, allowed reason and up to 1,000 characters of text. No user-ID column, no automatic expiry. Function source contains no explicit feedback logging. `supabase/migrations/20260911181455_optional_account_exit_feedback.sql`. |
| Google Drive backup | **Disabled**: `HaneenGoogleBackupEnabled` is absent from archived Info.plist. Settings shows local storage, restore/sign-in are gated. Dormant implementation would upload saved situations and reflection text/timestamps to private `drive.appdata`; disconnect does not delete that file. Reassess before enabling. `Sakina/Account/GoogleBackupService.swift`, `Sakina/Views/SettingsView.swift`. |
| Nearby places | Apple `MKLocalSearch` and `https://overpass-api.de/api/interpreter` receive a search center/category. Overpass POST contains full coordinates and a Haneen user agent. The fallback array currently uses only its first endpoint. The actual Overpass operator’s retention policy remains unverified; the generic OSM foundation policy must not be assumed to cover it. `Sakina/Places/NearbyPlacesService.swift`. |
| Prayer/Qibla/widgets | Calculations, compass, saved prayer location and preferences are local; Apple geocoding may resolve place names. App Group widget snapshots contain calculated prayer times, city/time zone, local reading/progress information, not latitude/longitude. `Sakina/Prayer/PrayerTimesService.swift`, `Shared/SharedStore.swift`. |
| Audio and tafsir | EveryAyah receives the requested reciter/ayah URL; Quran.com’s native tafsir API receives edition and ayah. These services receive network information such as IP. Retained reading/listening logs and any additional label category are unverified. Streaming Qur’an audio is not collection of the user’s recorded voice. `Sakina/Audio/RecitationCache.swift`, `Sakina/Mushaf/TafsirService.swift`. |
| Analytics/crashes | No Haneen event analytics, third-party crash reporter, ads SDK, ATT request or APNs token registration found. This does not establish absence of Google/provider-side logs or analytics. Apple’s own collection is distinct from data the developer collects through Apple services. |
| Notifications | Local permission and scheduled `UNCalendarNotificationTrigger` reminders; no server push token. `Sakina/App/CompanionReminders.swift`. |
| Scholar content | **Disabled**: app constructs `ScholarContentStore(client: nil, cache: ... nil)`, and archived scholar Supabase configuration is blank. No scholar-content fetch or previously cached profile load. `Sakina/App/SakinaApp.swift`. |

## Historical policy and URL corrections — earlier local-library release

The following records the earlier release work; the build-5 pages have since changed locally and need fresh deployment verification:

- Canonical Markdown, public HTML and in-app English/Arabic policy distinguish Haneen's lack of advertising/behavioural-event integration from provider account, security and technical processing.
- Disabled Google Drive/scholarly features, duplicate Location sections and unverified Sydney hosting claim are removed from current-release policy copy.
- Precise Overpass coordinates, native Quran.com tafsir requests and EveryAyah audio requests are described.
- Deletion copy now distinguishes authenticated transmission from storage without account ID. Feedback retention is “as needed to evaluate feedback and improve the app”; there is no invented automatic expiry.
- About and support FAQ now describe the local-only release. Support/share/review links use the App Store Connect ID verified by the release coordinator, `6811555262`.

Public GET verification on 13 September 2026, without authentication:

| Submitted page | Result |
|---|---|
| [Privacy policy](https://isharaf6.github.io/Sakina/privacy.html) | HTTP 200, title “Haneen Privacy Policy”, effective 13 September 2026. 7,311 bytes; byte-for-byte equal to `scholar-dashboard/public/privacy.html`. |
| [Support / app website](https://isharaf6.github.io/Sakina/app.html) | HTTP 200, title “Haneen — Your daily companion”. 2,597 bytes; byte-for-byte equal to `scholar-dashboard/public/app.html`. Contact address present. |

Privacy SHA-256: `50cbeb5eb2d4f3c8c28975975b18453be1af9109da06dbacad8f19dceaae7000`.
Support SHA-256: `c0570b2a7a2a9d513c89b4f0f88a99879f21847e615a3fe6141fcdbb5a0f78cc`.
The separate Privacy Choices URL is optional and is not supplied. Contact: `haneen.app.contact@gmail.com`.

## Facts that public/client evidence cannot certify

These are specific limits, not new copy tasks or proof of a policy violation:

1. **Overpass production logs:** whether `overpass-api.de` retains complete query bodies/coordinates, IP or a reversible client token after a request; for how long; for which uses; and whether records are linked. Upstream [dispatcher source](https://github.com/drolbr/Overpass-API/blob/master/src/overpass_api/dispatch/dispatcher_stub.cc) logs raw query text, but this does not prove the deployed operator's version/configuration or retention. Do not claim transient/anonymous processing or cite the generic OSM Foundation policy as this operator's policy. If complete searches are retained, **Search History** may also need declaration; only the operator/deployed configuration can settle that.
2. **Content API logs:** whether native Quran.com tafsir requests and EveryAyah reciter/ayah requests are retained and used as a reading/listening history. [Quran.com's policy](https://quran.com/privacy) discusses website log data, but does not specifically settle native API retention. It is not evidence that Haneen sends Quran.com account email or runs the website's analytics JavaScript. Confirm the API/CDN practices before asserting no retained Product Interaction or additional diagnostic data. EveryAyah's public index did not expose applicable retention information in this audit.
3. **Feedback linkage:** the database has no account-ID column and code does not explicitly log feedback. An authenticated request and timestamp remain; actual Supabase function/access-log settings were not read. A “not linked” answer requires verified handling before collection and no later linkage, not just a schema assertion. Current recommendation is linked, so no unsupported anonymity claim is necessary.

The recommended set resolves the Google supplier discrepancy and gives concrete current answers; it does not certify undisclosed production-provider behaviour. Location/content API retention is the unavoidable provider fact if the release owner needs an exhaustive guarantee about additional retained search/interaction categories. Do not present a missing public policy as evidence that no logs exist. Do not invent provider assurances or claim that the release was submitted merely because this worksheet is complete.

## Build 2 copy update — 17 September 2026

The public and Markdown policies now cover authentication-email processing: Brevo receives the recipient address, sign-in message and delivery/failure records through Supabase's custom SMTP integration. Custom SMTP was saved and rechecked in Supabase on 17 September; actual delivery remains unverified. Email Address / App Functionality / Linked remains applicable; review any actual provider tracking before retaining the No Tracking answers. The SMTP setup requires no marketing subscription. The in-app English/Arabic policy includes the same explanation.

Full morning and evening recordings and fifteen matched excerpts are bundled for offline playback. Playback makes no SoundCloud request; optional source links open externally. No new collection category is inferred from local playback itself.

The earlier public-page byte counts/hashes describe the 13 September publication only and must not be used to certify the updated pages. Verify deployed pages after publication. This document does not claim that revised console declarations have been saved.

The app-owned privacy manifest was also aligned on 17 September with the conservative current label choices for precise location, optional feedback and customer support. These entries describe Haneen's own data flows; the Google SDK's manifest remains separate. The support composer includes app/iOS versions only. These code changes do not by themselves publish revised App Store Connect declarations.

The regional Apple age-range check processes its response only on the device, discards age/category values, and keeps only the completion state in process memory. Haneen does not upload or persist these values, so this implementation does not by itself add developer-collected age or date-of-birth data to the label. Apple's account/parental settings remain governed by Apple. Manual device/Sandbox verification remains separate.


## Build 5 declaration and release gates

The exact Apple labels are **User Content → Other User Content**, **Sensitive Info → Sensitive Info**, and **Usage Data → Product Interaction**. The cloud data is linked because it is stored under the authenticated account. The collection is ongoing app functionality, so an occasional-feedback disclosure exception does not apply. These classifications follow [Apple’s privacy data types and purposes](https://developer.apple.com/app-store/app-privacy-details/); the mapping from Haneen’s religious library to Sensitive Info is a conservative application of those definitions.

`Sakina/PrivacyInfo.xcprivacy` adds `NSPrivacyCollectedDataTypeSensitiveInfo` and `NSPrivacyCollectedDataTypeProductInteraction`, both linked, not tracking and used for App Functionality. The existing Other User Content row retains App Functionality plus Analytics because feedback still has that stated use. No Analytics use is added for the private synced library. [Apple’s manifest value reference](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype) supplies these identifiers. Do not alter Google’s signed manifest.

Before upload/submission:
- Verify the deployed per-user RLS rules, account-deletion cascade, cross-account cache separation, explicit old-library import choice and lossless sync/retry on the release binary.
- Verify the actual sync payload contains only the documented fields. Confirm per-item deleted content is removed from the current server document after sync; pending deletion metadata must remain local until acknowledged.
- Publish the revised 13-type privacy answers in App Store Connect and the matching privacy/support pages, then independently reload both. **Not done by this documentation task.**
- Keep provider log/retention limitations above; do not imply encrypted transport makes server-readable content uncollected or anonymous.
- Supply workable reviewer authentication. Guest access has been removed, so the prior “no credentials needed” instructions are obsolete. No demo account or repeatable reviewer authentication has been verified in this task.

Mandatory sign-in is still a review risk under [Apple 5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage): a genuine restore/sync feature must be significant enough to justify requiring an account for the app. Adding backup does not itself guarantee approval. Apple’s case-specific physical-device video request also remains open; see `ReleaseReadiness-1.0-5.md`.
