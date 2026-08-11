import type { InsightStatus, ReviewState, TranslationStatus } from '../types'

const labels: Record<ReviewState | InsightStatus | TranslationStatus, string> = {
  needs_review: 'Needs review',
  changed: 'Changed since review',
  draft: 'Draft',
  submitted: 'Submitted',
  published: 'Published',
  archived: 'Archived',
  not_started: 'Not generated',
  generated: 'Generated draft',
  reviewed: 'English reviewed',
}

export function StatusMark({
  status,
}: {
  status: ReviewState | InsightStatus | TranslationStatus
}) {
  return (
    <span className={`status-mark status-mark--${status}`}>
      <span aria-hidden="true" className="status-mark__dot" />
      {labels[status]}
    </span>
  )
}
