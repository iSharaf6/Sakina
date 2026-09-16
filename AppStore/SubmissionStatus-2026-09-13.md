# Haneen submission status — 13 September 2026

> Superseded status: the owner submitted on 14 September, and Apple requested additional review information. See `ReviewStatus-2026-09-16.md`. The preparation and validation results below describe 13 September.

App Store Connect app `6811555262`, bundle `com.islamsharaf.sakina`, version **1.0 (1)**.

## Build

- Fresh Release archive: `/tmp/Haneen-release-final.xcarchive`.
- Local export: `build/Haneen-AppStore-final/Haneen.ipa`, 67,726,405 bytes.
- IPA SHA-256: `65754e32cd7550e2a2798334456e0b3beb62304e1f09ed9702871892f7fa15cf`.
- App and widget distribution signatures verified, both build 1, `get-task-allow=false`, correct App Group. Approved icon and original font notices included. Scholar and Drive backup features remain disabled.
- Xcode upload completed successfully at 23:31:08 Australia/Sydney. Apple reported “Uploaded package is processing”, then “Upload succeeded”; xcodebuild exited 0. Local logs and JSON verification are under `build/haneen-release-final-*`.
- Apple completed processing. Build 1 (internal ID `772c95f2-7918-4d40-98ab-200ac44db9c2`) was selected and saved on version 1.0. No review submission or release has occurred.
- Final “Add for Review” validation returned **Unable to Add for Review** with one listed missing item: **Content Rights Information** in App Information. No other version-form validation error was shown. The separate account EU trader-status declaration remains unset for EU availability.

## Saved App Store settings

- Owner-approved six English (Australia) screenshots, verified in order after reload.
- Listing and review notes from `SubmissionMetadata.en-AU.json`, subtitle “Quran, Dua & Prayer Times”, support URL, copyright and review contact saved. Sign-in is optional.
- Search metadata updated at the owner's request: 25-character subtitle and 100-byte keyword set from the matching JSON and listing files. Both fields saved in App Store Connect and verified after reopening. Keywords cover specific features and routines without repeating subtitle terms; effectiveness must be measured after release.
- Reference category, free pricing in every region, Australia as base. Public distribution, 175 regions available on release, including future regions. Mac and Vision Pro availability disabled for this iPhone release.
- Automatic release after App Review approval selected.
- Privacy policy URL verified publicly and entered. The 11-category supplier-inclusive privacy label from `AppPrivacySubmission.md` is published; all selected types linked, none tracking.

## Age rating answers

Apple calculated 13+ globally on newer operating systems, 12+ on earlier versions, with regional differences. No manual age override or Kids category was selected.

- No parental controls, age assurance, unrestricted browser, public user-generated content, social media, messaging, advertising, gambling, contests or loot boxes.
- No profanity; infrequent fear themes and alcohol references account for occasional scripture/hadith passages. This does not describe the companion illustrations as horror.
- No medical/treatment information; health/wellness topics present through self-care and spiritual support.
- Infrequent mature life themes; no sexual/nudity depictions or graphic sexual content.
- No cartoon violence or prolonged graphic violence. Infrequent realistic conflict and weapons references account for textual historical/scriptural passages.

Answers follow the descriptions displayed in Apple's questionnaire and its [age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions). A textual reference is distinct from a visual depiction; the record preserves this rationale for review.

## Remaining owner/provider items

1. Apple EU trader-status self-assessment: owner question sent, answer pending. The Free Apps Agreement is active; no Paid Apps Agreement is needed for this free release.
2. Offline storage of the Quran.com legacy API snapshots and EveryAyah streaming/cache permission: see `ContentRights.md` and the two prepared, unsent requests in `PermissionsRequests.md`. Owner asked whether relevant permission already exists or the requests may be sent. Sending a request alone does not grant permission.

These statuses must not be described as a submitted or released app. The physical-device checks listed in `ReleaseChecklist.md` remain unverified unless separately recorded.
