# Haneen release polish — 17 September 2026

Current preparation record for **Haneen 1.0 (3)**, now signed and archived with upload in progress. This supersedes the pending-email state in the historical [build-2 record](ReleasePreparation-2026-09-17.md). Build 2's archived test/upload evidence remains valid for that binary; it is not evidence for the new build.

**Verdict: not ready to resubmit yet.** Production email works, final automated tests passed, and the signed build-3 archive passed validation. Upload is in progress; processing/selection and Apple's specific physical-device recording request remain outstanding. No completed upload, App Review reply or resubmission is claimed here.

## Live email and contact changes

- `haneen.app.contact@gmail.com` is verified as the Haneen sender in Brevo and saved in Supabase custom SMTP. The owner does not have a custom domain.
- Confirm signup and Magic Link templates are saved with the new support link and intact Supabase confirmation-link/token placeholders.
- A fresh production email request returned **HTTP 200** and the message reached **INBOX**. Its actual From address was **Haneen <haneen.app.contact@12165955.brevosend.com>**, with **Reply-To: haneen.app.contact@gmail.com**. Brevo supplies that delivery domain; do not describe it as a Haneen-owned domain.
- The delivered HTML used the new support address and contained no old personal email address. A returning-user OTP verified with **HTTP 200**, created a session, and sign-out returned **HTTP 204**. No token, session secret or SMTP key is recorded in the repository.
- These are live backend/delivery results. They do not prove the latest iPhone build's magic-link callback, full new-user/returning-user UI lifecycle or account deletion.
- The earlier **SMTP 535** was resolved by correcting credentials. A subsequent **SMTP 525** was resolved by adding the observed source address **13.210.221.85** to Brevo's allowed IPs. The allowlist stays enabled. No official guarantee of a fixed Supabase Authentication egress IP was established; an infrastructure/address change could require a narrowly scoped allowlist update after checking provider logs.
- App Store Connect contact email and Notes were saved with the new contact address. The build-3 Notes prepared below are a local replacement draft until the coordinator separately saves them live.
- App support, in-app/public privacy source, email-template source and listing metadata use the new public contact. Developer-login credentials and historical evidence are not bulk-renamed. Current public-page deployment must be checked after these source changes are published.

Setup details and remaining tests: [AuthEmailSetup.md](AuthEmailSetup.md).

## Changes prepared for build 3

- **About Haneen:** English/Arabic creator credit for Islam Sharaf, supplied portrait, LinkedIn/contact links and a dedication to late grandparents on both parents' sides. The dedication expresses the hope of sadaqah jariyah rather than guaranteeing a religious outcome. The invitation covers ideas, support, collaboration and opportunities; it introduces no payment or donation flow.
- **Ratings:** the system StoreKit prompt is considered only after a visible reading completion, at least seven elapsed days, three distinct active days and five completed sessions. The same session is counted at most once per local day. Requests are limited to once per app version, at least 120 days apart, with five further sessions and at most three attempts in a rolling year. Leaving the completion screen cancels the delayed request. Timing stays on-device; there is no score filtering, sentiment screening, forced feedback or launch prompt.
- **Explicit feedback and sharing:** Settings/About provide persistent optional contact, App Store review and native share actions, with another share card at the Home footer. Sharing uses the actual App Store URL and Haneen artwork. The manual rating button opens the App Store review page; it does not rely on a system prompt that may choose not to display.
- **Audio:** morning/evening adhkar, Qur'an and situation playback share an in-app playback accessory and branded iOS Now Playing artwork. Audio continues after leaving its reader, with exclusive ownership between sources. Playback-error handling and visibility are part of the final verification below.
- **Qur'an typography:** ruqyah excerpt rendering is corrected without changing the underlying Qur'an text or removing its marks. Ruqyah 2:102 was visually checked with a uniform font and no placeholder glyphs.

Apple's [ratings design guidance](https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews) recommends engagement and natural stopping points, while [RequestReviewAction](https://developer.apple.com/documentation/storekit/requestreviewaction) leaves display to StoreKit and does not show in TestFlight. [Guidelines 5.6.1 and 5.6.3](https://developer.apple.com/app-store/review/guidelines/#developer-code-of-conduct) require the provided prompt API and prohibit review manipulation.

## Verification and build state

- The initial integrated change set passed 128 tests. After the playback-error fixes and final typography changes, the final run passed **130 tests, 0 failed, 0 skipped**, with **no build warnings**.
- Test evidence is retained under `/Users/IslamSharaf_1/Library/Developer/XcodeBuildMCP/workspaces/Sakina-main-2-3d8b1c5b1b6b`: log `test_sim_2026-09-16T16-11-14-501Z_pid80252_d600ac1a.log` and the paired xcresult with the same timestamp and suffix `29a9ad40`.
- Simulator screenshots were visually checked: ruqyah **2:102** has uniform Arabic typography without placeholder glyphs; the creator/About card and grandparents' dedication display correctly in Arabic right-to-left layout and dark appearance, without clipping.
- The signed Release archive completed at `build/Haneen-1.0-3.xcarchive`. App and widget both report **1.0 (3)**. Deep/strict code-signature verification passed; required-reason privacy declarations and background-audio configuration were verified.
- **Build-3 upload is running, not yet confirmed complete.** Processing, TestFlight availability and selected-review-build verification remain pending. Historical build **1.0 (2)** was processed and selected in App Store Connect. The new signed archive alone does not establish that build 3 is uploaded or selected.
- Branded Now Playing implementation and automated checks do not establish a visual pass on a physical Lock Screen. No physical Lock Screen appearance or completed physical account walkthrough is claimed.
- Build-3 review text is synchronized across `ReviewNotes-Draft-2026-09-16.txt`, `SubmissionMetadata.en-AU.json` and the response block in `ReviewResponse-2026-09-16.md`: **3,970 characters**, excluding the TXT's trailing newline. It remains below Apple's 4,000-character Notes limit and keeps `VIDEO EVIDENCE PENDING`.

## Apple's recording request remains active

The coordinator reopened the actual **14 September Guideline 2.1 — Information Needed — New App Submission** message in App Store Connect. It still explicitly requests a recording from a **physical device running the latest OS**, beginning at launch and showing normal use, registration/sign-in and account deletion, because this developer account has limited review history. No waiver or withdrawal was present.

This is an app-specific information request, not a claim that every App Store submission requires a recording. Simulator footage and marketing screenshots do not meet this particular request. The owner previously chose to record on the iPhone after the Mac recording attempts failed. No usable walkthrough has been received or attached. The [recording script](PhysicalDeviceWalkthrough-2026-09-16.md) remains a plan, not evidence of completed testing.

Do not remove the pending marker, send the prepared response, or claim the request is satisfied without the actual recording or an explicit change to Apple's requirement.

## Other release conditions

- The previously verified non-trader DSA declaration and Mainland China exclusion are preserved; see the historical build-2 record for their console evidence. No new regional setting change is claimed in this polish pass.
- The owner **declined** sending the prepared Quran Foundation and EveryAyah permission-scope questions. They remain unsent. Applicable public grants and existing evidence must be described accurately; silence is not additional permission or evidence of infringement. See [ContentRights.md](ContentRights.md).
- The developer reports Abu Islam's permission to include the recordings. Their source, hashes, durations and bounded excerpts remain documented in [AdhkarAudioProvenance.md](AdhkarAudioProvenance.md).
- Before resubmission: confirm upload/processing and select the exact new build, verify current published contact pages and live metadata, complete the physical account walkthrough, and attach the requested evidence. Only then replace the pending Notes paragraph and send/resubmit. Apple makes the approval decision.
