import { DeviceMobile } from '@phosphor-icons/react/DeviceMobile'
import { useEffect, useState } from 'react'
import { useTranslation } from '../i18n/useTranslation'
import { localizedErrorMessage } from '../i18n/localizedError'
import { BrandMark } from './BrandMark'
import { CommandButton } from './CommandButton'
import { LanguageSwitcher } from './LanguageSwitcher'

interface LoginViewProps {
  status: 'signed_out' | 'unauthorized' | 'misconfigured'
  onSendMagicLink: (email: string) => Promise<void>
  onVerifyCode: (email: string, token: string) => Promise<void>
}

export function LoginView({ status, onSendMagicLink, onVerifyCode }: LoginViewProps) {
  const { locale, t } = useTranslation()
  const [email, setEmail] = useState('')
  const [token, setToken] = useState('')
  const [sent, setSent] = useState(false)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    setMessage(sent ? t('login.sent') : '')
  }, [locale, sent, t])

  const sendLink = async () => {
    setBusy(true)
    setMessage('')
    try {
      await onSendMagicLink(email.trim())
      setSent(true)
      setMessage(t('login.sent'))
    } catch (error) {
      setMessage(localizedErrorMessage(error, locale, t, 'errors.sendLink'))
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
      setMessage(localizedErrorMessage(error, locale, t, 'errors.verifyCode'))
      setBusy(false)
    }
  }

  return (
    <main className="login-page">
      <section className="login-panel">
        <div className="login-brand">
          <BrandMark size={40} />
          <span>{t('app.brand')}</span>
        </div>
        <LanguageSwitcher compact />
        <div className="login-copy">
          <h1>{t('login.title')}</h1>
          {status === 'misconfigured' ? (
            <>
              <p>{t('login.misconfigured')}</p>
              <p className="login-notice">
                {t('login.misconfiguredNotice')}
              </p>
            </>
          ) : (
            <>
              <p>{t('login.description')}</p>
              {status === 'unauthorized' ? (
                <p className="login-notice" role="alert">
                  {t('login.unauthorized')}
                </p>
              ) : null}
              <form
                onSubmit={(event) => {
                  event.preventDefault()
                  void (sent && token.trim() ? verify() : sendLink())
                }}
              >
                <label className="form-field" htmlFor="login-email">
                  <span>{t('login.emailLabel')}</span>
                  <input
                    autoComplete="email"
                    dir="ltr"
                    id="login-email"
                    name="email"
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder={t('login.emailPlaceholder')}
                    required
                    type="email"
                    value={email}
                  />
                </label>
                {sent ? (
                  <label className="form-field" htmlFor="login-otp">
                    <span>{t('login.codeLabel')}</span>
                    <input
                      autoComplete="one-time-code"
                      dir="ltr"
                      id="login-otp"
                      inputMode="numeric"
                      name="otp"
                      onChange={(event) => setToken(event.target.value.replace(/\D/g, '').slice(0, 8))}
                      placeholder={t('login.codePlaceholder')}
                      value={token}
                    />
                  </label>
                ) : null}
                {message ? <p className="login-message" role="status">{message}</p> : null}
                <CommandButton disabled={busy || !email.trim()} type="submit" variant="primary">
                  {busy ? t('login.wait') : sent && token.trim() ? t('login.verify') : t('login.sendLink')}
                </CommandButton>
                {sent ? (
                  <button className="login-resend" disabled={busy} onClick={sendLink} type="button">
                    {t('login.resend')}
                  </button>
                ) : null}
              </form>
            </>
          )}
          <a
            aria-label={t('app.openAppHint')}
            className="login-open-app"
            href="haneen://"
            title={t('app.openAppHint')}
          >
            <DeviceMobile aria-hidden="true" size={18} weight="bold" />
            <span>{t('app.openApp')}</span>
          </a>
        </div>
        <p className="login-footer">{t('login.footer')}</p>
      </section>
      <div className="login-atmosphere" aria-hidden="true">
        <span>{t('login.atmosphereTitle')}</span>
        <p>{t('login.atmosphereBody')}</p>
      </div>
    </main>
  )
}
