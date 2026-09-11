# Companion experience

The previous reader work was pushed to `main` as `7d52f76` before this change.

## Appearance and layout

The shared palette uses charcoal-green surfaces, softer sage accents and quieter
background ornament in dark mode. Reusable rows and guidance rows now have real
vertical padding; grid titles can wrap. Accent fills use a semantic foreground
for readable contrast. Existing pencil artwork is rendered with only the
edge-connected white paper removed, cached per asset. The original files are
preserved. Tabs use the same rendering path.

The new appearance illustration was generated using the built-in image tool and
saved at `Shared/CompanionAssets.xcassets/Companion-appearance.imageset/artwork.png`.
Prompt: match the existing cream-and-charcoal pencil cat and moss scarf, curled
around a half-sun/half-moon medallion; ochre sun, moss moon, no lettering, gradients
or 3D. The first output included a checkerboard, so a targeted edit replaced it
with solid white for the app's display mask. The supplied existing cat artwork
is animated gently in onboarding; Reduce Motion removes movement.

## Onboarding

One welcome screen replaces the former questionnaire. Apple, Google and email
are immediately available. A phone preview cycles through the actual HomeView,
PrintedMushafPage and DhikrListView, with the existing cat artwork animated beside
it. The view responds to light/dark appearance, pauses while inactive or showing
sheets, and respects Reduce Motion. Preview dots are manually selectable; the
pause button is accessible. Successful authentication opens Home. Existing users
can replay the welcome screen from Settings and dismiss it without signing in.
No notification or location permissions are requested by the welcome screen.

The supplied [onboarding reference video](https://www.youtube.com/watch?v=Qsq-Sj_rojU)
was reviewed using its transcript and the Tiimo screenshot supplied by the user.
The product demonstration is rendered natively rather than a bundled video.
Google's logo comes unchanged from the GoogleSignIn-iOS SDK resource bundle.

Design references checked September 2026, for the requested August 2026-era
experience (no claim to have an archived August snapshot):
- [Apple: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding): brief, optional, experiential guidance.
- [Apple: Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications): useful, relevant invitations under the person's control.
- [Apple: Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets): glanceable content and direct destinations.

## Reminders

Local notifications only; no notification server or analytics tracking. Daily
reflection rotates seven weekly titles, morning/evening adhkar repeat, and five
prayer alerts use absolute UTC instants from the saved calculation. Sunrise is
excluded. Optional sound is the standard notification tone, **not a full adhan
recording**. Reflective invitations move to the end of configured quiet hours;
prayer alerts retain their exact time, as explained in settings. Foreground
notifications do not interrupt reading. Actions open the right screen or snooze
for ten minutes. No permissions are requested until the person taps Allow.

Requests are capped at 60, leaving room under iOS's pending notification limit.
Prayer schedules cover today plus seven days, so the person needs to reopen the
app to replenish them. The last calculation location stays in app-private
UserDefaults; the shared widget schedule excludes coordinates. On foreground or
calculation preference changes, that location refreshes the schedule. Existing
installs need one location update to seed this local calculation cache.

Reset Settings clears an explicit preference allowlist and reschedules alerts;
notes, ayat, accounts, saved place and completed onboarding remain untouched.

## Ten widget choices

1. Ayah of the Day — small/medium
2. Pinned Situation — small/medium
3. Prayer Times — medium and Lock Screen accessories
4. Prayer Times · Fajr–Dhuhr — rectangular Lock Screen
5. Prayer Times · Asr–Isha — rectangular Lock Screen
6. Prayer Companion — small/medium and cat Lock Screen
7. Until the Next Prayer — small/medium live countdown
8. Morning Companion — small/medium, morning adhkar link
9. Evening Companion — small/medium, evening adhkar link
10. A Quiet Moment — small/medium, daily guidance link

Settings → Widget collection previews production card layouts and explains how
to add each one. iOS requires the user to add widgets; the app cannot install
widgets automatically. Gallery times are explicitly labeled as examples. Lock
Screen cat art uses the drawing's luminance as a monochrome mask.

## Account deployment — 11 September 2026

The app now connects to the existing **Yaqeen** project
`uouukrvkkoegfnhrldwg` (Sydney) using its publishable client key, configured in
`project.yml` and the generated Xcode project. The app contains no provider
client secret or Supabase service-role key.

Completed live configuration:
- Enabled native Apple authentication with audience `com.islamsharaf.sakina`.
- Created Google Cloud project **Yaqeen** (`mythical-style-508310-a4`) and web OAuth
  client **Yaqeen Supabase Sign In**. Its callback is
  `https://uouukrvkkoegfnhrldwg.supabase.co/auth/v1/callback`.
- Stored Google's OAuth secret only in the Supabase provider configuration;
  nonce verification remains enabled. Google audience is **In production**.
- Added exact native redirect `yaqeen://auth-callback` to Supabase's allowlist.
- Published app information and privacy pages through the existing Pages workflow:
  `https://isharaf6.github.io/Sakina/app.html` and `/Sakina/privacy.html`.
- Deployed `delete-account` v1. It verifies the caller with `auth.getUser()` before
  deleting that caller only. Gateway JWT checking is off because this function
  implements its own authentication, including compatibility with current JWT
  signing keys. An unauthenticated POST was verified to return HTTP 401.

Verification:
- Simulator build succeeded. All 57 unit tests passed, including email validation.
- Verified the native Google button opens the system authentication browser and
  reaches Google's credential screen. An end-to-end authenticated Google session
  has not yet been completed by the account owner in the simulator.
- Supabase accepted an actual owner email sign-in request with HTTP 200. This
  verifies request acceptance, not receipt or successful session creation.
- Inspected welcome and email screens in dark mode, preview navigation, and the
  light-mode welcome. Screenshots are in ignored `build/welcome-qa/`.

Remaining external steps (do not describe these as completed):
- Apple Developer login is awaiting the owner's device verification code. The
  portal app identifier/capability and a signed-device Apple login remain unverified.
- Supabase uses its default email service, restricted to project team addresses.
  General public email sign-in needs an owner-approved sending domain and SMTP
  service. The app supports the currently delivered magic link and optionally a
  code, so it no longer promises an OTP when the template sends a link.
- Full provider session restoration, returning-account sign-in and authenticated
  account deletion still need end-to-end device verification after owner sign-in.

Authentication does not upload local notes or bookmarks. The public privacy
page describes authentication data separately from the local library and optional
Google Drive backup.
