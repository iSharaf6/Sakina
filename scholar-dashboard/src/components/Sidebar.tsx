import { CheckCircle } from '@phosphor-icons/react/CheckCircle'
import { DeviceMobile } from '@phosphor-icons/react/DeviceMobile'
import { FileText } from '@phosphor-icons/react/FileText'
import { FunnelSimple } from '@phosphor-icons/react/FunnelSimple'
import { List } from '@phosphor-icons/react/List'
import { PaperPlaneTilt } from '@phosphor-icons/react/PaperPlaneTilt'
import { SignOut } from '@phosphor-icons/react/SignOut'
import { UserCircle } from '@phosphor-icons/react/UserCircle'
import { X } from '@phosphor-icons/react/X'
import type { Icon } from '@phosphor-icons/react/lib'
import { useEffect, useRef, useState } from 'react'
import scholarPortrait from '../assets/dr-abdullah-abu-hatab.png'
import { useTranslation } from '../i18n/useTranslation'
import { publicScholarAvatarURL } from '../lib/supabase'
import type { AppRole, NavDestination, ScholarProfile } from '../types'
import { BrandMark } from './BrandMark'
import { LanguageSwitcher } from './LanguageSwitcher'

const destinations: Array<{
  id: NavDestination
  icon: Icon
}> = [
  { id: 'queue', icon: FunnelSimple },
  { id: 'drafts', icon: FileText },
  { id: 'submitted', icon: PaperPlaneTilt },
  { id: 'published', icon: CheckCircle },
  { id: 'profile', icon: UserCircle },
]

interface SidebarProps {
  destination: NavDestination
  onDestinationChange: (destination: NavDestination) => void
  profile: ScholarProfile
  role: AppRole
  demo: boolean
  onSignOut: () => void
}

export function Sidebar({
  destination,
  onDestinationChange,
  profile,
  role,
  demo,
  onSignOut,
}: SidebarProps) {
  const { locale, t } = useTranslation()
  const [mobileOpen, setMobileOpen] = useState(false)
  const [mobileViewport, setMobileViewport] = useState(() =>
    typeof window !== 'undefined' && window.matchMedia('(max-width: 820px)').matches,
  )
  const [accountOpen, setAccountOpen] = useState(false)
  const menuButtonRef = useRef<HTMLButtonElement>(null)
  const sidebarRef = useRef<HTMLElement>(null)
  const accountPortrait = publicScholarAvatarURL(profile.avatarPath) ?? scholarPortrait
  const accountName = locale === 'ar'
    ? profile.displayNameAr || profile.displayNameEn || t('nav.scholarFallback')
    : profile.displayNameEn || profile.displayNameAr || t('nav.scholarFallback')
  const destinationLabels: Record<NavDestination, string> = {
    queue: t('nav.queue'),
    drafts: t('nav.drafts'),
    submitted: t('nav.submitted'),
    published: t('nav.published'),
    profile: t('nav.profile'),
  }

  useEffect(() => {
    const media = window.matchMedia('(max-width: 820px)')
    const updateViewport = () => {
      setMobileViewport(media.matches)
      if (!media.matches) setMobileOpen(false)
    }
    updateViewport()
    media.addEventListener('change', updateViewport)
    return () => media.removeEventListener('change', updateViewport)
  }, [])

  const closeMobileNavigation = () => {
    setMobileOpen(false)
    window.requestAnimationFrame(() => menuButtonRef.current?.focus())
  }

  useEffect(() => {
    if (!mobileViewport || !mobileOpen) return

    const sidebar = sidebarRef.current
    const appContent = document.querySelector<HTMLElement>('.app-content')
    appContent?.setAttribute('aria-hidden', 'true')
    if (appContent) appContent.inert = true
    const getFocusable = () => sidebar
      ? Array.from(
          sidebar.querySelectorAll<HTMLElement>(
            'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])',
          ),
        ).filter((element) => element.getClientRects().length > 0)
      : []

    window.requestAnimationFrame(() => getFocusable()[0]?.focus())

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault()
        closeMobileNavigation()
        return
      }

      const focusable = getFocusable()
      if (event.key !== 'Tab' || !focusable.length) return
      const first = focusable[0]
      const last = focusable[focusable.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      appContent?.removeAttribute('aria-hidden')
      if (appContent) appContent.inert = false
    }
  }, [mobileOpen, mobileViewport])

  const chooseDestination = (next: NavDestination) => {
    onDestinationChange(next)
    if (mobileOpen) closeMobileNavigation()
  }

  return (
    <>
      <header className="mobile-header">
        <span className="mobile-brand">
          <BrandMark size={30} />
          {t('app.brand')}
        </span>
        <span className="mobile-header__actions">
          <a
            aria-hidden={mobileOpen ? true : undefined}
            aria-label={t('app.openAppHint')}
            className="mobile-open-app"
            href="haneen://"
            inert={mobileOpen ? true : undefined}
            tabIndex={mobileOpen ? -1 : undefined}
            title={t('app.openAppHint')}
          >
            <DeviceMobile aria-hidden="true" size={20} weight="bold" />
          </a>
          <button
            aria-controls="mobile-navigation"
            aria-expanded={mobileOpen}
            aria-label={mobileOpen ? t('nav.close') : t('nav.open')}
            className="mobile-menu-button"
            onClick={() => (mobileOpen ? closeMobileNavigation() : setMobileOpen(true))}
            ref={menuButtonRef}
            type="button"
          >
            {mobileOpen ? <X aria-hidden="true" /> : <List aria-hidden="true" />}
          </button>
        </span>
      </header>
      {mobileOpen ? (
        <button
          aria-label={t('nav.close')}
          className="navigation-scrim"
          onClick={closeMobileNavigation}
          type="button"
        />
      ) : null}
      <aside
        aria-hidden={mobileViewport && !mobileOpen ? true : undefined}
        className={`sidebar ${mobileOpen ? 'sidebar--mobile-open' : ''}`}
        id="mobile-navigation"
        inert={mobileViewport && !mobileOpen ? true : undefined}
        ref={sidebarRef}
      >
        <div className="sidebar__brand">
          <BrandMark />
          <span>{t('app.brand')}</span>
        </div>

        <nav aria-label={t('nav.review')} className="sidebar__nav">
          {destinations.map(({ id, icon: Icon }) => (
            <button
              aria-label={destinationLabels[id]}
              aria-current={destination === id ? 'page' : undefined}
              className={`sidebar__nav-item ${destination === id ? 'sidebar__nav-item--selected' : ''}`}
              key={id}
              onClick={() => chooseDestination(id)}
              type="button"
            >
              <Icon aria-hidden="true" weight={destination === id ? 'fill' : 'regular'} />
              <span>{destinationLabels[id]}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar__footer">
          <a
            aria-label={t('app.openAppHint')}
            className="open-app-link"
            href="haneen://"
            title={t('app.openAppHint')}
          >
            <span>{t('app.openApp')}</span>
            <DeviceMobile aria-hidden="true" size={18} weight="bold" />
          </a>
          <LanguageSwitcher compact />
          {demo ? <p className="demo-label">{t('nav.demo')}</p> : null}
          <button
            aria-expanded={accountOpen}
            className="account-summary"
            onClick={() => setAccountOpen((open) => !open)}
            title={t('nav.accountTitle', { name: accountName })}
            type="button"
          >
            <span className="account-summary__avatar-frame">
              <img alt="" className="account-summary__avatar" src={accountPortrait} />
            </span>
            <span className="account-summary__copy">
              <strong>{accountName || t('nav.scholarAccount')}</strong>
              <span>{role === 'admin' ? t('nav.administrator') : t('nav.scholar')}</span>
            </span>
          </button>
          {accountOpen ? (
            <button className="sign-out-button" onClick={onSignOut} type="button">
              <SignOut aria-hidden="true" size={17} weight="bold" />
              {t('nav.signOut')}
            </button>
          ) : null}
        </div>
      </aside>
      <nav
        aria-hidden={mobileOpen ? true : undefined}
        aria-label={t('nav.review')}
        className="mobile-tabbar"
        inert={mobileOpen ? true : undefined}
      >
        {destinations.map(({ id, icon: Icon }) => (
          <button
            aria-current={destination === id ? 'page' : undefined}
            aria-label={destinationLabels[id]}
            className={destination === id ? 'mobile-tabbar__item--selected' : undefined}
            key={id}
            onClick={() => chooseDestination(id)}
            type="button"
          >
            <Icon aria-hidden="true" size={22} weight={destination === id ? 'fill' : 'regular'} />
            <span className="sr-only">{destinationLabels[id]}</span>
          </button>
        ))}
      </nav>
    </>
  )
}
