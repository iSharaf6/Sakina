import type { Locale, TranslationKey } from './translations'

interface TranslationFunction {
  (key: TranslationKey): string
}

export class LocalizedUIError extends Error {
  readonly isLocalizedUIError = true
}

export function localizedErrorMessage(
  error: unknown,
  locale: Locale,
  t: TranslationFunction,
  fallback: TranslationKey = 'errors.generic',
): string {
  if (error instanceof LocalizedUIError) return error.message
  if (locale === 'en' && error instanceof Error && error.message.trim()) return error.message
  return t(fallback)
}
