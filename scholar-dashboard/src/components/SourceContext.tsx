import { ChevronDown } from 'lucide-react'
import { useState } from 'react'
import type { GuidanceItem } from '../types'

interface SourceContextProps {
  item: GuidanceItem
  variant?: 'rail' | 'editor'
}

export function SourceContext({ item, variant = 'rail' }: SourceContextProps) {
  const [mobileExpanded, setMobileExpanded] = useState(false)

  return (
    <aside className={`source-context source-context--${variant}`} aria-label="Source context">
      <h2 className={variant === 'editor' ? 'sr-only' : undefined}>Source context</h2>
      <section className="source-section source-section--situation">
        <h3>{variant === 'editor' ? item.titleEn : 'Situation'}</h3>
        {variant === 'rail' ? <p>{item.titleEn}</p> : <p>{`Surah ${item.surahNameEn} · ${item.verseKey}`}</p>}
      </section>

      {variant === 'editor' ? (
        <button
          aria-expanded={mobileExpanded}
          className="mobile-source-toggle"
          onClick={() => setMobileExpanded((expanded) => !expanded)}
          type="button"
        >
          {mobileExpanded ? 'Hide full source context' : 'View full source context'}
          <ChevronDown aria-hidden="true" size={17} />
        </button>
      ) : null}

      <div className={`source-context__details ${mobileExpanded ? 'source-context__details--open' : ''}`}>
        <section className="source-section">
          <h3>{variant === 'editor' ? 'Full Arabic ayah' : 'Ayah'}</h3>
          {variant === 'rail' ? <p>{`Surah ${item.surahNameEn} · ${item.verseKey}`}</p> : null}
          {item.ayahAr ? (
            <p className="quran-arabic" dir="rtl" lang="ar">
              {item.ayahAr}
            </p>
          ) : (
            <p className="source-missing">Source text is awaiting the protected content sync.</p>
          )}
        </section>

        <section className="source-section">
          <h3>{variant === 'editor' ? 'Approved English meaning' : 'Existing English meaning'}</h3>
          <p>{item.meaningEn || 'Source meaning is awaiting the protected content sync.'}</p>
        </section>

        <section className="source-section source-section--last">
          <h3>Why this reading</h3>
          <p>{item.orientationEn}</p>
        </section>
      </div>
    </aside>
  )
}
