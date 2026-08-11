import { useTranslation } from '../i18n/useTranslation'
import type { TranslationKey } from '../i18n/translations'
import type { InsightStatus, ReviewState, TranslationStatus } from '../types'

const labelKeys: Record<ReviewState | InsightStatus | TranslationStatus, TranslationKey> = {
  needs_review: 'status.needs_review',
  changed: 'status.changed',
  draft: 'status.draft',
  submitted: 'status.submitted',
  published: 'status.published',
  archived: 'status.archived',
  not_started: 'status.not_started',
  generated: 'status.generated',
  reviewed: 'status.reviewed',
}

export function StatusMark({
  status,
}: {
  status: ReviewState | InsightStatus | TranslationStatus
}) {
  const { t } = useTranslation()
  return (
    <span className={`status-mark status-mark--${status}`}>
      <span aria-hidden="true" className="status-mark__dot" />
      {t(labelKeys[status])}
    </span>
  )
}
