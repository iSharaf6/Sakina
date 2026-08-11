import {
  CheckCircle2,
  FileText,
  ListFilter,
  LogOut,
  Menu,
  Send,
  UserRound,
  X,
} from 'lucide-react'
import { useState } from 'react'
import scholarPortrait from '../assets/dr-abdullah-abu-hatab.png'
import { publicScholarAvatarURL } from '../lib/supabase'
import type { AppRole, NavDestination, ScholarProfile } from '../types'
import { BrandMark } from './BrandMark'

const destinations: Array<{
  id: NavDestination
  label: string
  icon: typeof ListFilter
}> = [
  { id: 'queue', label: 'Review queue', icon: ListFilter },
  { id: 'drafts', label: 'Drafts', icon: FileText },
  { id: 'submitted', label: 'Submitted', icon: Send },
  { id: 'published', label: 'Published', icon: CheckCircle2 },
  { id: 'profile', label: 'Scholar profile', icon: UserRound },
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
  const [mobileOpen, setMobileOpen] = useState(false)
  const [accountOpen, setAccountOpen] = useState(false)
  const accountPortrait = publicScholarAvatarURL(profile.avatarPath) ?? scholarPortrait

  const chooseDestination = (next: NavDestination) => {
    onDestinationChange(next)
    setMobileOpen(false)
  }

  return (
    <>
      <header className="mobile-header">
        <span className="mobile-brand">
          <BrandMark size={30} />
          Yaqeen Review
        </span>
        <button
          aria-expanded={mobileOpen}
          aria-label={mobileOpen ? 'Close navigation' : 'Open navigation'}
          className="mobile-menu-button"
          onClick={() => setMobileOpen((open) => !open)}
          type="button"
        >
          {mobileOpen ? <X /> : <Menu />}
        </button>
      </header>
      {mobileOpen ? (
        <button
          aria-label="Close navigation"
          className="navigation-scrim"
          onClick={() => setMobileOpen(false)}
          type="button"
        />
      ) : null}
      <aside className={`sidebar ${mobileOpen ? 'sidebar--mobile-open' : ''}`}>
        <div className="sidebar__brand">
          <BrandMark />
          <span>Yaqeen Review</span>
        </div>

        <nav aria-label="Scholar review" className="sidebar__nav">
          {destinations.map(({ id, label, icon: Icon }) => (
            <button
              aria-label={label}
              aria-current={destination === id ? 'page' : undefined}
              className={`sidebar__nav-item ${destination === id ? 'sidebar__nav-item--selected' : ''}`}
              key={id}
              onClick={() => chooseDestination(id)}
              type="button"
            >
              <Icon aria-hidden="true" strokeWidth={1.7} />
              <span>{label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar__footer">
          {demo ? <p className="demo-label">Development demo · local data only</p> : null}
          <button
            aria-expanded={accountOpen}
            className="account-summary"
            onClick={() => setAccountOpen((open) => !open)}
            title={`${profile.displayNameEn || 'Scholar'} account`}
            type="button"
          >
            <span className="account-summary__avatar-frame">
              <img alt="" className="account-summary__avatar" src={accountPortrait} />
            </span>
            <span className="account-summary__copy">
              <strong>{profile.displayNameEn || 'Scholar account'}</strong>
              <span>{role === 'admin' ? 'Administrator' : 'Scholar'}</span>
            </span>
          </button>
          {accountOpen ? (
            <button className="sign-out-button" onClick={onSignOut} type="button">
              <LogOut aria-hidden="true" size={17} />
              Sign out
            </button>
          ) : null}
        </div>
      </aside>
    </>
  )
}
