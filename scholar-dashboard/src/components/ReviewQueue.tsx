import { BookOpen } from '@phosphor-icons/react/BookOpen'
import { CaretLeft } from '@phosphor-icons/react/CaretLeft'
import { CaretRight } from '@phosphor-icons/react/CaretRight'
import { MagnifyingGlass } from '@phosphor-icons/react/MagnifyingGlass'
import { X } from '@phosphor-icons/react/X'
import { useDeferredValue, useEffect, useMemo, useRef, useState } from 'react'
import { useTranslation } from '../i18n/useTranslation'
import type { GuidanceItem, NavDestination, ReviewState } from '../types'
import { CommandButton } from './CommandButton'
import { SourceContext } from './SourceContext'
import { StatusMark } from './StatusMark'

type QueueFilter = ReviewState | 'all'

const normalized = (value: string) =>
  value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLocaleLowerCase()
    .trim()

const pageSize = 7

function paginationTokens(currentPage: number, pageCount: number): Array<number | 'ellipsis'> {
  if (pageCount <= 5) return Array.from({ length: pageCount }, (_, index) => index + 1)
  if (currentPage <= 3) return [1, 2, 3, 'ellipsis', pageCount]
  if (currentPage >= pageCount - 2) {
    return [1, 'ellipsis', pageCount - 2, pageCount - 1, pageCount]
  }
  return [1, 'ellipsis', currentPage - 1, currentPage, currentPage + 1, 'ellipsis', pageCount]
}

interface ReviewQueueProps {
  items: GuidanceItem[]
  destination: NavDestination
  selectedId: string
  onSelect: (id: string) => void
  onOpen: (id: string) => void
}

export function ReviewQueue({ items, destination, selectedId, onSelect, onOpen }: ReviewQueueProps) {
  const { locale, t } = useTranslation()
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<QueueFilter>('needs_review')
  const [contextOpen, setContextOpen] = useState(false)
  const [page, setPage] = useState(1)
  const contextDialogRef = useRef<HTMLDialogElement>(null)
  const contextTriggerRef = useRef<HTMLButtonElement>(null)
  const deferredQuery = useDeferredValue(query)

  const visibleItems = useMemo(() => {
    const search = normalized(deferredQuery)
    return items.filter((item) => {
      const destinationMatch =
        destination === 'queue' ||
        (destination === 'drafts' && item.workingInsight?.status === 'draft') ||
        (destination === 'submitted' && item.workingInsight?.status === 'submitted') ||
        (destination === 'published' && Boolean(item.publishedInsight))
      const filterMatch =
        destination !== 'queue' ||
        filter === 'all' ||
        (filter === 'needs_review' && item.needsReview !== false) ||
        (filter === 'changed' && item.needsReview !== false && item.reviewState === 'changed')
      const searchMatch =
        !search ||
        normalized(
          `${item.titleEn} ${item.titleAr} ${item.verseKey} ${item.surahNameEn}`,
        ).includes(search)
      return destinationMatch && filterMatch && searchMatch
    })
  }, [deferredQuery, destination, filter, items])

  const pageCount = Math.max(1, Math.ceil(visibleItems.length / pageSize))
  const currentPage = Math.min(page, pageCount)
  const pageItems = useMemo(
    () => visibleItems.slice((currentPage - 1) * pageSize, currentPage * pageSize),
    [currentPage, visibleItems],
  )
  const pageTokens = paginationTokens(currentPage, pageCount)

  useEffect(() => {
    setPage(1)
  }, [deferredQuery, destination, filter])

  useEffect(() => {
    setPage((current) => Math.min(current, pageCount))
  }, [pageCount])

  useEffect(() => {
    const firstPageItem = pageItems[0]
    if (firstPageItem && !pageItems.some((item) => item.id === selectedId)) {
      onSelect(firstPageItem.id)
    }
  }, [onSelect, pageItems, selectedId])

  useEffect(() => {
    const dialog = contextDialogRef.current
    if (!dialog) return

    if (contextOpen && !dialog.open) {
      dialog.showModal()
    } else if (!contextOpen && dialog.open) {
      dialog.close()
    }
  }, [contextOpen])

  useEffect(() => {
    const compactLayout = window.matchMedia('(max-width: 1280px)')
    const closeWhenDocked = () => {
      if (!compactLayout.matches) setContextOpen(false)
    }
    compactLayout.addEventListener('change', closeWhenDocked)
    return () => compactLayout.removeEventListener('change', closeWhenDocked)
  }, [])

  const selected = pageItems.find((item) => item.id === selectedId) ?? pageItems[0] ?? visibleItems[0] ?? items[0]
  const filterLabels: Array<{ value: QueueFilter; label: string }> = [
    { value: 'needs_review', label: t('queue.filterNeedsReview') },
    { value: 'changed', label: t('queue.filterChanged') },
    { value: 'all', label: t('queue.filterAll') },
  ]
  const title =
    destination === 'queue'
      ? t('nav.queue')
      : destination === 'drafts'
        ? t('nav.drafts')
        : destination === 'submitted'
          ? t('nav.submitted')
          : t('nav.published')
  const PreviousIcon = locale === 'ar' ? CaretRight : CaretLeft
  const NextIcon = locale === 'ar' ? CaretLeft : CaretRight

  return (
    <div className="queue-layout">
      <main className="queue-workspace">
        <h1>{title}</h1>
        <div className="queue-toolbar">
          <label className="search-field">
            <span className="sr-only">{t('queue.searchLabel')}</span>
            <MagnifyingGlass aria-hidden="true" size={20} weight="regular" />
            <input
              name="queue-search"
              onChange={(event) => setQuery(event.target.value)}
              placeholder={t('queue.searchPlaceholder')}
              type="search"
              value={query}
            />
          </label>
          {destination === 'queue' ? (
            <div aria-label={t('queue.filterLabel')} className="review-filter" role="group">
              {filterLabels.map((option) => (
                <button
                  aria-pressed={filter === option.value}
                  className={filter === option.value ? 'review-filter__button--selected' : ''}
                  key={option.value}
                  onClick={() => setFilter(option.value)}
                  type="button"
                >
                  {option.label}
                </button>
              ))}
            </div>
          ) : null}
          <button
            aria-controls="queue-source-context-dialog"
            aria-expanded={contextOpen}
            className="context-toggle"
            onClick={() => setContextOpen(true)}
            ref={contextTriggerRef}
            type="button"
          >
            <BookOpen aria-hidden="true" size={18} weight="regular" />
            {t('queue.sourceContext')}
          </button>
        </div>

        <div className="review-table" role="table" aria-label={title}>
          <div className="review-table__header" role="row">
            <span role="columnheader">{t('queue.situation')}</span>
            <span role="columnheader">{t('queue.ayah')}</span>
            <span role="columnheader">{t('queue.orientation')}</span>
            <span role="columnheader">{t('queue.status')}</span>
            <span role="columnheader">{t('queue.action')}</span>
          </div>
          <div className="review-table__body" role="rowgroup">
            {pageItems.length ? (
              pageItems.map((item) => {
                const isSelected = selected?.id === item.id
                const workflowStatus = destination === 'published'
                  ? item.publishedInsight?.status ?? 'published'
                  : item.workingInsight?.status ?? item.insight.status
                return (
                  <div
                    aria-selected={isSelected}
                    className={`review-row ${isSelected ? 'review-row--selected' : ''}`}
                    key={item.id}
                    onClick={() => onSelect(item.id)}
                    onKeyDown={(event) => {
                      if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault()
                        onSelect(item.id)
                      }
                    }}
                    role="row"
                    tabIndex={0}
                  >
                    <span className="review-row__situation" role="cell">
                      {locale === 'ar' ? item.titleAr || item.titleEn : item.titleEn || item.titleAr}
                    </span>
                    <span role="cell">
                      {t('queue.surahVerse', {
                        surah: locale === 'ar' ? item.surahNameAr || item.surahNameEn : item.surahNameEn || item.surahNameAr,
                        verse: item.verseKey,
                      })}
                    </span>
                    <span role="cell">{t('queue.existingOrientation')}</span>
                    <span role="cell">
                      <StatusMark status={destination === 'queue' ? item.reviewState : workflowStatus} />
                    </span>
                    <span role="cell">
                      <CommandButton
                        onClick={(event) => {
                          event.stopPropagation()
                          onOpen(item.id)
                        }}
                        variant={isSelected ? 'primary' : 'secondary'}
                      >
                        {t('queue.openReview')}
                      </CommandButton>
                    </span>
                  </div>
                )
              })
            ) : (
              <div className="queue-empty" role="row">
                <p role="cell">{t('queue.empty')}</p>
              </div>
            )}
          </div>
        </div>

        <nav
          aria-label={t('queue.pagesLabel', { current: currentPage, total: pageCount })}
          className="pagination"
        >
          <button
            aria-label={t('queue.previousPage')}
            disabled={currentPage === 1}
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            type="button"
          >
            <PreviousIcon aria-hidden="true" size={16} weight="bold" />
          </button>
          {pageTokens.map((token, index) => token === 'ellipsis' ? (
            <span aria-hidden="true" key={`ellipsis-${index}`}>…</span>
          ) : (
            <button
              aria-current={currentPage === token ? 'page' : undefined}
              aria-label={t('queue.page', { page: token })}
              className={currentPage === token ? 'pagination__current' : undefined}
              key={token}
              onClick={() => setPage(token)}
              type="button"
            >
              {token}
            </button>
          ))}
          <button
            aria-label={t('queue.nextPage')}
            disabled={currentPage === pageCount}
            onClick={() => setPage((current) => Math.min(pageCount, current + 1))}
            type="button"
          >
            <NextIcon aria-hidden="true" size={16} weight="bold" />
          </button>
        </nav>
      </main>
      {selected ? (
        <>
          <aside aria-label={t('queue.sourceContext')} className="queue-context-rail">
            <SourceContext item={selected} />
          </aside>
          <dialog
            aria-label={t('queue.sourceContext')}
            className="queue-context-dialog"
            id="queue-source-context-dialog"
            onCancel={(event) => {
              event.preventDefault()
              setContextOpen(false)
            }}
            onClick={(event) => {
              if (event.target === event.currentTarget) setContextOpen(false)
            }}
            onKeyDown={(event) => {
              if (event.key === 'Escape') {
                event.preventDefault()
                setContextOpen(false)
                return
              }

              if (event.key !== 'Tab') return
              const dialog = contextDialogRef.current
              const focusable = dialog
                ? Array.from(
                    dialog.querySelectorAll<HTMLElement>(
                      'a[href], button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])',
                    ),
                  ).filter((element) => element.getClientRects().length > 0)
                : []
              const first = focusable[0]
              const last = focusable[focusable.length - 1]

              if (!first || !last) {
                event.preventDefault()
                dialog?.focus()
              } else if (
                document.activeElement === dialog ||
                (event.shiftKey && document.activeElement === first) ||
                (!event.shiftKey && document.activeElement === last)
              ) {
                event.preventDefault()
                ;(event.shiftKey ? last : first).focus()
              }
            }}
            onClose={() => {
              setContextOpen(false)
              contextTriggerRef.current?.focus()
            }}
            ref={contextDialogRef}
            tabIndex={-1}
          >
            <div className="queue-context-dialog__surface">
              <button
                aria-label={t('queue.closeContext')}
                autoFocus
                className="context-drawer-close"
                onClick={() => setContextOpen(false)}
                type="button"
              >
                <X aria-hidden="true" size={20} weight="bold" />
              </button>
              <SourceContext item={selected} />
            </div>
          </dialog>
        </>
      ) : null}
    </div>
  )
}
