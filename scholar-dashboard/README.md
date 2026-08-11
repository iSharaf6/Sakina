# Yaqeen Scholar Review

Private React/Vite editorial dashboard for the invited Yaqeen scholar and administrator. It is intentionally separate from the public iOS app and never reads users’ bookmarks, reflections, searches, prayer location, or backups.

## Local review

```sh
npm install
npm run dev -- --host 127.0.0.1
```

Open `http://127.0.0.1:5173/`. When Supabase variables are absent, Vite development mode uses deterministic local queue data and shows `Development demo · local data only`. This bypass exists only behind `import.meta.env.DEV`; a production build without provider configuration shows a configuration-required screen and never simulates authentication.

The first visit opens an Arabic-first language choice. Arabic and English are both complete interface languages, the choice persists locally, and the document switches its `lang` and `dir` attributes between RTL and LTR. The language can always be changed again from sign-in or the workspace navigation.

To inspect the admin-only controls locally, open:

```text
http://127.0.0.1:5173/?demoRole=admin
```

Direct editor QA is available through `?review=<guidance-item-id>`, for example `?review=marriage-problems-4-35` in the deterministic demo.

`demoRole` is compiled out of production behavior. The deployed dashboard accepts only invited Supabase Auth users with an explicit `scholar` or `admin` role.

## Quality checks

```sh
npm run lint
npm run typecheck
npm run build
npm run preview -- --host 127.0.0.1
```

The same lint, type-check, production build, and high-severity dependency audit
run in `.github/workflows/scholar-dashboard.yml` for every dashboard change.

## Visual QA evidence

The canonical candidate-3 captures are under `docs/screenshots/`:

- `candidate3-login-ar-768x1024.png`
- `candidate3-queue-ar-390x844.png`
- `candidate3-queue-ar-1440x900.png`
- `candidate3-editor-ar-390x844.png`
- `candidate3-reference-dialog-ar-390x844.png`
- `candidate3-profile-consent-ar-390x844.png`
- `candidate3-profile-ar-1440x900.png`

The final responsive audit covers 390, 430, 768, 1024, and 1440 CSS-pixel viewports; Arabic RTL and English LTR; keyboard focus traps and restoration; 44px effective targets; reduced motion; horizontal overflow; Axe WCAG checks; console/network errors; and mobile bottom-navigation clearance.

## Provider setup

1. Deploy the repository’s Supabase migrations and Edge Functions described in `../supabase/README.md`.
2. Disable public sign-up in Supabase Auth. Invite the administrator and scholar emails privately.
3. Assign roles in `user_roles`; do not expose a role-writing browser policy.
4. Configure deployment variables from `.env.example`:

   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_PUBLISHABLE_KEY`
   - `VITE_TRANSLATION_FUNCTION=translate-scholar-insight`

5. Keep the service-role key, sync token, and translation-provider key only in server/Edge Function secrets.
   Set the server-side `SCHOLAR_DASHBOARD_ORIGINS` secret to the deployed dashboard's
   exact origin (or a comma-separated list of approved origins) so authenticated
   browser translation preflights are accepted; unlisted origins are rejected.
6. Set the production site URL and redirect URL in Supabase Auth so email magic links return to the deployed dashboard.
7. Upload the approved portrait to the public-media `scholar-avatars` bucket under the scholar owner folder and store its path in the scholar profile. Its owner-folder write policy is intended only for approved public profile media—never upload drafts, private records, or sensitive media there. The bundled original portrait remains the deterministic local/dashboard fallback.

Avatar replacement is an initial manual Supabase activation step in this release; the dashboard does not claim to upload or crop replacement files. An administrator should upload only the approved public portrait and set `avatar_path`. The profile editor then renders that exact public Storage object and keeps **Verify & publish** disabled until it loads successfully; it never silently substitutes the bundled portrait for a failed remote review image.

The browser contract uses the protected RPC workflow:

```text
create_scholar_insight_draft
create_scholar_replacement_draft
save_scholar_insight_draft
translate-scholar-insight (Edge Function)
review_scholar_insight_translation
submit_scholar_insight
publish_scholar_insight / archive_scholar_insight (admin only)
```

The dashboard never writes status columns directly. Save, translation review, and submit all carry `p_expected_revision_number`, so stale browser state conflicts instead of overwriting a newer edit. The translation Edge Function returns both `body_en` and the `revision_number` it translated. A replacement is created atomically from the live publication through `create_scholar_replacement_draft`; the dashboard does not write over the published row. A machine-generated translation is always `generated`; the scholar must explicitly review it before submission, and only an administrator can publish or archive.

## Scholar profile safety

Only the supplied English identity and Facebook/Instagram links are seeded. Arabic identity, qualification/title, and biographies stay empty until approved facts are supplied.

The backend deliberately makes a scholar’s self-edited profile private and unverified. The UI requires acknowledgement before saving and reports the resulting review state. Administrator edits use `admin_upsert_scholar_profile`, preserving the existing visibility state; the admin-only **Verify & publish** and **Make private** controls call `admin_set_scholar_profile_visibility`.
