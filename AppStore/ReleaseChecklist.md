# Yaqeen 1.0 release checklist

## Completed in the repository

- [x] iPhone-only iOS 17+ app target and WidgetKit extension
- [x] Production AppIcon catalog including opaque 1024×1024 marketing icon
- [x] App and widget privacy manifests
- [x] App Group entitlement on both targets
- [x] Location usage description
- [x] No placeholder OAuth client or reversed URL scheme in the submitted configuration
- [x] Google UI safely hidden when production OAuth is absent
- [x] Qur’an content-integrity tests and Qibla geometry tests
- [x] Verified-scholar public profile and published-insight presentation, with an offline/unconfigured safe state
- [x] Invite-only scholar/admin dashboard and least-privilege Supabase schema, RLS, revision history, and publishing workflow
- [x] Deterministic guidance manifest and CI drift check
- [x] Schema and JWT-role pgTAP suites wired into CI, including public-read denial, revoked-role denial, admin-only publication, inactive-source denial, and stale-revision conflicts
- [x] Revision-safe draft/translation/review/submit RPCs and exact-origin CORS handling for the browser translation function
- [x] In-app bilingual privacy policy
- [x] Release device build and unsigned Archive verification

## Apple Developer and App Store Connect

- [ ] Confirm the App ID and widget App ID both have `group.com.islamsharaf.sakina`
- [ ] Create or refresh App Store distribution profiles for both targets
- [ ] Choose the final unique build number before upload
- [ ] Create the App Store Connect app record for bundle ID `com.islamsharaf.sakina`
- [ ] Host `PrivacyPolicy.md` on a public HTTPS URL and enter it in App Store Connect
- [ ] Provide a public Support URL and monitored support email
- [ ] Complete App Privacy answers against the exact uploaded binary and all third-party services
- [ ] Confirm permission to publish the supplied scholar portrait, name, links, and any subsequently submitted prose
- [ ] Complete age rating, category, pricing, availability, and content-rights questions
- [ ] Upload final device screenshots and optional App Preview
- [ ] Add review notes from `Listing.en-AU.md`

## Final physical-device QA

- [ ] Prayer times: precise/approximate location, denied access, time-zone changes, and calculation methods
- [ ] Qibla: true-north heading, calibration, magnetic interference/case, denied access, and disabled services
- [ ] Widgets: both Lock Screen halves plus Home Screen widget, including after Isha and after location refresh
- [ ] Arabic and English, right-to-left layout, Dynamic Type, VoiceOver, Reduce Motion, and dark appearance
- [ ] Notifications after a restart and across midnight
- [ ] Recitation playback on Wi-Fi and cellular data
- [ ] Cold-launch deep links and App Shortcuts
- [ ] Install/upgrade on the oldest supported iOS 17 device

## Scholar service activation

- [ ] Create the production Supabase project and apply every migration in order
- [ ] Configure only the project URL and publishable key in the public app/dashboard; keep secret/service-role keys in Supabase or encrypted CI secrets
- [ ] Invite the scholar and administrator through Supabase Auth; disable public user creation for this workflow
- [ ] Assign the `scholar` and `admin` roles with the protected administrator RPC
- [ ] Create the profile using only owner-confirmed facts, upload the supplied portrait to the scholar’s UUID folder, then explicitly mark the profile verified and public
- [ ] Deploy the manifest-sync and translation Edge Functions and set their server-side secrets, including the dashboard’s exact HTTPS origin in `SCHOLAR_DASHBOARD_ORIGINS`
- [ ] Run `supabase test db` from a clean local/staging stack and require both pgTAP suites to pass before production deployment
- [ ] Run the manifest sync, confirm the expected queue count, and review a draft/translation/submission/publication end to end
- [ ] Deploy the dashboard over HTTPS and verify an uninvited or role-less user is signed out
- [ ] Confirm only `published` content is readable with an unauthenticated publishable-key request
- [ ] Re-run App Privacy answers and physical-device QA against the exact production Supabase configuration

## Optional Google backup decision

For a local-only 1.0, leave OAuth credentials absent; the UI remains hidden. If Google backup is enabled before submission, add the production iOS OAuth client and reversed URL scheme, verify Drive API consent and data deletion, repeat privacy review, and retest account restoration and two-device conflict behavior.
