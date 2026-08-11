import { createContext } from 'react'
import type { Locale, TranslationKey, TranslationValues } from './translations'

export interface LanguageContextValue {
  locale: Locale
  direction: 'rtl' | 'ltr'
  hasChosenLanguage: boolean
  setLocale: (locale: Locale) => void
  t: (key: TranslationKey, values?: TranslationValues) => string
}

export const LanguageContext = createContext<LanguageContextValue | null>(null)
