# Account and Explore follow-up — build 4

The owner reported that the signed-in Account screen offered no useful actions and that many Explore life-topic links failed on their iPhone. Build 3 is already installed on EZY and remains the selected App Store Connect build; these changes require a new build.

## Scope

- Replace the sparse account screen with **Your space**, a local personal hub for continuing Qur'an reading, opening saved content/reflections and choosing daily goals. Keep those tools available without authentication. Only display a provider-supplied name; do not infer a name from an email address.
- Keep sign-in, sign-out and account deletion accessible. The email shown for a signed-in reader is their identity, not Haneen's public contact address.
- Centralize Explore's life-topic destinations at the navigation-stack root and use stable catalog IDs for navigation. Preserve existing widget and debug deep links. The former child-level `Situation` registration conflicted with the parent's ownership of that route.
- Optional private cloud backup was proposed to the owner, but has not been selected or implemented in this build. Notes, bookmarks and personal reading activity remain on-device. Do not claim cross-device sync or an account-only benefit.

## Verification

- **137 tests passed, 0 failed, 0 skipped**, with no compiler warnings. The final run is `test_sim_2026-09-17T03-54-05-839Z_pid80252_96006e14.log` with result bundle `test_sim_2026-09-17T03-54-05-839Z_pid80252_91dfc65f.xcresult`, under the Haneen XcodeBuildMCP workspace in `~/Library/Developer/XcodeBuildMCP/workspaces/Sakina-main-2-3d8b1c5b1b6b/`.
- Tests cover every life-topic catalog route, a mounted SwiftUI stack through all five groups, updates to the Explore root, correct Back behavior, valid library counts, invalid saved references, goal/day rollover, provider-name clearing on sign-out, and a mounted account view responding to SwiftData changes, Arabic and sign-out. Auth uses isolated HTTP fixtures; this run does not claim a new live-provider/device sign-in check.
- Simulator taps checked two topics in each life group: Marriage (30 topics), Family (4), Faith (12), Worry (13), and Work (25). Every checked detail remained open after settling; Back restored its group and Explore's scroll position.
- The new hub initially exposed a second mixed-navigation issue opening practices from Daily Goals. Settings and the hub now share value routes. Live taps verified Your space → Daily goals → Morning adhkar and waking remembrance, plus Saved moments → Find a reading → Too much to carry. Those destinations now remain open.
- English light/dark and Arabic right-to-left signed-in/guest screenshots were visually reviewed. The hosted account test confirms sign-out removes identity while preserving local moments/reflections. Screenshot attachments use a synthetic test identity and are under `build/account-hub-verified/`.
- The signed Release archive succeeded at `build/Haneen-1.0-4.xcarchive`. App and widget both report **1.0 (4)**, with no compiler warnings. Deep/strict signature checks passed for the archive and device export. Device export succeeded at `build/Haneen-1.0-4-Device/Haneen.ipa`.
- **Build 4 installed successfully on EZY at 13:57 AEST on 17 September**, through the existing cable/device pairing. A device query confirmed **1.0 (4)** and the launch command succeeded at 13:58. This is a direct signed device installation, not a TestFlight download. App Store Connect still has build 3 selected; build 4 has not been uploaded or submitted in this pass.
- Local [build-4 review notes](ReviewNotes-1.0-4.txt) are **3,905 characters**, keep `VIDEO EVIDENCE PENDING` and describe the new account location. [Build-4 testing instructions](TestFlight-1.0-4.txt) are prepared locally.

The Mac exhausted free disk space while generating repeated test builds. Reproducible Haneen test-product packages and the superseded `build/ReleaseDerivedData` cache were removed. Source files, release archives, result bundles and logs were preserved.

## Review status

This follow-up does not satisfy or waive Apple's outstanding request for a physical-device walkthrough. Do not represent simulator checks as a completed physical-device account lifecycle or recording. See [ReleasePolish-2026-09-17.md](ReleasePolish-2026-09-17.md) for the verified build-3 upload and the original review conditions.
