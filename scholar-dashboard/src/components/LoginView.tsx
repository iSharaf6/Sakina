import { useState } from 'react'
import { BrandMark } from './BrandMark'
import { CommandButton } from './CommandButton'

interface LoginViewProps {
  status: 'signed_out' | 'unauthorized' | 'misconfigured'
  onSendMagicLink: (email: string) => Promise<void>
  onVerifyCode: (email: string, token: string) => Promise<void>
}

export function LoginView({ status, onSendMagicLink, onVerifyCode }: LoginViewProps) {
  const [email, setEmail] = useState('')
  const [token, setToken] = useState('')
  const [sent, setSent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  const sendLink = async () => {
    setBusy(true)
    setMessage('')
    try {
      await onSendMagicLink(email.trim())
      setSent(true)
      setMessage('Check your invited email for a secure link or one-time code.')
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to send the secure link.')
    } finally {
      setBusy(false)
    }
  }

  const verify = async () => {
    setBusy(true)
    setMessage('')
    try {
      await onVerifyCode(email.trim(), token.trim())
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to verify the code.')
      setBusy(false)
    }
  }

  return (
    <main className="login-page">
      <section className="login-panel">
        <div className="login-brand">
          <BrandMark size={40} />
          <span>Yaqeen Review</span>
        </div>
        <div className="login-copy">
          <h1>Scholar sign in</h1>
          {status === 'misconfigured' ? (
            <>
              <p>This production deployment has not been connected to Supabase.</p>
              <p className="login-notice">
                Add the public Supabase URL and publishable key at deployment time. Development demo access is never enabled in production.
              </p>
            </>
          ) : (
            <>
              <p>Use the email address that was privately invited to review Yaqeen content.</p>
              {status === 'unauthorized' ? (
                <p className="login-notice" role="alert">
                  That account is not authorised for scholar review and has been signed out.
                </p>
              ) : null}
              <form
                onSubmit={(event) => {
                  event.preventDefault()
                  void (sent && token.trim() ? verify() : sendLink())
                }}
              >
                <label className="form-field">
                  <span>Invited email</span>
                  <input
                    autoComplete="email"
                    name="email"
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder="name@example.com"
                    required
                    type="email"
                    value={email}
                  />
                </label>
                {sent ? (
                  <label className="form-field">
                    <span>One-time code</span>
                    <input
                      autoComplete="one-time-code"
                      inputMode="numeric"
                      name="otp"
                      onChange={(event) => setToken(event.target.value.replace(/\D/g, '').slice(0, 8))}
                      placeholder="Enter the code"
                      value={token}
                    />
                  </label>
                ) : null}
                {message ? <p className="login-message" role="status">{message}</p> : null}
                <CommandButton disabled={busy || !email.trim()} type="submit" variant="primary">
                  {busy ? 'Please wait…' : sent && token.trim() ? 'Verify code' : 'Email secure sign-in link'}
                </CommandButton>
                {sent ? (
                  <button className="login-resend" disabled={busy} onClick={sendLink} type="button">
                    Send another link or code
                  </button>
                ) : null}
              </form>
            </>
          )}
        </div>
        <p className="login-footer">Invite-only editorial access · No public registration</p>
      </section>
      <div className="login-atmosphere" aria-hidden="true">
        <span>Review with care.</span>
        <p>Original Arabic insight, human-reviewed English, and clear sources.</p>
      </div>
    </main>
  )
}
