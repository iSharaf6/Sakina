import { useContext } from 'react'
import { LanguageContext, type LanguageContextValue } from './LanguageContext'

export function useTranslation(): LanguageContextValue {
  const context = useContext(LanguageContext)
  if (!context) throw new Error('useTranslation must be used within LanguageProvider')
  return context
}
