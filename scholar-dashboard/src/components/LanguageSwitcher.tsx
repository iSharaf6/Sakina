import { useTranslation } from '../i18n/useTranslation'

export function LanguageSwitcher({ compact = false }: { compact?: boolean }) {
  const { locale, setLocale, t } = useTranslation()

  return (
    <div
      aria-label={t('language.switchLabel')}
      className={`language-switcher${compact ? ' language-switcher--compact' : ''}`}
      role="group"
    >
      <button
        aria-label={t('language.changeToArabic')}
        aria-pressed={locale === 'ar'}
        lang="ar"
        onClick={() => setLocale('ar')}
        type="button"
      >
        {t('language.arabic')}
      </button>
      <button
        aria-label={t('language.changeToEnglish')}
        aria-pressed={locale === 'en'}
        lang="en"
        onClick={() => setLocale('en')}
        type="button"
      >
        {t('language.english')}
      </button>
    </div>
  )
}
