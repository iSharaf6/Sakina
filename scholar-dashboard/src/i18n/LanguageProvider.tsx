import {
  useCallback,
  useLayoutEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { LanguageContext, type LanguageContextValue } from './LanguageContext'
import {
  defaultLocale,
  formatTranslation,
  languageStorageKey,
  translations,
  type Locale,
  type TranslationKey,
  type TranslationValues,
} from './translations'

interface StoredLanguagePreference {
  locale: Locale
  chosen: boolean
}

function readPreference(): StoredLanguagePreference {
  try {
    const stored = window.localStorage.getItem(languageStorageKey)
    if (stored === 'ar' || stored === 'en') return { locale: stored, chosen: true }
  } catch {
    // Storage may be unavailable in privacy-restricted browser contexts.
  }
  return { locale: defaultLocale, chosen: false }
}

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [preference, setPreference] = useState<StoredLanguagePreference>(readPreference)
  const direction = preference.locale === 'ar' ? 'rtl' : 'ltr'

  useLayoutEffect(() => {
    document.documentElement.lang = preference.locale
    document.documentElement.dir = direction
    document.title = translations[preference.locale]['app.brand']
  }, [direction, preference.locale])

  const setLocale = useCallback((locale: Locale) => {
    setPreference({ locale, chosen: true })
    try {
      window.localStorage.setItem(languageStorageKey, locale)
    } catch {
      // The in-memory choice still works when storage is unavailable.
    }
  }, [])

  const t = useCallback(
    (key: TranslationKey, values?: TranslationValues) =>
      formatTranslation(translations[preference.locale][key], values),
    [preference.locale],
  )

  const value = useMemo<LanguageContextValue>(
    () => ({
      locale: preference.locale,
      direction,
      hasChosenLanguage: preference.chosen,
      setLocale,
      t,
    }),
    [direction, preference.chosen, preference.locale, setLocale, t],
  )

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
}
