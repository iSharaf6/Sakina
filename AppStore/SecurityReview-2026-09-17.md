# Haneen security review, 17 September 2026

Scope: the Supabase project `uouukrvkkoegfnhrldwg`, the iOS app, the scholar dashboard and the GitHub repository. Reference checklists: benavlabs/vibe-check and astoj/vibe-security. This is a configuration and code review, not a penetration test.

## Checked and sound

- **Row Level Security** is on for every public table; `account_library_documents` also forces it. Library policies compare `auth.uid()` to `user_id` and refuse anonymous sessions. Table grants are minimal (authenticated: select, plus insert/update on the library only; anon: none).
- **Privileged functions**: all 11 `SECURITY DEFINER` RPCs check `has_app_role` or `auth.uid()` internally, pin `search_path = ""`, and are not executable by `anon`. The Supabase advisor warning about them is expected for this design.
- **Edge functions**: `delete-account` verifies the caller's token with `auth.getUser` before anything else; `sync-guidance-manifest` requires a 32+ character token compared in constant time and caps body size; `translate-scholar-insight` has `verify_jwt` on and re-checks the caller. No function logs tokens or bodies.
- **Storage**: one bucket, 2 MB limit, JPEG/PNG/WebP only, writes limited to the owning scholar or an admin.
- **Secrets**: no keys, `.env`, certificates or service-role values in tracked files or in git history. GitHub secret scanning and push protection are enabled.
- **App**: no App Transport Security exceptions, no `http://` endpoints, no logging of credentials; the Supabase SDK keeps the session in the Keychain. The password field exists only for the App Review address.
- **Dashboard dependencies**: `npm audit` reports 0 vulnerabilities; no `innerHTML` use.

## Changed in this review

- Migration `20260917130000_read_only_public_scholar_views` (applied to production): the two public scholar views had default write grants for `anon` and `authenticated`. Base-table RLS already blocked writes; the grants are now `SELECT` only.
- Dashboard production build now carries a Content-Security-Policy and referrer policy (`scholar-dashboard/vite.config.ts`). Verified locally: page loads with no CSP violations. Live after the next push.

## Owner actions (dashboards Claude cannot reach)

Supabase → Authentication:
1. URL Configuration: Site URL is still `http://localhost:3000`. Set it to `yaqeen://auth-callback`; keep that as the only redirect URL.
2. Sign In / Providers: confirm anonymous sign-ins are off; keep "Secure email change" on; email OTP expiry 600–3600 seconds.
3. Rate Limits: keep email sends low (for example 30 per hour) and OTP verifications at the default or lower.
4. Give the review account a long random password (20+ characters). Leaked-password protection needs the Pro plan; it only matters for that one account.
5. Attack Protection → CAPTCHA would need an app change; not enabled, revisit if sign-in email abuse appears.

Accounts: turn on two-factor authentication for Supabase, Brevo, GitHub, the Apple developer account and the `haneen.app.contact` Google account.

Brevo: keep the authorised-IP list on; keep one SMTP key named for Supabase and delete unused API/SMTP keys; keep open and click tracking off for transactional mail.

GitHub: the repository is public, so never commit review passwords or provider keys; enable Dependabot alerts and security updates in Settings → Code security.

## Not covered

No physical-device traffic inspection, no third-party penetration test, and no review of Apple/Google provider console settings.
