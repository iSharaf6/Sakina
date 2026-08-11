import { useEffect, useState } from 'react'
import { InsightEditor } from './components/InsightEditor'
import { LoginView } from './components/LoginView'
import { ProfileEditor } from './components/ProfileEditor'
import { ReviewQueue } from './components/ReviewQueue'
import { Sidebar } from './components/Sidebar'
import { Toast, type ToastState } from './components/Toast'
import { useAuth } from './hooks/useAuth'
import { useDashboardData } from './hooks/useDashboardData'
import { isDevelopmentDemo } from './lib/supabase'
import type { AuthUser, NavDestination } from './types'

function LoadingScreen() {
  return (
    <main className="state-page" aria-busy="true">
      <span className="state-page__loader" />
      <p>Opening the review workspace…</p>
    </main>
  )
}

function Dashboard({ user, onSignOut }: { user: AuthUser; onSignOut: () => void }) {
  const initialReviewId = new URLSearchParams(window.location.search).get('review') ?? ''
  const data = useDashboardData(user.id, user.role)
  const [destination, setDestination] = useState<NavDestination>('queue')
  const [selectedId, setSelectedId] = useState(initialReviewId)
  const [editing, setEditing] = useState(Boolean(initialReviewId))
  const [toast, setToast] = useState<ToastState | null>(null)

  useEffect(() => {
    if (!selectedId && data.items[0]) setSelectedId(data.items[0].id)
  }, [data.items, selectedId])

  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(null), 3200)
    return () => window.clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    const restoreFromURL = () => {
      const reviewId = new URLSearchParams(window.location.search).get('review') ?? ''
      setSelectedId(reviewId)
      setEditing(Boolean(reviewId))
    }
    window.addEventListener('popstate', restoreFromURL)
    return () => window.removeEventListener('popstate', restoreFromURL)
  }, [])

  const notify = (message: string, tone: ToastState['tone'] = 'success') => {
    setToast({ message, tone })
  }

  const chooseDestination = (next: NavDestination) => {
    setDestination(next)
    setEditing(false)
    const url = new URL(window.location.href)
    url.searchParams.delete('review')
    window.history.pushState({}, '', url)
  }

  const openEditor = (id: string) => {
    setSelectedId(id)
    setEditing(true)
    const url = new URL(window.location.href)
    url.searchParams.set('review', id)
    window.history.pushState({}, '', url)
  }

  const closeEditor = () => {
    setEditing(false)
    const url = new URL(window.location.href)
    url.searchParams.delete('review')
    window.history.pushState({}, '', url)
  }

  if (data.loading) return <LoadingScreen />
  if (data.error) {
    return (
      <main className="state-page state-page--error">
        <h1>Unable to open the review workspace</h1>
        <p>{data.error}</p>
        <button onClick={() => window.location.reload()} type="button">Try again</button>
      </main>
    )
  }

  const selected = data.items.find((item) => item.id === selectedId) ?? data.items[0]

  return (
    <div className="app-frame">
      <Sidebar
        demo={isDevelopmentDemo}
        destination={destination}
        onDestinationChange={chooseDestination}
        onSignOut={onSignOut}
        profile={data.profile}
        role={user.role}
      />
      <div className="app-content">
        {destination === 'profile' ? (
          <ProfileEditor
            onNotify={notify}
            onSave={data.saveProfile}
            onSetVisibility={data.setProfileVisibility}
            profile={data.profile}
            role={user.role}
          />
        ) : editing && selected ? (
          <InsightEditor
            item={selected}
            onBack={closeEditor}
            onGenerate={data.generateEnglishDraft}
            onNotify={notify}
            onOpenWorking={(status) => setDestination(status === 'submitted' ? 'submitted' : 'drafts')}
            onReviewEnglish={data.reviewEnglishDraft}
            onSave={data.saveInsight}
            onStatus={data.setStatus}
            role={user.role}
            viewingPublished={destination === 'published'}
          />
        ) : (
          <ReviewQueue
            destination={destination}
            items={data.items}
            onOpen={openEditor}
            onSelect={setSelectedId}
            selectedId={selected?.id ?? ''}
          />
        )}
      </div>
      <Toast toast={toast} />
    </div>
  )
}

export default function App() {
  const auth = useAuth()

  if (auth.status === 'loading') return <LoadingScreen />
  if (auth.status !== 'ready' || !auth.user) {
    return (
      <LoginView
        onSendMagicLink={auth.sendMagicLink}
        onVerifyCode={auth.verifyCode}
        status={auth.status === 'ready' ? 'signed_out' : auth.status}
      />
    )
  }

  return <Dashboard onSignOut={() => void auth.signOut()} user={auth.user} />
}
