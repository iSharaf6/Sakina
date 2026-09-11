# Haneen release check — 12 September 2026

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
- [x] Sheikh Abdullah Abu Hattab receives a simple acknowledgment. The large review workbook is optional and not part of launch requirements; no endorsement is claimed.

## Before submission

- [ ] Complete Apple, Google and email sign-in with real test accounts on a physical device; test sign-out, relaunch, email confirmation and account deletion, including Apple's reauthorization/revocation flow. Provider configuration and automated tests do not replace these checks.
- [ ] Confirm real-device Qibla heading, location permission changes, prayer notifications across midnight/restart, and Home/Lock Screen widget updates. Simulator checks cannot verify a magnetometer or notification delivery while the device is locked.
- [ ] Check VoiceOver, largest text sizes, Reduce Motion, recitation on cellular, and installation on the oldest supported iOS version.
- [ ] Create/confirm the App Store Connect record for `com.islamsharaf.sakina`; choose the final unique build number and upload the signed build.
- [ ] Add screenshots, age rating, category, pricing/availability, content-rights declarations and privacy answers matching the shipped binary and services. Confirm consent for the Sheikh acknowledgment.
- [ ] Enter public support and privacy URLs from the listing, add review notes, then submit for review.
- [ ] Monitor Google's external branding review; approval timing is controlled by Google.

No build has been uploaded or submitted to App Store Connect during this release check.

## Account-deletion operations

Production secrets are stored in Supabase: `APPLE_SIGNIN_PRIVATE_KEY`, `APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_TEAM_ID`, `APPLE_SIGNIN_CLIENT_ID`. The Apple private-key backup is outside this repository in the owner's protected local configuration directory. Never commit or bundle it.

The Apple credential check returned `invalid_grant` for an intentionally invalid authorization code, rather than `invalid_client`. This supports correct client credentials; it is not an end-to-end user deletion test.

Tests: `deno test supabase/functions/delete-account/handler_test.ts`. The endpoint validates the bearer session, ignores caller-supplied deletion targets and preserves Apple-linked accounts when revocation fails.

## Latest polish check

Horizontal Mushaf paging uses a lazy scroll container rather than 604 TabView hosts. A memory-bounded cache retains the most recent 12 shaped page layouts for both reading directions. Simulator page navigation was checked in both directions; no device frame-rate percentage is claimed.

Nearby search publishes each source as it completes. Location acquisition times out after 12 seconds once permission is granted, Apple search cancels after 10 seconds, and OpenStreetMap uses a 12-second request timeout without serial retries. Unconfirmed halal results retain their evidence labels.

The account page uses compact cards and illustrated actions. Deletion feedback is optional, capped at 1,000 characters, stored without an account identifier, and does not gate deletion. The Kaaba illustration is removed from the compass dial. The installed icon has a sage background; in-app artwork remains transparent.
