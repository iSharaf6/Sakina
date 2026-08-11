import { useTranslation } from '../i18n/useTranslation'
import type { Insight } from '../types'

interface PublishedInsightContextProps {
  insight: Insight
  workingInsight: Insight | null
}

export function PublishedInsightContext({ insight, workingInsight }: PublishedInsightContextProps) {
  const { t } = useTranslation()
  return (
    <section aria-labelledby="currently-published-title" className="published-context">
      <header className="published-context__header">
        <div>
          <span className="published-context__eyebrow">{t('published.liveVersion')}</span>
          <h2 id="currently-published-title">{t('published.currently')}</h2>
        </div>
        <span className="published-context__readonly">{t('published.readOnly')}</span>
      </header>
      <p className="published-context__note">
        {workingInsight
          ? t('published.noteWithReplacement')
          : t('published.noteCurrent')}
      </p>
      <div className="published-context__body">
        <article>
          <h3>{t('published.arabicTitle')}</h3>
          {insight.bodyAr.trim() ? (
            <p className="published-context__arabic" dir="rtl" lang="ar">{insight.bodyAr}</p>
          ) : (
            <p className="published-context__empty">{t('published.arabicEmpty')}</p>
          )}
        </article>
        <article>
          <h3>{t('published.englishTitle')}</h3>
          {insight.bodyEn.trim() ? (
            <p dir="ltr" lang="en">{insight.bodyEn}</p>
          ) : (
            <p className="published-context__empty">{t('published.englishEmpty')}</p>
          )}
        </article>
      </div>
      {workingInsight ? (
        <section aria-label={t('published.workingLabel')} className="published-context__replacement">
          <header>
            <div>
              <span className="published-context__eyebrow">{t('published.replacement')}</span>
              <h3>{t('published.working')}</h3>
            </div>
            <span className="published-context__replacement-status">
              {workingInsight.status === 'submitted'
                ? t('published.submittedApproval')
                : t('published.draftProgress')}
            </span>
          </header>
          <div className="published-context__replacement-copy">
            <p dir="rtl" lang="ar">
              {workingInsight.bodyAr.trim() || t('published.arabicPreviewEmpty')}
            </p>
            {workingInsight.bodyEn.trim() ? (
              <p dir="ltr" lang="en">{workingInsight.bodyEn}</p>
            ) : (
              <p>{t('published.englishPreviewEmpty')}</p>
            )}
          </div>
        </section>
      ) : null}
    </section>
  )
}
