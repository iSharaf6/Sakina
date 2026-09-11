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

Four optional steps: an actual ayah, the person's reading intention, optional
reminders/location, then appearance/widgets/account. Finish opens the selected
area. Skip enters immediately. Settings can replay the welcome tour.

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

## Account deployment

Apple, Google OAuth (PKCE), and email OTP sign-up/sign-in use Supabase Auth. The
SDK maintains sessions; native Apple sign-in uses a secure random hashed nonce.
The iOS app contains only a public client key, never a service-role key.
The account UI explicitly says when the backend is not configured and does not
pretend to create an account. Guest reading remains available. Authentication
alone does not upload notes or claim cross-device library sync.

Required external configuration before live testing:
1. Set Xcode build settings `YAQEEN_AUTH_SUPABASE_URL` and
   `YAQEEN_AUTH_SUPABASE_KEY` to the chosen project's URL and public key. These
   are separate from the existing scholar dashboard configuration.
2. Enable email, Google and Apple providers in that Supabase project's Auth
   settings, with provider credentials. Allow `yaqeen://auth-callback` as a
   redirect URL. Configure the email template to include `{{ .Token }}` so the
   code entry screen can verify it. Configure production SMTP/rate limits.
3. Enable Sign in with Apple on `com.islamsharaf.sakina` in the Apple Developer
   account and refresh the signing profile. The entitlement is present locally.
4. Deploy `supabase/functions/delete-account`. It validates the bearer token
   server-side and deletes only that authenticated user; no supplied user ID is
   trusted. Service-role credentials stay in the function environment.
5. Verify sign-up, returning sign-in, canceled OAuth, email delivery, sign-out,
   and account deletion using test accounts on a signed device. Check provider
   terms/privacy settings before release.

No authentication project or provider credentials were supplied during this
implementation. The code compiles, but real provider sign-in and server account
deletion cannot be claimed as tested until configured and deployed.
