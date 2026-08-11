import { CheckCircle } from '@phosphor-icons/react/CheckCircle'
import { WarningCircle } from '@phosphor-icons/react/WarningCircle'

export interface ToastState {
  message: string
  tone: 'success' | 'error'
}

export function Toast({ toast }: { toast: ToastState | null }) {
  return (
    <div aria-atomic="true" aria-live="polite" className="toast-region">
      {toast ? (
        <div className={`toast toast--${toast.tone}`} role={toast.tone === 'error' ? 'alert' : 'status'}>
          {toast.tone === 'success' ? (
            <CheckCircle aria-hidden="true" size={18} weight="bold" />
          ) : (
            <WarningCircle aria-hidden="true" size={18} weight="bold" />
          )}
          {toast.message}
        </div>
      ) : null}
    </div>
  )
}
