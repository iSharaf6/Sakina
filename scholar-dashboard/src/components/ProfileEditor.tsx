import { ExternalLink } from 'lucide-react'
import { useEffect, useState } from 'react'
import scholarPortrait from '../assets/dr-abdullah-abu-hatab.png'
import { isDevelopmentDemo, publicScholarAvatarURL } from '../lib/supabase'
import type { AppRole, ScholarProfile } from '../types'
import { CommandButton } from './CommandButton'

interface ProfileEditorProps {
  profile: ScholarProfile
  role: AppRole
  onSave: (profile: ScholarProfile) => Promise<void>
  onSetVisibility: (verified: boolean, isPublic: boolean) => Promise<void>
  onNotify: (message: string, tone?: 'success' | 'error') => void
}

const socialFields: Array<{ key: keyof ScholarProfile; label: string; placeholder: string }> = [
  { key: 'facebookUrl', label: 'Facebook', placeholder: 'https://facebook.com/…' },
  { key: 'instagramUrl', label: 'Instagram', placeholder: 'https://instagram.com/…' },
  { key: 'youtubeUrl', label: 'YouTube', placeholder: 'Not provided' },
  { key: 'tiktokUrl', label: 'TikTok', placeholder: 'Not provided' },
  { key: 'websiteUrl', label: 'Website', placeholder: 'Not provided' },
]

export function ProfileEditor({ profile, role, onSave, onSetVisibility, onNotify }: ProfileEditorProps) {
  const [draft, setDraft] = useState(profile)
  const [saving, setSaving] = useState(false)
  const [visibilityBusy, setVisibilityBusy] = useState(false)
  const [reviewResetConfirmed, setReviewResetConfirmed] = useState(false)
  const remoteAvatarURL = publicScholarAvatarURL(draft.avatarPath)
  const [avatarLoadState, setAvatarLoadState] = useState<
    'bundled' | 'loading' | 'loaded' | 'failed'
  >(remoteAvatarURL ? 'loading' : 'bundled')

  useEffect(() => {
    setDraft(profile)
    setReviewResetConfirmed(false)
  }, [profile])

  useEffect(() => {
    setAvatarLoadState(remoteAvatarURL ? 'loading' : 'bundled')
  }, [remoteAvatarURL])

  const update = (key: keyof ScholarProfile, value: string) => {
    setDraft((current) => ({ ...current, [key]: value }))
  }

  const save = async () => {
    setSaving(true)
    try {
      await onSave(draft)
      onNotify(
        role === 'scholar'
          ? 'Profile saved privately and sent for administrator review'
          : 'Scholar profile saved; its review status was preserved',
      )
    } catch (error) {
      onNotify(error instanceof Error ? error.message : 'Unable to save the profile.', 'error')
    } finally {
      setSaving(false)
    }
  }

  const updateVisibility = async (makePublic: boolean) => {
    setVisibilityBusy(true)
    try {
      if (makePublic) await onSave(draft)
      await onSetVisibility(makePublic ? true : profile.verified, makePublic)
      onNotify(makePublic ? 'Scholar profile verified and published' : 'Scholar profile made private')
    } catch (error) {
      onNotify(error instanceof Error ? error.message : 'Unable to change profile visibility.', 'error')
    } finally {
      setVisibilityBusy(false)
    }
  }

  const reviewState = profile.isPublic && profile.verified
    ? 'Public and verified'
    : profile.verified
      ? 'Private · verified'
      : 'Private · awaiting administrator review'
  const avatarReadyForPublication = isDevelopmentDemo || avatarLoadState === 'loaded'
  const avatarStatus = isDevelopmentDemo && !remoteAvatarURL
    ? 'Bundled supplied portrait · development preview'
    : avatarLoadState === 'loaded'
      ? 'Exact public Storage portrait loaded for review'
      : avatarLoadState === 'loading'
        ? 'Loading the exact public Storage portrait…'
        : avatarLoadState === 'failed'
          ? 'Public portrait could not be loaded · verification is blocked'
          : 'No public avatar path is set · verification is blocked'

  return (
    <main className="profile-page">
      <header className="profile-header">
        <div>
          <h1>Scholar profile</h1>
          <p>Only publish identity, qualifications and biography that the scholar has approved.</p>
          <span className={`profile-review-state ${profile.verified && profile.isPublic ? 'profile-review-state--public' : ''}`}>
            {reviewState}
          </span>
        </div>
        <div className="profile-header__actions">
          {role === 'admin' ? (
            profile.isPublic ? (
              <CommandButton
                disabled={saving || visibilityBusy}
                onClick={() => void updateVisibility(false)}
                variant="quiet"
              >
                {visibilityBusy ? 'Updating…' : 'Make private'}
              </CommandButton>
            ) : (
              <CommandButton
                disabled={
                  saving ||
                  visibilityBusy ||
                  !draft.displayNameEn.trim() ||
                  !avatarReadyForPublication
                }
                onClick={() => void updateVisibility(true)}
                variant="primary"
              >
                {visibilityBusy ? 'Publishing…' : 'Verify & publish'}
              </CommandButton>
            )
          ) : null}
          <CommandButton
            disabled={
              saving ||
              visibilityBusy ||
              !draft.displayNameEn.trim() ||
              (role === 'scholar' && !reviewResetConfirmed)
            }
            onClick={save}
            variant={role === 'admin' ? 'secondary' : 'primary'}
          >
            {saving ? 'Saving…' : 'Save profile'}
          </CommandButton>
        </div>
      </header>

      <div className="profile-layout">
        <aside className="profile-identity">
          <img
            alt={`${draft.displayNameEn || 'Scholar'} public profile portrait`}
            key={remoteAvatarURL ?? 'bundled-portrait'}
            onError={() => {
              if (remoteAvatarURL) setAvatarLoadState('failed')
            }}
            onLoad={() => setAvatarLoadState(remoteAvatarURL ? 'loaded' : 'bundled')}
            src={remoteAvatarURL ?? scholarPortrait}
          />
          <p
            aria-live="polite"
            className={`profile-avatar-status${avatarLoadState === 'failed' ? ' profile-avatar-status--error' : ''}`}
          >
            {avatarStatus}
          </p>
          <h2>{draft.displayNameEn || 'Scholar name'}</h2>
          {draft.displayNameAr ? (
            <p dir="rtl" lang="ar">{draft.displayNameAr}</p>
          ) : (
            <p className="empty-profile-value">Arabic display name not provided</p>
          )}
          <div className="profile-links">
            {socialFields.map(({ key, label }) => {
              const value = draft[key]
              return typeof value === 'string' && value ? (
                <a href={value} key={key} rel="noreferrer" target="_blank">
                  {label}
                  <ExternalLink aria-hidden="true" size={15} />
                </a>
              ) : null
            })}
          </div>
        </aside>

        <form
          className="profile-form"
          onSubmit={(event) => {
            event.preventDefault()
            void save()
          }}
        >
          <div className="profile-review-notice">
            <strong>{role === 'scholar' ? 'Profile review required after changes' : 'Administrator edit'}</strong>
            <p>
              {role === 'scholar'
                ? 'Saving any change makes this profile private and clears verification. An administrator must review and republish it before the public app shows the update.'
                : 'Administrator text and link edits preserve the current review state. A changed portrait path becomes private automatically. Verify & publish is enabled only after the exact public portrait loads and every field has been checked.'}
            </p>
            {role === 'scholar' ? (
              <label>
                <input
                  checked={reviewResetConfirmed}
                  name="profile-review-confirmation"
                  onChange={(event) => setReviewResetConfirmed(event.target.checked)}
                  type="checkbox"
                />
                I understand this profile will become private until reviewed.
              </label>
            ) : null}
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>English display name</span>
              <input
                name="display-name-en"
                onChange={(event) => update('displayNameEn', event.target.value)}
                required
                value={draft.displayNameEn}
              />
            </label>
            <label className="form-field">
              <span>Arabic display name</span>
              <input
                dir="rtl"
                lang="ar"
                name="display-name-ar"
                onChange={(event) => update('displayNameAr', event.target.value)}
                placeholder="Not provided"
                value={draft.displayNameAr}
              />
            </label>
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>English title or qualification</span>
              <input
                name="title-en"
                onChange={(event) => update('titleEn', event.target.value)}
                placeholder="Not provided"
                value={draft.titleEn}
              />
            </label>
            <label className="form-field">
              <span>Arabic title or qualification</span>
              <input
                dir="rtl"
                lang="ar"
                name="title-ar"
                onChange={(event) => update('titleAr', event.target.value)}
                placeholder="غير متوفر"
                value={draft.titleAr}
              />
            </label>
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>English biography</span>
              <textarea
                name="bio-en"
                onChange={(event) => update('bioEn', event.target.value)}
                placeholder="Not provided"
                rows={5}
                value={draft.bioEn}
              />
            </label>
            <label className="form-field">
              <span>Arabic biography</span>
              <textarea
                dir="rtl"
                lang="ar"
                name="bio-ar"
                onChange={(event) => update('bioAr', event.target.value)}
                placeholder="غير متوفر"
                rows={5}
                value={draft.bioAr}
              />
            </label>
          </div>

          <fieldset className="social-fieldset">
            <legend>Approved links</legend>
            {socialFields.map(({ key, label, placeholder }) => (
              <label className="form-field" key={key}>
                <span>{label}</span>
                <input
                  inputMode="url"
                  name={String(key)}
                  onChange={(event) => update(key, event.target.value)}
                  placeholder={placeholder}
                  type="url"
                  value={String(draft[key])}
                />
              </label>
            ))}
          </fieldset>
        </form>
      </div>
    </main>
  )
}
