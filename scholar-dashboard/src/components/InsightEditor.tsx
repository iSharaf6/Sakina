import { BookOpen, ChevronLeft, ExternalLink, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
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
      onNotify(error instanceof Error ? error.message : 'Something went wrong.', 'error')
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
      if (role !== 'scholar') throw new Error('Only the scholar can create or save a working draft.')
      await save('draft')
      onNotify('Draft saved')
    })

  const createReplacement = () =>
    run('save', async () => {
      if (role !== 'scholar' || insight.status !== 'published') {
        throw new Error('A replacement can only be created from a published insight.')
      }
      const saved = await save('draft')
      onNotify('Replacement draft created')
      onOpenWorking(saved.status === 'submitted' ? 'submitted' : 'draft')
    })

  const submit = () =>
    run('submit', async () => {
      if (!insight.bodyAr.trim()) throw new Error('Add the Arabic insight before submitting.')
      if (insight.translationStatus !== 'reviewed' || !insight.bodyEn.trim()) {
        throw new Error('Review the English translation before submitting.')
      }
      await save('submitted')
      onNotify('Submitted for publication')
    })

  const publish = () =>
    run('publish', async () => {
      if (!insight.bodyAr.trim()) throw new Error('Add the Arabic insight before publishing.')
      if (insight.translationStatus !== 'reviewed') {
        throw new Error('Review the English translation before publishing.')
      }
      if (insight.status !== 'submitted') {
        throw new Error('Only a submitted insight can be published.')
      }
      await onStatus(item.id, insight, 'published')
      onNotify('Insight published')
    })

  const archive = () =>
    run('archive', async () => {
      if (!insight.id) throw new Error('Save the insight before archiving it.')
      await onStatus(item.id, insight, 'archived')
      onNotify('Insight archived')
    })

  const generate = () =>
    run('generate', async () => {
      const translated = await onGenerate(item.id, insight)
      setInsight(translated)
      setPreviewLanguage('en')
      onNotify('English draft generated')
    })

  const reviewEnglish = () =>
    run('review', async () => {
      const reviewed = await onReviewEnglish(item.id, insight)
      setInsight(reviewed)
      onNotify('English translation marked as reviewed')
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

  return (
    <main className="editor-page">
      <header className="editor-command-bar">
        <div>
          <h1>Review insight</h1>
          <button className="editor-breadcrumb" onClick={onBack} type="button">
            <ChevronLeft aria-hidden="true" size={19} />
            <span>Review queue</span>
            <span aria-hidden="true">/</span>
            <span>{item.verseKey}</span>
          </button>
        </div>
        <div className="editor-command-bar__actions">
          {role === 'scholar' && (viewingPublished || insight.status === 'published') ? (
            item.workingInsight ? (
              <CommandButton
                disabled={busy !== null}
                onClick={() => onOpenWorking(item.workingInsight?.status === 'submitted' ? 'submitted' : 'draft')}
                variant="secondary"
              >
                {item.workingInsight.status === 'submitted' ? 'View submitted replacement' : 'Open replacement draft'}
              </CommandButton>
            ) : (
              <CommandButton disabled={busy !== null} onClick={createReplacement} variant="primary">
                {busy === 'save' ? 'Creating…' : 'Create replacement draft'}
              </CommandButton>
            )
          ) : role === 'scholar' ? (
            <>
              <CommandButton disabled={busy !== null} onClick={saveDraft}>
                {busy === 'save' ? 'Saving…' : insight.status === 'published' ? 'Create replacement draft' : 'Save draft'}
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
                  ? 'Submitting…'
                  : insight.status === 'submitted'
                    ? 'Submitted'
                    : 'Submit for publication'}
              </CommandButton>
            </>
          ) : insight.status === 'published' ? (
            <CommandButton disabled={busy !== null || !insight.id} onClick={archive} variant="quiet">
              {busy === 'archive' ? 'Archiving…' : 'Archive live version'}
            </CommandButton>
          ) : insight.status === 'submitted' ? (
            <>
              <CommandButton disabled={busy !== null || !insight.id} onClick={archive} variant="quiet">
                {busy === 'archive' ? 'Archiving…' : 'Archive submission'}
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
                {busy === 'publish' ? 'Publishing…' : 'Publish'}
              </CommandButton>
            </>
          ) : (
            <span className="editor-readonly-label">No submitted insight to review</span>
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
              <h2>Arabic insight</h2>
              <p>{contentIsReadOnly ? 'Read-only insight content' : 'Write the scholar’s original explanation in Arabic'}</p>
            </div>
            <label>
              <span className="sr-only">Arabic insight</span>
              <textarea
                className="arabic-editor-field"
                dir="rtl"
                lang="ar"
                name="body-ar"
                onChange={(event) => update('bodyAr', event.target.value)}
                placeholder="اكتب الشرح الأصلي باللغة العربية…"
                readOnly={contentIsReadOnly}
                rows={7}
                value={insight.bodyAr}
              />
            </label>
          </section>

          <section className="editor-section editor-section--references">
            <div className="section-heading section-heading--inline">
              <div>
                <h2>Sources and references</h2>
                <p>{contentIsReadOnly ? 'References supplied with this insight' : 'Add a book, tafsir, hadith reference, or URL'}</p>
              </div>
              {role === 'scholar' && !contentIsReadOnly ? (
                <CommandButton onClick={() => setReferenceOpen(true)}>Add reference</CommandButton>
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
                          <span className="sr-only">Open {reference.label}</span>
                          <ExternalLink aria-hidden="true" size={17} />
                        </a>
                      ) : null}
                      {role === 'scholar' && !contentIsReadOnly ? (
                        <button onClick={() => removeReference(reference.id)} type="button">
                          <span className="sr-only">Remove {reference.label}</span>
                          <Trash2 aria-hidden="true" size={17} />
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
                <h2>English translation</h2>
                <StatusMark status={insight.translationStatus} />
              </div>
              {role === 'scholar' && !contentIsReadOnly ? (
                <CommandButton
                  disabled={busy !== null || !arabicIsSaved}
                  onClick={generate}
                >
                  {busy === 'generate' ? 'Generating…' : 'Generate English draft'}
                </CommandButton>
              ) : null}
            </div>
            <p className="translation-note">
              The Arabic is saved first. Translation never changes Qur’anic text.
            </p>
            {insight.bodyEn ? (
              <div className="translation-review">
                <label>
                  <span className="sr-only">
                    {contentIsReadOnly ? 'English translation' : 'Editable English translation'}
                  </span>
                  <textarea
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
                      ? 'Saving review…'
                      : insight.translationStatus === 'reviewed'
                        ? 'English reviewed'
                        : 'Mark English reviewed'}
                  </CommandButton>
                ) : null}
              </div>
            ) : null}
          </section>

          <section className="editor-section editor-section--preview">
            <div className="section-heading section-heading--inline">
              <h2>Preview</h2>
              <div aria-label="Preview language" className="preview-tabs" role="group">
                <button
                  aria-pressed={previewLanguage === 'ar'}
                  onClick={() => setPreviewLanguage('ar')}
                  type="button"
                >
                  Arabic
                </button>
                <button
                  aria-pressed={previewLanguage === 'en'}
                  onClick={() => setPreviewLanguage('en')}
                  type="button"
                >
                  English
                </button>
              </div>
            </div>
            <div className="insight-preview" key={previewLanguage}>
              {previewLanguage === 'ar' && insight.bodyAr.trim() ? (
                <p className="insight-preview__arabic" dir="rtl" lang="ar">
                  {insight.bodyAr}
                </p>
              ) : previewLanguage === 'en' && insight.bodyEn.trim() ? (
                <p>{insight.bodyEn}</p>
              ) : (
                <div className="preview-empty">
                  <BookOpen aria-hidden="true" size={34} strokeWidth={1.4} />
                  <strong>
                    {previewLanguage === 'ar'
                      ? 'Add Arabic insight to preview'
                      : 'Generate English draft to preview'}
                  </strong>
                  <span>Your preview will appear here once content is entered.</span>
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
