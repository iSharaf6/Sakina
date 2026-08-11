import { ArrowSquareOut } from '@phosphor-icons/react/ArrowSquareOut'
import { BookOpen } from '@phosphor-icons/react/BookOpen'
import { CaretLeft } from '@phosphor-icons/react/CaretLeft'
import { CaretRight } from '@phosphor-icons/react/CaretRight'
import { Trash } from '@phosphor-icons/react/Trash'
import { useEffect, useState } from 'react'
import { useTranslation } from '../i18n/useTranslation'
import { LocalizedUIError, localizedErrorMessage } from '../i18n/localizedError'
import type { AppRole, GuidanceItem, Insight, InsightStatus, ReferenceMaterial } from '../types'
import { CommandButton } from './CommandButton'
import { PublishedInsightContext } from './PublishedInsightContext'
import { ReferenceDialog } from './ReferenceDialog'
import { SourceContext } from './SourceContext'
import { StatusMark } from './StatusMark'

interface InsightEditorProps {
  item: GuidanceItem
  role: AppRole
  onBack: () => void
  onOpenWorking: (status: 'draft' | 'submitted') => void
  onSave: (itemId: string, insight: Insight, status: InsightStatus) => Promise<Insight>
  onGenerate: (itemId: string, insight: Insight) => Promise<Insight>
  onReviewEnglish: (itemId: string, insight: Insight) => Promise<Insight>
  onStatus: (itemId: string, insight: Insight, status: 'published' | 'archived') => Promise<void>
  onNotify: (message: string, tone?: 'success' | 'error') => void
  viewingPublished: boolean
}

export function InsightEditor({
  item,
  role,
  onBack,
  onOpenWorking,
  onSave,
  onGenerate,
  onReviewEnglish,
  onStatus,
  onNotify,
  viewingPublished,
}: InsightEditorProps) {
  const { locale, t } = useTranslation()
  const initialInsight = viewingPublished && item.publishedInsight ? item.publishedInsight : item.insight
  const [insight, setInsight] = useState<Insight>(initialInsight)
  const [savedArabic, setSavedArabic] = useState(initialInsight.bodyAr)
  const [previewLanguage, setPreviewLanguage] = useState<'ar' | 'en'>('ar')
  const [referenceOpen, setReferenceOpen] = useState(false)
  const [busy, setBusy] = useState<'save' | 'generate' | 'review' | 'submit' | 'publish' | 'archive' | null>(null)

  useEffect(() => {
    const nextInsight = viewingPublished && item.publishedInsight ? item.publishedInsight : item.insight
    setInsight(nextInsight)
    setSavedArabic(nextInsight.bodyAr)
  }, [item.id, item.insight, item.publishedInsight, viewingPublished])

  const update = <Key extends keyof Insight>(key: Key, value: Insight[Key]) => {
    setInsight((current) => ({ ...current, [key]: value }))
  }

  const run = async (action: typeof busy, operation: () => Promise<void>) => {
    setBusy(action)
    try {
      await operation()
    } catch (error) {
      onNotify(localizedErrorMessage(error, locale, t), 'error')
    } finally {
      setBusy(null)
    }
  }

  const save = async (status: InsightStatus = 'draft') => {
    const saved = await onSave(item.id, insight, status)
    setInsight(saved)
    setSavedArabic(saved.bodyAr)
    return saved
  }

  const saveDraft = () =>
    run('save', async () => {
      if (role !== 'scholar') throw new LocalizedUIError(t('errors.scholarDraftOnly'))
      await save('draft')
      onNotify(t('notice.draftSaved'))
    })

  const createReplacement = () =>
    run('save', async () => {
      if (role !== 'scholar' || insight.status !== 'published') {
        throw new LocalizedUIError(t('errors.replacementPublishedOnly'))
      }
      const saved = await save('draft')
      onNotify(t('notice.replacementCreated'))
      onOpenWorking(saved.status === 'submitted' ? 'submitted' : 'draft')
    })

  const submit = () =>
    run('submit', async () => {
      if (!insight.bodyAr.trim()) throw new LocalizedUIError(t('errors.addArabicSubmit'))
      if (insight.translationStatus !== 'reviewed' || !insight.bodyEn.trim()) {
        throw new LocalizedUIError(t('errors.reviewEnglishSubmit'))
      }
      await save('submitted')
      onNotify(t('notice.submitted'))
    })

  const publish = () =>
    run('publish', async () => {
      if (!insight.bodyAr.trim()) throw new LocalizedUIError(t('errors.addArabicPublish'))
      if (insight.translationStatus !== 'reviewed') {
        throw new LocalizedUIError(t('errors.reviewEnglishPublish'))
      }
      if (insight.status !== 'submitted') {
        throw new LocalizedUIError(t('errors.submittedPublishOnly'))
      }
      await onStatus(item.id, insight, 'published')
      onNotify(t('notice.published'))
    })

  const archive = () =>
    run('archive', async () => {
      if (!insight.id) throw new LocalizedUIError(t('errors.saveBeforeArchive'))
      await onStatus(item.id, insight, 'archived')
      onNotify(t('notice.archived'))
    })

  const generate = () =>
    run('generate', async () => {
      const translated = await onGenerate(item.id, insight)
      setInsight(translated)
      setPreviewLanguage('en')
      onNotify(t('notice.englishGenerated'))
    })

  const reviewEnglish = () =>
    run('review', async () => {
      const reviewed = await onReviewEnglish(item.id, insight)
      setInsight(reviewed)
      onNotify(t('notice.englishReviewed'))
    })

  const addReference = (reference: ReferenceMaterial) => {
    update('references', [...insight.references, reference])
  }

  const removeReference = (id: string) => {
    update(
      'references',
      insight.references.filter((reference) => reference.id !== id),
    )
  }

  const arabicIsSaved = Boolean(
    insight.id && insight.status === 'draft' && insight.bodyAr.trim() && insight.bodyAr === savedArabic,
  )
  const contentIsReadOnly = role === 'admin' || viewingPublished || insight.status === 'published'
  const BackIcon = locale === 'ar' ? CaretRight : CaretLeft

  return (
    <main className="editor-page">
      <header className="editor-command-bar">
        <div>
          <h1>{t('editor.title')}</h1>
          <button className="editor-breadcrumb" onClick={onBack} type="button">
            <BackIcon aria-hidden="true" size={19} weight="bold" />
            <span>{t('editor.queueBreadcrumb')}</span>
            <span aria-hidden="true">/</span>
            <span>{item.verseKey}</span>
          </button>
        </div>
        <div className="editor-command-bar__actions">
          <div className={`editor-role-state editor-role-state--${role}`}>
            <span>{role === 'admin' ? t('nav.administrator') : t('nav.scholar')}</span>
            <span aria-hidden="true" className="editor-role-state__divider" />
            <StatusMark status={insight.status} />
          </div>
          {role === 'scholar' && (viewingPublished || insight.status === 'published') ? (
            item.workingInsight ? (
              <CommandButton
                disabled={busy !== null}
                onClick={() => onOpenWorking(item.workingInsight?.status === 'submitted' ? 'submitted' : 'draft')}
                variant="secondary"
              >
                {item.workingInsight.status === 'submitted'
                  ? t('editor.viewSubmittedReplacement')
                  : t('editor.openReplacementDraft')}
              </CommandButton>
            ) : (
              <CommandButton disabled={busy !== null} onClick={createReplacement} variant="primary">
                {busy === 'save' ? t('editor.creating') : t('editor.createReplacementDraft')}
              </CommandButton>
            )
          ) : role === 'scholar' ? (
            <>
              <CommandButton disabled={busy !== null} onClick={saveDraft}>
                {busy === 'save'
                  ? t('editor.saving')
                  : insight.status === 'published'
                    ? t('editor.createReplacementDraft')
                    : t('editor.saveDraft')}
              </CommandButton>
              <CommandButton
                disabled={
                  busy !== null ||
                  !insight.bodyAr.trim() ||
                  !insight.bodyEn.trim() ||
                  insight.translationStatus !== 'reviewed' ||
                  insight.status !== 'draft'
                }
                onClick={submit}
                variant="primary"
              >
                {busy === 'submit'
                  ? t('editor.submitting')
                  : insight.status === 'submitted'
                    ? t('editor.submitted')
                    : t('editor.submitPublication')}
              </CommandButton>
            </>
          ) : insight.status === 'published' ? (
            <CommandButton disabled={busy !== null || !insight.id} onClick={archive} variant="quiet">
              {busy === 'archive' ? t('editor.archiving') : t('editor.archiveLive')}
            </CommandButton>
          ) : insight.status === 'submitted' ? (
            <>
              <CommandButton disabled={busy !== null || !insight.id} onClick={archive} variant="quiet">
                {busy === 'archive' ? t('editor.archiving') : t('editor.archiveSubmission')}
              </CommandButton>
              <CommandButton
                disabled={
                  busy !== null ||
                  insight.status !== 'submitted' ||
                  insight.translationStatus !== 'reviewed'
                }
                onClick={publish}
                variant="primary"
              >
                {busy === 'publish' ? t('editor.publishing') : t('editor.publish')}
              </CommandButton>
            </>
          ) : (
            <span className="editor-readonly-label">{t('editor.noSubmission')}</span>
          )}
        </div>
      </header>

      <div className="editor-layout">
        <SourceContext item={item} variant="editor" />
        <div className="insight-editor">
          {item.publishedInsight ? (
            <PublishedInsightContext
              insight={item.publishedInsight}
              workingInsight={item.workingInsight}
            />
          ) : null}
          <section className="editor-section editor-section--arabic">
            <div className="section-heading">
              <h2>{t('editor.arabicTitle')}</h2>
              <p>
                {contentIsReadOnly ? t('editor.readOnlyContent') : t('editor.arabicDescription')}
              </p>
            </div>
            <label>
              <span className="sr-only">{t('editor.arabicTitle')}</span>
              <textarea
                className="arabic-editor-field"
                dir="rtl"
                lang="ar"
                name="body-ar"
                onChange={(event) => update('bodyAr', event.target.value)}
                placeholder={t('editor.arabicPlaceholder')}
                readOnly={contentIsReadOnly}
                rows={7}
                value={insight.bodyAr}
              />
            </label>
          </section>

          <section className="editor-section editor-section--references">
            <div className="section-heading section-heading--inline">
              <div>
                <h2>{t('editor.referencesTitle')}</h2>
                <p>
                  {contentIsReadOnly
                    ? t('editor.referencesReadOnly')
                    : t('editor.referencesDescription')}
                </p>
              </div>
              {role === 'scholar' && !contentIsReadOnly ? (
                <CommandButton onClick={() => setReferenceOpen(true)}>
                  {t('editor.addReference')}
                </CommandButton>
              ) : null}
            </div>
            {insight.references.length ? (
              <ul className="reference-list">
                {insight.references.map((reference) => (
                  <li key={reference.id}>
                    <span>{reference.label}</span>
                    <span className="reference-list__actions">
                      {reference.url ? (
                        <a href={reference.url} rel="noreferrer" target="_blank">
                          <span className="sr-only">
                            {t('editor.openReference', { label: reference.label })}
                          </span>
                          <ArrowSquareOut aria-hidden="true" size={17} weight="bold" />
                        </a>
                      ) : null}
                      {role === 'scholar' && !contentIsReadOnly ? (
                        <button onClick={() => removeReference(reference.id)} type="button">
                          <span className="sr-only">
                            {t('editor.removeReference', { label: reference.label })}
                          </span>
                          <Trash aria-hidden="true" size={17} weight="bold" />
                        </button>
                      ) : null}
                    </span>
                  </li>
                ))}
              </ul>
            ) : null}
          </section>

          <section className="editor-section editor-section--translation">
            <div className="section-heading section-heading--inline">
              <div>
                <h2>{t('editor.englishTitle')}</h2>
                <StatusMark status={insight.translationStatus} />
              </div>
              {role === 'scholar' && !contentIsReadOnly ? (
                <CommandButton
                  disabled={busy !== null || !arabicIsSaved}
                  onClick={generate}
                >
                  {busy === 'generate' ? t('editor.generating') : t('editor.generateDraft')}
                </CommandButton>
              ) : null}
            </div>
            <p className="translation-note">
              {t('editor.translationNote')}
            </p>
            {insight.bodyEn ? (
              <div className="translation-review">
                <label>
                  <span className="sr-only">
                    {contentIsReadOnly
                      ? t('editor.englishReadOnlyLabel')
                      : t('editor.englishEditableLabel')}
                  </span>
                  <textarea
                    dir="ltr"
                    lang="en"
                    name="body-en"
                    onChange={(event) => {
                      setInsight((current) => ({
                        ...current,
                        bodyEn: event.target.value,
                        translationStatus:
                          current.translationStatus === 'reviewed' ? 'generated' : current.translationStatus,
                      }))
                    }}
                    readOnly={contentIsReadOnly}
                    rows={4}
                    value={insight.bodyEn}
                  />
                </label>
                {role === 'scholar' && !contentIsReadOnly ? (
                  <CommandButton
                    disabled={busy !== null || !insight.bodyEn.trim() || insight.status !== 'draft'}
                    onClick={reviewEnglish}
                    variant={insight.translationStatus === 'reviewed' ? 'primary' : 'secondary'}
                  >
                    {busy === 'review'
                      ? t('editor.savingReview')
                      : insight.translationStatus === 'reviewed'
                        ? t('editor.englishReviewed')
                        : t('editor.markEnglishReviewed')}
                  </CommandButton>
                ) : null}
              </div>
            ) : null}
          </section>

          <section className="editor-section editor-section--preview">
            <div className="section-heading section-heading--inline">
              <h2>{t('editor.preview')}</h2>
              <div aria-label={t('editor.previewLanguage')} className="preview-tabs" role="group">
                <button
                  aria-pressed={previewLanguage === 'ar'}
                  onClick={() => setPreviewLanguage('ar')}
                  type="button"
                >
                  {t('editor.arabic')}
                </button>
                <button
                  aria-pressed={previewLanguage === 'en'}
                  onClick={() => setPreviewLanguage('en')}
                  type="button"
                >
                  {t('editor.english')}
                </button>
              </div>
            </div>
            <div className="insight-preview" key={previewLanguage}>
              {previewLanguage === 'ar' && insight.bodyAr.trim() ? (
                <p className="insight-preview__arabic" dir="rtl" lang="ar">
                  {insight.bodyAr}
                </p>
              ) : previewLanguage === 'en' && insight.bodyEn.trim() ? (
                <p dir="ltr" lang="en">{insight.bodyEn}</p>
              ) : (
                <div className="preview-empty">
                  <BookOpen aria-hidden="true" size={34} weight="regular" />
                  <strong>
                    {previewLanguage === 'ar'
                      ? t('editor.previewArabicEmpty')
                      : t('editor.previewEnglishEmpty')}
                  </strong>
                  <span>{t('editor.previewEmptyDescription')}</span>
                </div>
              )}
            </div>
          </section>
        </div>
      </div>
      <ReferenceDialog onAdd={addReference} onClose={() => setReferenceOpen(false)} open={referenceOpen} />
    </main>
  )
}
