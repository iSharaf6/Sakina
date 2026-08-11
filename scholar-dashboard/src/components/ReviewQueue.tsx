import { BookOpen, ChevronLeft, ChevronRight, Search, X } from 'lucide-react'
import { useDeferredValue, useEffect, useMemo, useState } from 'react'
import type { GuidanceItem, NavDestination, ReviewState } from '../types'
import { CommandButton } from './CommandButton'
import { SourceContext } from './SourceContext'
import { StatusMark } from './StatusMark'

type QueueFilter = ReviewState | 'all'

const filterLabels: Array<{ value: QueueFilter; label: string }> = [
  { value: 'needs_review', label: 'Needs review' },
  { value: 'changed', label: 'Changed' },
  { value: 'all', label: 'All' },
]

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
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<QueueFilter>('needs_review')
  const [contextOpen, setContextOpen] = useState(false)
  const [page, setPage] = useState(1)
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

  const selected = pageItems.find((item) => item.id === selectedId) ?? pageItems[0] ?? visibleItems[0] ?? items[0]
  const title =
    destination === 'queue'
      ? 'Review queue'
      : destination === 'drafts'
        ? 'Drafts'
        : destination === 'submitted'
          ? 'Submitted'
          : 'Published'

  return (
    <div className="queue-layout">
      <main className="queue-workspace">
        <h1>{title}</h1>
        <div className="queue-toolbar">
          <label className="search-field">
            <span className="sr-only">Search situations or ayat</span>
            <Search aria-hidden="true" size={20} strokeWidth={1.8} />
            <input
              name="queue-search"
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search situations or ayat"
              type="search"
              value={query}
            />
          </label>
          {destination === 'queue' ? (
            <div aria-label="Review status" className="review-filter" role="group">
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
            aria-expanded={contextOpen}
            className="context-toggle"
            onClick={() => setContextOpen(true)}
            type="button"
          >
            <BookOpen aria-hidden="true" size={18} />
            Source context
          </button>
        </div>

        <div className="review-table" role="table" aria-label={title}>
          <div className="review-table__header" role="row">
            <span role="columnheader">Situation</span>
            <span role="columnheader">Ayah</span>
            <span role="columnheader">Orientation</span>
            <span role="columnheader">Status</span>
            <span role="columnheader">Action</span>
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
                      {item.titleEn}
                    </span>
                    <span role="cell">{`Surah ${item.surahNameEn} · ${item.verseKey}`}</span>
                    <span role="cell">Existing app orientation</span>
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
                        Open review
                      </CommandButton>
                    </span>
                  </div>
                )
              })
            ) : (
              <div className="queue-empty" role="row">
                <p role="cell">No review items match this view.</p>
              </div>
            )}
          </div>
        </div>

        <nav aria-label={`Queue pages, page ${currentPage} of ${pageCount}`} className="pagination">
          <button
            aria-label="Previous page"
            disabled={currentPage === 1}
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            type="button"
          >
            <ChevronLeft aria-hidden="true" size={16} />
          </button>
          {pageTokens.map((token, index) => token === 'ellipsis' ? (
            <span aria-hidden="true" key={`ellipsis-${index}`}>…</span>
          ) : (
            <button
              aria-current={currentPage === token ? 'page' : undefined}
              aria-label={`Page ${token}`}
              className={currentPage === token ? 'pagination__current' : undefined}
              key={token}
              onClick={() => setPage(token)}
              type="button"
            >
              {token}
            </button>
          ))}
          <button
            aria-label="Next page"
            disabled={currentPage === pageCount}
            onClick={() => setPage((current) => Math.min(pageCount, current + 1))}
            type="button"
          >
            <ChevronRight aria-hidden="true" size={16} />
          </button>
        </nav>
      </main>
      {selected ? (
        <div className={`queue-context-drawer ${contextOpen ? 'queue-context-drawer--open' : ''}`}>
          <button
            aria-label="Close source context"
            className="context-drawer-close"
            onClick={() => setContextOpen(false)}
            type="button"
          >
            <X aria-hidden="true" size={20} />
          </button>
          <SourceContext item={selected} />
        </div>
      ) : null}
    </div>
  )
}
