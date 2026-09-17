# Haneen auth emails

Paste each file into Supabase → Authentication → Emails → the matching template, with the subject below. Keep `{{ ... }}` placeholders exactly as written.

| Supabase template | File | Subject |
|---|---|---|
| Confirm sign up | `confirm-signup.html` | Welcome to Haneen | أهلًا بك في حنين |
| Invite user | `invite-user.html` | You’re invited to Haneen | دعوة إلى حنين |
| Magic link or OTP | `magic-link.html` | Your Haneen sign-in | تسجيل الدخول إلى حنين |
| Change email address | `change-email.html` | Confirm your new email | تأكيد بريدك الجديد |
| Reset password | `reset-password.html` | Reset your Haneen password | إعادة تعيين كلمة المرور |
| Reauthentication | `reauthentication.html` | Confirm it’s you | تأكيد هويتك |

Reauthentication has no link in Supabase, so that email carries the code only. The logo loads from `https://isharaf6.github.io/Sakina/haneen-logo-email.png`, which exists only after `scholar-dashboard/public/haneen-logo-email.png` is pushed and deployed.

`magic-link.html` is identical to `../AuthEmailTemplate.html`.
