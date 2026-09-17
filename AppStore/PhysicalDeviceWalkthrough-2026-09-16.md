# Haneen physical-device walkthrough — planned 1.0 (5)

Updated 17 September 2026 for Apple's existing Guideline 2.1 information request. **This is a recording script, not a completed test or recording.** Use [ReleaseReadiness-1.0-5.md](ReleaseReadiness-1.0-5.md) for current gates. Mandatory sign-in and account-library sync supersede the earlier guest/local-only script.

Apple specifically requested a physical device running the latest released OS. Marketing screenshots and simulator video do not satisfy that request; no waiver has been received. The previously connected iPhone 15 reported iOS 27.0 (24A437) on 16 September, which establishes only the earlier device state. Verify the exact OS and release build when recording.

## Preparation

- Install the final candidate build and verify its displayed version. Use disposable, developer-controlled accounts A and B and a second signed-in test device for sync checks. Never delete the owner's personal account.
- Preserve existing personal data. Do not uninstall an old local-only installation to obtain a clean onboarding recording: first verify the offered migration choices and retain its unclaimed backup. A separate clean test device is preferable.
- Keep passwords, recovery codes, one-time codes, tokens, mailbox contents and unrelated personal information out of the video. Show the successful before/after result without exposing the credential.
- Start with a real Home Screen launch. Record actual actions and loading/results; do not disguise a failure or substitute a mock-up. Optional narration can explain a brief pause for authentication.

## Recording sequence

| Step | Action | Evidence to show |
|---|---|---|
| Launch and legal access | Launch Haneen from the Home Screen. Show Apple, Google and email choices and open Sources/privacy before authentication. Return to sign-in. | A working launch and accessible legal information, without a nested-stack pop or inaccessible gate. |
| New account | Create disposable account A using an offered method. Email uses the same one-time link/code flow for new and returning users. | Authentication completes and the personal library becomes usable. Do not stop at showing a form or successful mail send. |
| Existing-library choice, if present | On a test upgrade, inspect the old-library import choice. Choose to import into A only if the test data belongs to A. Separately test the cloud-only choice without destroying its retained old backup. | No automatic upload to whichever account happens to sign in first. Record this only when it actually appears; do not describe a replay as a fresh upgrade. |
| Regional system prompt | If Apple requires an age-range check, complete the actual system flow. | Setup completes without saving/uploading the age response. Do not simulate a region or claim untested child/parent Sandbox coverage. |
| Qur'an and saving | Open a surah, tap an ayah, briefly listen/pause, save it, add a harmless note such as “Review demonstration”, and open tafsir. | Real Arabic text, source-labelled meaning, audio, a saved note and loaded online tafsir. |
| Library and restoration | In Your space, show the saved ayah/note, a category, saved du’a, moment and reflection. Sign in as A on the second device and show restoration and reading position. | Real account-backed data rather than only a local count. Do not claim success before sync finishes. |
| Offline use | With A already signed in and its library prepared, disconnect, edit a harmless note and read bundled content. Reconnect and show that change on the other device. | Cached-session offline use and successful queued-change retry. First-time sign-in/cloud restore are not claimed to work offline. |
| Du'a and audio | Open Morning and Evening adhkar. Play/pause a full Abu Islam recording and one matched excerpt, such as an-Nas. Leave the reader and show in-app and iOS media controls. | Credits, real playback, persistent controls and no automatic repetition-count increase. Offline playback is bundled, not a SoundCloud download at runtime. |
| Guidance and navigation | Home → All feelings → a feeling; Explore → a life group → a topic; Your space → Sources & privacy → Privacy, then back. | Each screen remains open and Back returns to the correct parent. |
| Prayer and permissions | Show prayer times and Qibla on the physical device. Optionally show nearby search and a widget. | No claim that a simulator verifies a magnetometer. Denying location must not block reading or the account library. Notifications remain optional. |
| Returning sign-in and isolation | Sign out of A, show the sign-in gate, sign into B and confirm A’s library is absent. Sign back into A and show restoration. | A working returning flow and separation between accounts; no misleading blank “success” state. |
| Delete the test account | In A, Settings → Your space → Account → Delete account. Leave feedback blank/Prefer not to say; confirm. If Apple-linked, complete fresh authorisation for the same Apple account. | Feedback is optional, deletion completes and returns to sign-in. Independently verify the cloud record and active-device account cache are removed. An offline second device is not claimed to be instantly wiped. |

The owner may keep a concise recording of the core requested sequence and separate clear evidence for the longer two-device/migration checks. Do not claim any unrecorded or unverified check passed.

## Reviewer authentication

Guest access has been removed. Mark sign-in required in App Review Information and provide a tested, repeatable way for Apple to access the account-based features, using a controlled review account or another arrangement Apple explicitly accepts. A one-time code that expires, the owner's personal credentials, or instructions merely assuming the reviewer will supply their own email are not a verified demo-access plan. **Reviewer access remains pending.**

## Evidence to complete after the actual recording

| Item | Current status |
|---|---|
| Recorded device and OS | Pending fresh verification |
| Installed version/build | Target 1.0 (5); pending |
| Registration/returning sign-in | Pending physical verification |
| Two-device restore/offline retry/isolation | Pending |
| Confirmed cloud/current-device deletion | Pending |
| Exported video path and reviewed contents | Pending |
| Attachment or stable review-accessible URL | Pending |
| App Review notes and response saved with evidence | Pending |

Watch the exported footage before submitting. Replace the evidence placeholders in `ReviewNotes-1.0-5.txt` and the response draft only with inspected, accessible evidence. A new build alone does not cancel Apple's case-specific recording request.
