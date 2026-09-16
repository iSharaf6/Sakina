# Haneen — physical-device App Review walkthrough

Prepared 16 September 2026 for Apple's Guideline 2.1 information request. This is the recording script, not a completed QA report. Apple requested a physical device running the latest released OS; simulator captures and marketing screenshots do not meet that request.

This script now targets planned **Haneen 1.0 (3)**. See [ReleasePolish-2026-09-17.md](ReleasePolish-2026-09-17.md) for current build, email and review status. Production email delivery and returning OTP/session/sign-out have passed at the backend. Build 3 has not yet been uploaded, and physical-device account verification and recording remain pending. The review response remains unsent.

## Recording setup

- On the physical iPhone, check **Settings → General → Software Update** and install the latest public iOS release offered for that device. Do not rely on the cached iOS version from an earlier development session. Install the exact Haneen build selected for review (for example through TestFlight). Record the actual model, iOS version, app version and build below; do not infer them from filenames.
- Use a fresh installation for onboarding only if local data can be discarded. Uninstalling deletes local notes and bookmarks. A separate test device is preferable to erasing personal app data.
- Use a disposable, developer-controlled test email/account for the account sequence. Delete that test account only. Do not delete the owner's normal account or record personal mailbox contents, passwords, recovery codes or one-time codes in legible form.
- Turn on screen recording before launching Haneen from the Home Screen. Enable microphone narration if convenient, increase media volume enough to hear the short recitation example, and use Focus mode to keep unrelated notifications out of the video.
- Demonstrate real interactions and results without disguising errors. If a required step fails, record the failure for diagnosis and fix it before claiming that sequence works. Do not substitute rendered mock-ups.
- Aim for a 3–5 minute essentials recording, allowing more time if authentication takes longer. Show launch/guest access, an ayah and save, a dua and feeling/situation, prayer/Qibla, then the test-account creation, returning sign-in and deletion. Nearby search, Arabic and widgets are useful short extras. Keep results legible; there is no need to read an entire surah or finish every adhkar collection.

## Shot sequence

| Step | Actual route/action | What the reviewer should see |
|---|---|---|
| 1. Launch and guest access | Start at the iPhone Home Screen, tap Haneen. On the welcome screen tap **Use Haneen without an account**. | Real app launch, onboarding and accessible core app without credentials or payment. |
| 1a. Regional age check, if required by Apple | Complete the Apple system age-range prompt if it appears after setup. A required declined/failed response must offer a retry; do not simulate a regional account condition in the recording. | The system flow completes before app access continues. Haneen does not save/upload the age response or bar parent-approved children merely because they are under 13. Regional Sandbox scenarios require separate validation. |
| 2. Prayer setup | On Home tap **Use my location**; allow while-using location. If already set, open the Settings cat/gear button, then **Prayer times → Location → Update**. Briefly show calculation settings. | A real city label, today's prayer times and the upcoming-prayer display. This build does not expose a manual-city picker. |
| 3. Qur'an reading | Open **Qur'an**. Tap the surah title / **Choose surah**, select Al-Fatihah, swipe a page. Open **More → Reading appearance** if needed to briefly show printed/digital reading options. | Bundled Arabic text and normal navigation/readability. |
| 4. Ayah actions | Tap an ayah; tap **Listen**, let a short portion play, then **Pause**. Tap **Save**, then **More**. Show translation and **Tafsir** loading actual content. Tap **Note**, enter a harmless note such as "Review demonstration", then **Done**. | Audio, save interaction, source-labelled translation/tafsir, and a private local note. |
| 5. Saved readings | Open **Saved → My ayat**, then open the saved item/note. | The change persists and there is no public posting, comments or user feed. |
| 6. Du'as and dhikr | Open **Du'as → Morning**. Show Arabic/meaning, source/context and reported virtue where that item has one. Tap its count control when present. Play a short portion of the full Abu Islam recording, then pause. Briefly show the corresponding Evening recording. Check playback with Wi-Fi and cellular data off, then restore them before the sign-in sequence. An optional SoundCloud source link should open externally only when tapped. Return to Home, scroll to **Tasbih**, choose a dhikr and increment it. | Sourced religious readings, local counters, visible reciter credit and bundled audio that plays offline. No SoundCloud SDK, API or embedded player is used. Show a matched excerpt, such as Surah an-Nas, if useful. Fifteen excerpts are available; do not claim every entry has its own clip or a specific reward. |
| 7. Feelings and situations | Open **Home → All feelings**, select any feeling and open a suggested dua. Go back normally. Open **Explore**, a group under **Where are you in life?**, then a situation; show its Qur'an, hadith and dua sections. | The requested typical discovery flow and stable back navigation, without a medical-treatment claim. |
| 8. Qibla and nearby places | On Home open **Qibla**, hold the physical phone flat and turn it slowly; return. Open **Explore → Mosques near me** and show a result/map. Optionally show **Halal food near me**. | Real compass heading and provider-backed place results. Do not label a restaurant certified unless its actual evidence supports that. |
| 9. Language and widgets | Open Settings, under **Reading** change **App language** to Arabic and briefly show a core screen; return to English if desired. In the iPhone Home Screen widget gallery search **Haneen** and add one prayer widget, then tap it. | Actual Arabic/right-to-left UI, installed widget content and deep link back into Haneen. |
| 10. Create a test account | **Settings → Account**. Enter a new controlled test email and tap **Continue with email**. Open its sign-in link on this iPhone, or enter the supplied code and tap **Verify & continue**. There is no separate Sign up selector. | A completed real registration, followed by **SIGNED IN** on the account page. A video may avoid exposing the code while still showing the real before/after result. This remains pending until production email delivery and the account flow are verified. |
| 11. Returning sign-in | Tap **Sign out**. Enter the same email and choose **Continue with email** again. Open a fresh link or verify the latest code, then show the signed-in account page. | The same flow works for returning users; no separate Sign in selector. Show completion, not only the form. Apple/Google buttons can also be shown; demonstrate a complete account lifecycle and follow any additional provider-specific request from Apple. |
| 12. Delete the test account | **Account → Delete account**. Keep **Prefer not to say**, leave written feedback empty, tap **Delete account**, then confirm **Delete account**. If the demo uses an Apple-linked account instead, complete the fresh Apple authorisation with the same Apple identity. | Deletion completes and the screen returns to the signed-out account UI. Feedback is visibly optional. Core guest access still works; local notes/bookmarks remain separate. |

If the app is already installed and onboarding has been completed, **Settings → Welcome tour** can show that UI, but identify it honestly as a replay. The recording must still start with an actual launch; a replay must not be described as a fresh installation.

The welcome-screen email sheet uses **Continue with email → enter email → Continue**, then opens a link or accepts a code through **Sign in**. The Settings account screen labels its corresponding code action **Verify & continue**. Both create an account on first verified use and sign returning users in.

Show the installed version/build through the **Version** row at the bottom of Settings, below **Sources & privacy**. It reads the actual bundle values; the About footer does not include the build number.

On 16 September at 09:14 UTC, developer tools verified the connected physical iPhone 15 running **iOS 27.0 (24A437)**. The owner is recording directly on the phone after Mac capture attempts failed. This verifies device readiness, not a completed walkthrough; fill the recording evidence below only after inspecting the real video.

## Inapplicable flows to explain in the response

- **Public UGC report/block:** not applicable. Notes and reflections are private on-device content; there is no public user-content feed, chat, comments or user-to-user messaging. The iOS share sheet is a user-directed export.
- **Purchases/subscriptions:** not applicable. No paid tier, external checkout, IAP or subscription exists in this release.
- **Runtime AI:** not applicable. No AI/chat/generation service is called by the shipped app. Illustration assets are static.
- **Demo credentials:** core review does not need them. Optional email sign-in accepts the reviewer's own reachable email. If Apple specifically requests a supplied account later, provide a controlled review account and a workable authentication method; never put the owner's account credentials into a recording or public document.

## Recording evidence — complete after recording

| Field | Recorded value |
|---|---|
| Physical iPhone model | PENDING |
| Installed iOS version | PENDING |
| Haneen version/build | Target 1.0 (2); installed/recorded build PENDING |
| Recording date | PENDING |
| Video filename or accessible review link | PENDING |
| Launch/setup timestamp | PENDING |
| Main feature timestamps | PENDING |
| Registration/sign-in/deletion timestamps | PENDING |
| Guest access after deletion timestamp | PENDING |
| Reviewer can open the attachment/link without a new access request | NOT YET VERIFIED |
| Production email delivery and account lifecycle | PENDING |

Before sending, watch the exported video once and confirm that the exact release build, physical-device actions, account completion/deletion and any loading results are actually visible. Attach the video or supply a stable accessible link in App Review, then replace the pending reference in `AppStore/ReviewResponse-2026-09-16.md`. No successful device test or attachment upload is asserted by this script.
