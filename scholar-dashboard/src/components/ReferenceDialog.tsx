import { useEffect, useRef, useState } from 'react'
import type { ReferenceMaterial } from '../types'
import { CommandButton } from './CommandButton'

interface ReferenceDialogProps {
  open: boolean
  onClose: () => void
  onAdd: (reference: ReferenceMaterial) => void
}

export function ReferenceDialog({ open, onClose, onAdd }: ReferenceDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null)
  const [label, setLabel] = useState('')
  const [url, setUrl] = useState('')
  const [urlError, setUrlError] = useState('')

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    if (open && !dialog.open) dialog.showModal()
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
        setUrlError('Use a complete HTTPS URL, for example https://example.org/reference')
        return
      }
    }
    onAdd({ id: crypto.randomUUID(), label: trimmedLabel, url: trimmedUrl || undefined })
    setLabel('')
    setUrl('')
    setUrlError('')
    onClose()
  }

  return (
    <dialog
      aria-labelledby="reference-dialog-title"
      className="reference-dialog"
      onCancel={onClose}
      onClose={onClose}
      ref={dialogRef}
    >
      <form
        method="dialog"
        onSubmit={(event) => {
          event.preventDefault()
          submit()
        }}
      >
        <h2 id="reference-dialog-title">Add reference</h2>
        <p>Add a book, tafsir, hadith reference, or URL.</p>
        <label className="form-field">
          <span>Reference</span>
          <input
            autoFocus
            maxLength={300}
            name="reference-label"
            onChange={(event) => setLabel(event.target.value)}
            placeholder="Book, edition, volume and page"
            required
            value={label}
          />
        </label>
        <label className="form-field">
          <span>URL <small>Optional</small></span>
          <input
            aria-describedby={urlError ? 'reference-url-error' : undefined}
            aria-invalid={Boolean(urlError)}
            inputMode="url"
            maxLength={2048}
            name="reference-url"
            onChange={(event) => {
              setUrl(event.target.value)
              setUrlError('')
            }}
            placeholder="https://"
            type="url"
            value={url}
          />
          {urlError ? <small id="reference-url-error" role="alert">{urlError}</small> : null}
        </label>
        <div className="dialog-actions">
          <CommandButton onClick={onClose} variant="quiet">
            Cancel
          </CommandButton>
          <CommandButton disabled={!label.trim()} type="submit" variant="primary">
            Add reference
          </CommandButton>
        </div>
      </form>
    </dialog>
  )
}
