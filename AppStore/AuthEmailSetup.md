# Haneen authentication email setup

**Status, 16 September 2026:** template prepared locally. Brevo account/phone checks and the Haneen sender verification are complete; custom SMTP connection is still in progress, and delivery has not been verified. No credentials are stored in these files.

## Sender and SMTP

1. Finish the Brevo account setup and any transactional-sending activation it requests. Verify a sender address you control and use **Haneen** as its display name. The owner currently has no custom domain: do not enter or authenticate a domain they do not own.
2. Brevo documents temporary sender-address replacement for free email addresses. For transactional mail this can use a `t-sender-sib.com` address. Confirm that the account permits this route and inspect the actual sender in a received test message; a Haneen display name does not make it a Haneen-owned domain. Brevo describes replacement as a stopgap, so do not promise a permanent free-domain arrangement. [Brevo sender requirements](https://help.brevo.com/hc/en-us/articles/14925263522578-Comply-with-Gmail-Yahoo-and-Microsoft-s-requirements-for-email-senders)
3. In Brevo **Settings → SMTP & API → SMTP**, copy the displayed SMTP login and generate a dedicated SMTP key named `Haneen Supabase Auth`. The password is that SMTP key, not a Brevo API key or the account password. Keep it in the provider dashboard/password manager, never Git. [Brevo SMTP setup](https://help.brevo.com/hc/en-us/articles/7924908994450-Send-transactional-emails-using-Brevo-SMTP)
4. In the Supabase project's **Authentication → Email → SMTP settings**, enable custom SMTP with host `smtp-relay.brevo.com`, port `587`, the displayed SMTP login, the SMTP key, and the verified sender. Use sender name **Haneen**. Save only once these account-specific details are available. Supabase's default mailer is restricted to project-team recipients and is unsuitable for public signup. [Supabase custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
5. Disable click/link rewriting and open tracking for authentication mail. Supabase warns that email tracking can break its confirmation links. [Email template limitations](https://supabase.com/docs/guides/auth/auth-email-templates#email-tracking)

## Template and redirect

- Paste `AuthEmailTemplate.html` into Supabase's **Magic Link / OTP** email template. Also apply it to **Confirm signup** for new email users. Suggested subject: **Your Haneen sign-in | تسجيل الدخول إلى حنين**.
- Preserve the two Supabase placeholders exactly: `{{ .ConfirmationURL }}` for the link and `{{ .Token }}` for the code. Do not replace them with Brevo template variables, hard-code a token, or wrap the confirmation link in another redirect. Supabase renders the HTML before handing the email to SMTP. [Supabase template variables](https://supabase.com/docs/guides/auth/auth-email-templates#terminology)
- Keep `yaqeen://auth-callback` in Supabase's allowed redirect URLs. This is the app's existing callback used by `CompanionAccount.swift`; the visible email/app brand is Haneen. Do not rename the callback independently of the app.
- The template uses real text, Arabic language/direction attributes, a large link, and a left-to-right code. It has no remote images, web fonts, scripts, forms or tracking pixels.

## Verify before calling it ready

Use a tester's consenting address outside the Supabase project team. Request a fresh email from the app, check its inbox and spam folder, and check the Supabase/Brevo delivery logs without recording tokens. Open the link on the same iPhone and confirm the account becomes signed in. Request a separate fresh email and test its code in Haneen; using a link consumes that message's one-time credential. Confirm that an expired or previously used code is rejected. Until both delivery and sign-in work, keep this setup marked incomplete.
