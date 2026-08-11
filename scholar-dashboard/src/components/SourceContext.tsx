import { CaretDown } from '@phosphor-icons/react/CaretDown'
import { useState } from 'react'
import { useTranslation } from '../i18n/useTranslation'
import type { GuidanceItem } from '../types'

interface SourceContextProps {
  item: GuidanceItem
  variant?: 'rail' | 'editor'
}

export function SourceContext({ item, variant = 'rail' }: SourceContextProps) {
  const { locale, t } = useTranslation()
  const [mobileExpanded, setMobileExpanded] = useState(false)
  const itemTitle = locale === 'ar' ? item.titleAr || item.titleEn : item.titleEn || item.titleAr
  const surahName = locale === 'ar'
    ? item.surahNameAr || item.surahNameEn
    : item.surahNameEn || item.surahNameAr
  const surahVerse = t('source.surahVerse', { surah: surahName, verse: item.verseKey })

  return (
    <aside className={`source-context source-context--${variant}`} aria-label={t('source.title')}>
      <h2 className={variant === 'editor' ? 'sr-only' : undefined}>{t('source.title')}</h2>
      <section className="source-section source-section--situation">
        <h3>{variant === 'editor' ? itemTitle : t('source.situation')}</h3>
        {variant === 'rail' ? <p>{itemTitle}</p> : <p>{surahVerse}</p>}
      </section>

      {variant === 'editor' ? (
        <button
          aria-expanded={mobileExpanded}
          className="mobile-source-toggle"
          onClick={() => setMobileExpanded((expanded) => !expanded)}
          type="button"
        >
          {mobileExpanded ? t('source.hideFull') : t('source.showFull')}
          <CaretDown aria-hidden="true" size={17} weight="bold" />
        </button>
      ) : null}

      <div className={`source-context__details ${mobileExpanded ? 'source-context__details--open' : ''}`}>
        <section className="source-section">
          <h3>{variant === 'editor' ? t('source.fullArabicAyah') : t('source.ayah')}</h3>
          {variant === 'rail' ? <p>{surahVerse}</p> : null}
          {item.ayahAr ? (
            <p className="quran-arabic" dir="rtl" lang="ar">
              {item.ayahAr}
            </p>
          ) : (
            <p className="source-missing">{t('source.textPending')}</p>
          )}
        </section>

        <section className="source-section">
          <h3>
            {variant === 'editor'
              ? t('source.approvedEnglishMeaning')
              : t('source.existingEnglishMeaning')}
          </h3>
          {item.meaningEn ? (
            <p dir="ltr" lang="en">{item.meaningEn}</p>
          ) : (
            <p>{t('source.meaningPending')}</p>
          )}
        </section>

        <section className="source-section source-section--last">
          <h3>{t('source.whyReading')}</h3>
          <p>
            {(locale === 'ar' ? item.orientationAr : item.orientationEn) ||
              t('source.orientationPending')}
          </p>
        </section>
      </div>
    </aside>
  )
}
