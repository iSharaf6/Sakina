# Haneen release check — updated 13 September 2026

> Status update, 16 September: the owner submitted version 1.0 (1). Apple returned a Guideline 2.1 information request. See `ReviewStatus-2026-09-16.md` for the current state; the submission status below is historical.

## Current submission status — 13 September

- App Store Connect record created: Haneen, app ID `6811555262`, bundle `com.islamsharaf.sakina`, version 1.0, English (Australia).
- Owner approved all six marketing screenshots with the countdown cat tucked into the widget corner. All six are uploaded in their approved order; persistence was verified after reloading App Store Connect.
- Promotional text, description, keywords, support URL, copyright and review notes are saved. Sign-in is marked optional.
- The shared countdown layout was rebuilt and checked in English light/dark and Arabic dark; the screenshot uses a fresh native capture.
- Fresh version 1.0 (1) archived, exported and uploaded successfully on 13 September at 23:31 Sydney time. Apple finished processing it; build 1 was selected and saved on version 1.0. It has not been submitted for review. The app is not released. Earlier archive/export results below are historical.
- Review contact information, subtitle, Reference category and calculated age rating are saved. The app is free (Australia base price A$0.00), public, and set for availability in 175 regions after release. Mac and Vision Pro distribution are disabled for this iPhone release.
- The privacy policy URL and all 11 documented privacy categories are published. See `AppPrivacySubmission.md` for the exact purposes, linkage, supplier evidence and limitations.
- The exact IndoPak author-issued charitable distribution notice was found, retained in the app, and credited in English/Arabic. The font is unchanged. About/FAQ copy now matches local-only storage; share/review links use the assigned App Store ID.
- Remaining account/submission decisions: owner EU trader-status answer and content-storage/audio permission evidence. Two unsent requests are prepared in `PermissionsRequests.md`. See `ContentRights.md`; the earlier unsupported assumption that the IndoPak font necessarily must be removed has been resolved by better primary evidence.
- Automatic release after Apple review approval is selected. No review submission or public release has occurred.
- Final Apple version validation lists one remaining requirement: Content Rights Information. The current owner/provider permission questions are described above; EU trader status is a separate account availability requirement.

## Verified

- [x] 60 iOS tests passed, including all 604 mushaf pages, Arabic script coverage, reminders, widget models and Qibla geometry.
- [x] Eleven account-deletion security and optional-feedback tests passed; the Edge Function type-check passed.
- [x] Simulator checks: light/dark appearance, transparent artwork, Settings tap target, temporary ayah hint, ayah actions, and du’a display toggles with bilingual rewards.
- [x] New cat-and-Qur’an app icon packaged at all required sizes; opaque 1024-pixel App Store icon. Kaaba artwork transparency covered by the asset test.
- [x] Signed Release archive and App Store export succeeded. Artifact: `build/Haneen-AppStore/Haneen.ipa` (local, ignored by Git).
- [x] Signed Release installed and launched on the paired iPhone 15. This confirms installation and launch, not the device-only checks below.
- [x] Apple, Google and email providers enabled in production Supabase; guest access available from the welcome screen.
- [x] Apple account deletion requests fresh Apple authorization and revokes the grant before deleting the Supabase user. Production function v7 deployed. No private key or token is bundled in the app.
- [x] Google OAuth is in production; Haneen name, logo and public URLs saved. Google reports branding under review. Native Google sign-in now uses the iOS client and ID-token exchange; the iOS prompt was verified to show accounts.google.com rather than the Supabase domain.
- [x] In-app and public privacy text updated for authentication, location and nearby-place services.

## Before submission

- [ ] Complete Apple, Google and email sign-in with real test accounts on a physical device; test sign-out, relaunch, email confirmation and account deletion, including Apple's reauthorization/revocation flow. Provider configuration and automated tests do not replace these checks.
- [ ] Confirm real-device Qibla heading, location permission changes, prayer notifications across midnight/restart, and Home/Lock Screen widget updates. Simulator checks cannot verify a magnetometer or notification delivery while the device is locked.
- [ ] Check VoiceOver, largest text sizes, Reduce Motion, recitation on cellular, and installation on the oldest supported iOS version.
- [x] Create/confirm the App Store Connect record for `com.islamsharaf.sakina`.
- [x] Choose the final unique build number and upload the current signed build: 1.0 (1).
- [x] Upload the six owner-approved screenshots in their approved order.
- [x] Add age rating, category, free pricing/availability and documented privacy answers.
- [ ] Complete the content-rights declaration after resolving the remaining storage/audio permission questions.
- [x] Enter the public support URL and review notes from the listing.
- [x] Enter the privacy URL and review contact information.
- [x] Attach the processed build: version 1.0 (1).
- [ ] Finish required declarations, then submit for review.
- [ ] Monitor Google's external branding review; approval timing is controlled by Google.

The current build has been uploaded successfully. It has not been submitted for review or released.

## Account-deletion operations

Production secrets are stored in Supabase: `APPLE_SIGNIN_PRIVATE_KEY`, `APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_TEAM_ID`, `APPLE_SIGNIN_CLIENT_ID`. The Apple private-key backup is outside this repository in the owner's protected local configuration directory. Never commit or bundle it.

The Apple credential check returned `invalid_grant` for an intentionally invalid authorization code, rather than `invalid_client`. This supports correct client credentials; it is not an end-to-end user deletion test.

Tests: `deno test supabase/functions/delete-account/handler_test.ts`. The endpoint validates the bearer session, ignores caller-supplied deletion targets and preserves Apple-linked accounts when revocation fails.

## Latest polish check

Horizontal Mushaf paging uses a lazy scroll container rather than 604 TabView hosts. A memory-bounded cache retains the most recent 12 shaped page layouts for both reading directions. Simulator page navigation was checked in both directions; no device frame-rate percentage is claimed.

Nearby search publishes each source as it completes. Location acquisition times out after 12 seconds once permission is granted, Apple search cancels after 10 seconds, and OpenStreetMap uses a 12-second request timeout without serial retries. Unconfirmed halal results retain their evidence labels.

The account page uses compact cards and illustrated actions. Deletion feedback is optional, capped at 1,000 characters, stored without an account identifier, and does not gate deletion. The Kaaba illustration is removed from the compass dial. The installed icon has a sage background; in-app artwork remains transparent.


## Dedication and navigation release check

- No named editorial contributor, portrait, social link, or attributed review PDF ships in this release. Generic future editorial tooling remains disabled; the release store reads neither the network nor a previous build’s contributor cache.
- About contains an English/Arabic dedication for the creator’s late maternal and paternal grandparents, worded as an intention and du’a. The new transparent pencil illustration depicts the companion with four elder cats.
- Reproduced the All feelings → feeling bounce on the previous build. Converted every browse entry in Home, Explore and Du’as to the shared value-based route, so the browse page and mood share one navigation path.
- Checked Home → All feelings → Depressed, Explore → Start with a feeling → Lonely, and Du’as → All 33 → Sad/Hurt. Readers stay open; back returns to the list even after the recent-feelings section updates.
- These simulator navigation checks do not establish physical-device frame rates. The signed build was installed successfully on EZY. Remote launch was blocked because EZY was locked; the updated flow still needs an owner check on that phone.

Final validation for this change: 60 iOS tests passed; dashboard production build and lint passed; 103 guidance entries and backend security invariants passed. Signed Release archive and App Store IPA export succeeded. Arabic About reading direction and standard-size light/dark layouts were visually checked. No App Store upload or submission was performed.

## Arabic copy update

Arabic grammar and phrasing reviewed across the interface and authored explanations. Middle-dot UI separators replaced with Arabic/English commas. Account, onboarding, reminder settings and widgets now include Arabic copy. 61 iOS tests passed; details and scope are recorded in `Design/ContentReview/ArabicCopy-2026-09-12.md`.
