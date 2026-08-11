import type { Insight } from '../types'

interface PublishedInsightContextProps {
  insight: Insight
  workingInsight: Insight | null
}

export function PublishedInsightContext({ insight, workingInsight }: PublishedInsightContextProps) {
  return (
    <section aria-labelledby="currently-published-title" className="published-context">
      <header className="published-context__header">
        <div>
          <span className="published-context__eyebrow">Live version</span>
          <h2 id="currently-published-title">Currently published</h2>
        </div>
        <span className="published-context__readonly">Read only</span>
      </header>
      <p className="published-context__note">
        {workingInsight
          ? 'This version remains public while the replacement moves through review.'
          : 'This is the version currently visible in the public app.'}
      </p>
      <div className="published-context__body">
        <article>
          <h3>Published Arabic insight</h3>
          {insight.bodyAr.trim() ? (
            <p className="published-context__arabic" dir="rtl" lang="ar">{insight.bodyAr}</p>
          ) : (
            <p className="published-context__empty">No published Arabic insight is available.</p>
          )}
        </article>
        <article>
          <h3>Published English</h3>
          {insight.bodyEn.trim() ? (
            <p>{insight.bodyEn}</p>
          ) : (
            <p className="published-context__empty">No published English translation is available.</p>
          )}
        </article>
      </div>
      {workingInsight ? (
        <section aria-label="Working replacement" className="published-context__replacement">
          <header>
            <div>
              <span className="published-context__eyebrow">Replacement</span>
              <h3>Working insight</h3>
            </div>
            <span className="published-context__replacement-status">
              {workingInsight.status === 'submitted' ? 'Submitted for approval' : 'Draft in progress'}
            </span>
          </header>
          <div className="published-context__replacement-copy">
            <p dir="rtl" lang="ar">
              {workingInsight.bodyAr.trim() || 'لا توجد معاينة عربية بعد.'}
            </p>
            <p>{workingInsight.bodyEn.trim() || 'No English replacement preview yet.'}</p>
          </div>
        </section>
      ) : null}
    </section>
  )
}
