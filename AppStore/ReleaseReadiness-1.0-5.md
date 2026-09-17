# Haneen 1.0 (5) — release readiness draft

Prepared 17 September 2026. **Not ready to submit on documentation alone.** This is the next-build plan and checklist, not evidence of a signed archive, deployment, physical-device test, store save or submission. Earlier build 1–4 records remain historical.

Coordinator update: the sync migration was deployed and rollback-isolated RLS checks passed, as reported by the release coordinator on 17 September. This is backend access-control evidence; client sync, physical-device flows, the final archive and reviewer access still need their separate checks.

## Material change

Haneen now requires Apple, Google or email sign-in for an account-backed personal library. The intended sync scope is saved ayat (including notes, favourites and highlights), categories/feeling mappings, saved du’a and moment identifiers, reflections, and Qur’an/du’a/collection reading positions. Goals, practice completion, dhikr counters, settings and saved prayer location remain local. After a library is prepared, cached sessions allow offline reading and changes retry when connected.

The first upgrade asks whether to import the old local library into the chosen account or use the cloud library. Cloud-only must preserve the unclaimed old backup locally. Sign-out must isolate cached account data; it must not show one person's library to the next account. Confirmed deletion must cascade the cloud row and clear the active account cache and its imported legacy backup. An offline second device is not remotely wiped; its cache can remain until it reconnects or its local data is removed. Per-item deletion must remove content from the current server document after sync, while pending deletion metadata stays local until acknowledged.

Sync uses HTTPS and Supabase storage protections with per-user RLS. It is not end-to-end encrypted. Synced religious reading choices/reflections may reveal sensitive personal information. The in-app English/Arabic policy, Markdown policy and local public HTML source now explain this.

## Ranked remaining release gates

| Priority | Requirement | Concrete release evidence still needed |
|---|---|---|
| Critical | Apple 2.1, functional account-backed app | Release-build registration/sign-in/sign-out/deletion, two-device restore, offline edit/retry, conflicting edits, cross-account isolation, and explicit old-library import choice all pass. Backend schema deployment, RLS isolation and deletion cascade must be verified against production. Code and this draft are not proof. |
| Critical | Apple 2.1, reviewer access | Set sign-in required in App Review Information and provide a usable, repeatable review account/authentication method. Check it independently. Do not fabricate credentials, leave an expired one-time link, or claim guest access remains. |
| High | Apple 5.1.1(i)–(ii), accurate policy and disclosure | Publish the revised privacy/support pages and reload them. Publish the 13-category worksheet in `AppPrivacySubmission.md`, including linked Sensitive Info and Product Interaction, both for App Functionality. New manifest entries do not publish the store labels. **Console/public deployment pending.** |
| High | Apple 5.1.1(v), mandatory account justification | Real library restore and sync are significant account features, but requiring login for bundled reading/prayer still needs Apple's assessment. Describe the working feature honestly and demonstrate it. Adding backup is not automatic compliance or guaranteed approval; be prepared to restore guest access if Apple requires it. |
| High | Existing Apple 2.1 information request | Supply the specifically requested physical-device recording, or obtain an explicit waiver from Apple. **Recording remains pending.** No simulator substitution or claim that a new build cancels the request. |
| High | Apple 2.3.1, consistent listing/review information | Use build-5 description and notes, verify the selected binary, update “sign-in required”, and replace old guest/local-only notes in both Review Information and the reply. Keep unresolved placeholders out of any final submission. |
| High | Apple 5.2, content rights | Retain the existing content-rights review and owner permission evidence. The owner declined sending provider questions; none were sent. This account change does not settle outstanding provider-scope questions. |

## Concrete final checks

- Test fresh Apple, Google and email accounts, returning sign-in, cached-session relaunch offline, cancellation, failed/expired email codes and a lost connection. No successful physical check is asserted here.
- On two devices using the same controlled account, save an ayah/note, category, du’a, moment and reflection, and change each reading position; verify restore. Test removal and conflicting changes without resurrecting deleted content.
- On one device, sign out of account A and into B. A’s content must not appear in B or upload to B. Re-enter A and verify its library. Repeat with an old unclaimed pre-sync library and both import choices.
- Delete only a disposable test account; verify the authenticated user and cloud row disappear and this device’s account data clears. Reconnection from the second device must not recreate the deleted account/library. Keep credentials, codes and personal content out of recordings and logs.
- Inspect Settings → Your space → Sources & privacy → Privacy/support and back navigation. Repeat the account/library paths in Arabic and with large text. Hosted tests are useful but do not replace live device checks.
- Re-run required app, sync and deletion checks; archive the final source; confirm the exported build contains the updated manifest. Do not reuse a prior archive to claim these changes shipped.

## Review materials

`ReviewNotes-1.0-5.txt` is the replacement draft. `SubmissionMetadata.en-AU.json` and `Listing.en-AU.md` use the same customer-facing description. `PhysicalDeviceWalkthrough-2026-09-16.md` has been revised for the mandatory account flow. These files are local until separately saved/deployed.

Apple does not demand a recording from every app as a universal submission field. In this case, Apple's recorded 14 September request specifically asks for physical-device footage, and no waiver is documented in `ReviewStatus-2026-09-16.md`. That case-specific requirement remains open.

Official references: [App Review 2.1 and 5.1.1](https://developer.apple.com/app-store/review/guidelines/), [App privacy details](https://developer.apple.com/app-store/app-privacy-details/), [Offering account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/).


## Local copy validation

The metadata-audit.py script audited the explicit build-5 JSON fields: zero critical, one high finding. The high is the existing subscription/EULA heuristic matching “No ads, subscriptions or in-app purchases”; there is no subscription or paywall, so it is a false positive. Description: 2,037 characters; review notes: 3,781; keywords: 100. All field limits pass and JSON/listing/review drafts match. Swift parsing, plist validation and whitespace checks pass. No additional app build or runtime test was run by the documentation task.

## Validation completed in this implementation

- 166 simulator tests passed, 0 failed, 0 skipped on 17 September 2026. This includes account isolation, persisted offline changes/relaunch, concurrent edits, remote deletion, malformed documents, storage-write failures, account deletion cleanup, authentication, app-share payloads and Sources/Privacy navigation.
- Result bundle: `test_sim_2026-09-17T05-38-54-911Z_pid80252_c256df9b.xcresult` in the local XcodeBuildMCP workspace.
- Supabase library migration is deployed. `supabase/tests/account_library_isolation.sql` passed against that backend in a rolled-back subtransaction, covering own-account operations, stale revisions, cross-account reads/writes and identity assertions, anonymous access, invalid payloads, and deletion cascade. No synthetic users or documents were retained.
- Live simulator: Sources & privacy stays open from Your space; the signed-out gate exposes Apple, Google and email with privacy/sources links and no guest entry; dark widget preview has an intact transparent silhouette. Existing automated coverage also checks widget alpha borders and localized sharing metadata.
- These checks do not claim a real two-iPhone authenticated sync walkthrough, an App Store upload, an updated App Store privacy declaration, or review submission. Those remain separate release gates above.
