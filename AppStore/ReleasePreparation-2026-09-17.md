# Haneen release preparation — 17 September 2026

This is the current preparation record for Haneen 1.0 (2). It supersedes older pending-state descriptions where explicitly stated below. It does not claim a submitted replacement build, a sent review reply, completed physical-device testing or App Store approval.

## Confirmed live configuration

- **Brevo custom SMTP:** enabled, saved and verified after reloading Supabase. The stored settings show the Brevo relay, port 587 and Haneen sender. The owner entered secret credentials directly; they are not in the repository.
- **Email templates:** Confirm signup and Magic Link are saved with branded bilingual copy and intact confirmation-link/token placeholders.
- **Email delivery is still blocked:** the actual delivery attempt returned **SMTP 535, authentication failed**. The owner is correcting the SMTP credentials. Saved configuration is not evidence of delivered email or a completed sign-in.
- **EU Digital Services Act declaration:** non-trader status is **Active**, verified in App Store Connect. The owner confirmed a personal, free app without business activity or monetisation. No statement about future changes to that status is inferred.
- **Availability:** Mainland China is **Not Available**; 174 regions remain selected. This records the verified App Store Connect setting, not legal certification for all selected countries.
- **Listing saved:** the updated English (Australia) description and 3,961-character review notes are saved in App Store Connect. The review reply remains an unsent draft; the physical-device video is still absent.
- **Screenshots saved:** all six corrected exports were uploaded, saved and checked in the console in this order: Daily companion (01), Widgets (06), Prayer times (05), Daily dhikr (04), Quran (02), Feelings (03).
- The last verified App Store Connect review state was the rejected build 1. No replacement-build selection, sent review response or resubmission is asserted here.
- **Build 1.0 (2) uploaded:** the final signed archive passed and Xcode reported `Upload succeeded` at 00:46 AEST on 17 September. Apple processing was pending at that point. The existing My Testers internal group contains the owner and distributes Xcode builds automatically.

## Prepared changes

- Auth copy matches the unified email flow: new and returning users follow the same one-time link/code process. Optional account deletion feedback remains optional.
- Full morning/evening Abu Islam recordings and fifteen matched excerpts are documented. In-app and public privacy copy describe offline playback and optional external source links.
- The review-notes TXT, response code block and saved metadata JSON contain identical replacement notes, **3,961 characters**, also saved live, including the regional Apple age-range check and Mainland China exclusion. The `VIDEO EVIDENCE PENDING` paragraph must be replaced with verified evidence before sending.
- Privacy copy in Markdown, public HTML and the English/Arabic in-app view describes Brevo email processing and on-device age-range checks. The age response is discarded; only check completion is retained in process memory. This is not a claim that Apple Sandbox/device scenarios have passed.
- The support page no longer says “In development” or implies an available cloud-backup feature. Signing in does not sync the local library.
- Home, Feelings and Prayer screenshot compositions show complete handset frames. Original captured interfaces, artwork, wording and colours are retained. The corrected six-image ZIP matches the exported PNGs.

## Verification completed for the copy/assets

- Review notes synchronized across TXT, JSON and response; field lengths within limits.
- Local website links resolve to existing files. Public support/privacy and Brevo's policy URLs returned HTTP 200, but this does not prove updated project copy has been deployed.
- Six marketing images are opaque RGB PNGs at 1242 × 2688. Renderer and review-gallery controls passed; the overview was visually inspected. ZIP CRC and exported-image contents match.
- `git diff --check` passed for these changes. The release coordinator reported 112 tests passing in the earlier full run, followed by 15 focused tests passing after the final eligibility-first change: 10 age-assurance and 5 tafsir-cache tests, with zero warnings in that focused run. These are automated checks, not physical account-flow or email-delivery evidence.
- A real simulator smoke check after the eligibility-first age-check fix reached Home without a blocking age prompt. Required-region child/parental account scenarios and physical-device checks remain unverified.
- Additional simulator checks: All feelings → Anxious stayed on its reading page; the enlarged Arabic long-dhikr view scrolled to its remaining text. These do not substitute for physical-device verification.
- Final archive verification: version 1.0, build 2, iPhoneOS 26.5 SDK; declared-age-range and Sign in with Apple entitlements are signed; FileTimestamp reason C617.1 and UserDefaults reasons are present; both full adhkar MP3s are bundled. Evidence is retained locally in `build/haneen-1.0-2-final-verification.json` and the archive/upload logs.
- Website `npm run lint` and `VITE_BASE_PATH=/Sakina/ npm run build` passed using installed dependencies. Built support/privacy/logo files match their public sources; the artifact uses the required base path, has no source maps or development-demo strings. Vite reports a non-blocking dashboard JavaScript chunk-size warning (531 kB); the standalone support/privacy HTML pages do not load that dashboard bundle.
- `PrivacyPolicyView.swift` copy is complete and frozen for the archive. Release signing/upload is tracked separately by the coordinator.

## Before resubmission

1. Correct the SMTP key/login as needed; send a real email to a consenting non-team test address, verify its unmodified link/code, and complete new-user/returning sign-in, sign-out and controlled test-account deletion on the physical iPhone.
2. Wait for Apple processing, select uploaded build 1.0 (2), and install that exact build for the physical-device walkthrough.
3. Publish the corrected website/privacy pages and verify the deployed content. The description, review notes and all six corrected screenshots are already saved in App Store Connect; the local gallery mirrors the verified uploaded order. Update the review notes again only when real video evidence can replace their pending paragraph.
4. Inspect and attach the actual physical-device walkthrough requested by Apple. Record the app build, device/iOS version and useful timestamps. Remove the pending marker only after that evidence is available.
5. Resolve the exact remaining content-source conditions using applicable public grants or existing permission evidence, and include the relevant documentation with the review response. Do not infer universal clearance or require bespoke contracts for every item without examining the source's public grant.
6. Send the final reply and resubmit only when the required evidence and functioning build are present. Apple's approval remains its decision.
