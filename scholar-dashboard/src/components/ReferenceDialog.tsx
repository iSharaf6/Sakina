import { useEffect, useRef, useState } from 'react'
import { useTranslation } from '../i18n/useTranslation'
import type { ReferenceMaterial } from '../types'
import { CommandButton } from './CommandButton'

interface ReferenceDialogProps {
  open: boolean
  onClose: () => void
  onAdd: (reference: ReferenceMaterial) => void
}

export function ReferenceDialog({ open, onClose, onAdd }: ReferenceDialogProps) {
  const { t } = useTranslation()
  const dialogRef = useRef<HTMLDialogElement>(null)
  const labelInputRef = useRef<HTMLInputElement>(null)
  const returnFocusRef = useRef<HTMLElement | null>(null)
  const [label, setLabel] = useState('')
  const [url, setUrl] = useState('')
  const [urlError, setUrlError] = useState(false)

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    if (open && !dialog.open) {
      returnFocusRef.current = document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null
      dialog.showModal()
      window.requestAnimationFrame(() => {
        if (dialog.open) labelInputRef.current?.focus()
      })
    }
    if (!open && dialog.open) dialog.close()
  }, [open])

  const submit = () => {
    const trimmedLabel = label.trim()
    if (!trimmedLabel) return
    const trimmedUrl = url.trim()
    if (trimmedUrl) {
      try {
        const parsed = new URL(trimmedUrl)
        if (parsed.protocol !== 'https:' || !parsed.hostname) throw new Error('HTTPS required')
      } catch {
        setUrlError(true)
        return
      }
    }
    onAdd({ id: crypto.randomUUID(), label: trimmedLabel, url: trimmedUrl || undefined })
    setLabel('')
    setUrl('')
    setUrlError(false)
    onClose()
  }

  return (
    <dialog
      aria-describedby="reference-dialog-description"
      aria-labelledby="reference-dialog-title"
      className="reference-dialog"
      onCancel={(event) => {
        event.preventDefault()
        onClose()
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose()
      }}
      onClose={() => {
        onClose()
        window.requestAnimationFrame(() => returnFocusRef.current?.focus())
      }}
      onKeyDown={(event) => {
        if (event.key === 'Escape') {
          event.preventDefault()
          onClose()
          return
        }

        if (event.key !== 'Tab') return
        const dialog = dialogRef.current
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
      ref={dialogRef}
      tabIndex={-1}
    >
      <form
        method="dialog"
        onSubmit={(event) => {
          event.preventDefault()
          submit()
        }}
      >
        <h2 id="reference-dialog-title">{t('reference.title')}</h2>
        <p id="reference-dialog-description">{t('reference.description')}</p>
        <label className="form-field" htmlFor="reference-label">
          <span>{t('reference.label')}</span>
          <input
            autoFocus
            id="reference-label"
            maxLength={300}
            name="reference-label"
            onChange={(event) => setLabel(event.target.value)}
            placeholder={t('reference.placeholder')}
            required
            ref={labelInputRef}
            value={label}
          />
        </label>
        <label className="form-field" htmlFor="reference-url">
          <span>{t('reference.url')} <small>{t('reference.optional')}</small></span>
          <input
            aria-describedby={urlError ? 'reference-url-error' : undefined}
            aria-invalid={urlError}
            dir="ltr"
            id="reference-url"
            inputMode="url"
            maxLength={2048}
            name="reference-url"
            onChange={(event) => {
              setUrl(event.target.value)
              setUrlError(false)
            }}
            placeholder="https://"
            type="url"
            value={url}
          />
          {urlError ? (
            <small id="reference-url-error" role="alert">{t('reference.urlError')}</small>
          ) : null}
        </label>
        <div className="dialog-actions">
          <CommandButton onClick={onClose} variant="quiet">
            {t('reference.cancel')}
          </CommandButton>
          <CommandButton disabled={!label.trim()} type="submit" variant="primary">
            {t('reference.add')}
          </CommandButton>
        </div>
      </form>
    </dialog>
  )
}
