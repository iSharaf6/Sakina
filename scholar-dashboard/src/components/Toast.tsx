import { CheckCircle2, CircleAlert } from 'lucide-react'

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
            <CheckCircle2 aria-hidden="true" size={18} />
          ) : (
            <CircleAlert aria-hidden="true" size={18} />
          )}
          {toast.message}
        </div>
      ) : null}
    </div>
  )
}
