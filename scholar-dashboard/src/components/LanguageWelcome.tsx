import { BrandMark } from './BrandMark'
import { useTranslation } from '../i18n/useTranslation'
import { translations } from '../i18n/translations'

export function LanguageWelcome() {
  const { setLocale, t } = useTranslation()

  return (
    <main className="language-welcome">
      <section aria-labelledby="language-welcome-title" className="language-welcome__card">
        <div className="language-welcome__brand">
          <BrandMark size={40} />
          <span>{t('app.brand')}</span>
        </div>
        <p className="language-welcome__eyebrow">{t('language.chooseEyebrow')}</p>
        <h1 id="language-welcome-title">{t('language.chooseTitle')}</h1>
        <p>{t('language.chooseDescription')}</p>
        <div className="language-welcome__choices">
          <button lang="ar" onClick={() => setLocale('ar')} type="button">
            <strong>{translations.ar['language.arabic']}</strong>
            <span>{translations.ar['language.continueArabic']}</span>
          </button>
          <button dir="ltr" lang="en" onClick={() => setLocale('en')} type="button">
            <strong>{translations.en['language.english']}</strong>
            <span>{translations.en['language.continueEnglish']}</span>
          </button>
        </div>
      </section>
    </main>
  )
}
