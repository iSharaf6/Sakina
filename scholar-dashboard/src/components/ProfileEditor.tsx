import { ArrowSquareOut } from '@phosphor-icons/react/ArrowSquareOut'
import { useEffect, useState } from 'react'
import scholarPortrait from '../assets/contributor-placeholder.png'
import { useTranslation } from '../i18n/useTranslation'
import { localizedErrorMessage } from '../i18n/localizedError'
import type { TranslationKey } from '../i18n/translations'
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

const socialFields: Array<{
  key: keyof ScholarProfile
  labelKey: TranslationKey
  placeholder?: string
}> = [
  { key: 'facebookUrl', labelKey: 'profile.facebook', placeholder: 'https://facebook.com/…' },
  { key: 'instagramUrl', labelKey: 'profile.instagram', placeholder: 'https://instagram.com/…' },
  { key: 'youtubeUrl', labelKey: 'profile.youtube' },
  { key: 'tiktokUrl', labelKey: 'profile.tiktok' },
  { key: 'websiteUrl', labelKey: 'profile.website' },
]

export function ProfileEditor({ profile, role, onSave, onSetVisibility, onNotify }: ProfileEditorProps) {
  const { locale, t } = useTranslation()
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
          ? t('notice.profileScholarSaved')
          : t('notice.profileAdminSaved'),
      )
    } catch (error) {
      onNotify(localizedErrorMessage(error, locale, t, 'errors.profileSave'), 'error')
    } finally {
      setSaving(false)
    }
  }

  const updateVisibility = async (makePublic: boolean) => {
    setVisibilityBusy(true)
    try {
      if (makePublic) await onSave(draft)
      await onSetVisibility(makePublic ? true : profile.verified, makePublic)
      onNotify(makePublic ? t('notice.profilePublished') : t('notice.profilePrivate'))
    } catch (error) {
      onNotify(localizedErrorMessage(error, locale, t, 'errors.profileVisibility'), 'error')
    } finally {
      setVisibilityBusy(false)
    }
  }

  const reviewState = profile.isPublic && profile.verified
    ? t('profile.publicVerified')
    : profile.verified
      ? t('profile.privateVerified')
      : t('profile.awaitingReview')
  const avatarReadyForPublication = isDevelopmentDemo || avatarLoadState === 'loaded'
  const avatarStatus = isDevelopmentDemo && !remoteAvatarURL
    ? t('profile.avatarBundled')
    : avatarLoadState === 'loaded'
      ? t('profile.avatarLoaded')
      : avatarLoadState === 'loading'
        ? t('profile.avatarLoading')
        : avatarLoadState === 'failed'
          ? t('profile.avatarFailed')
          : t('profile.avatarMissing')
  const displayName = locale === 'ar'
    ? draft.displayNameAr || draft.displayNameEn || t('profile.nameFallback')
    : draft.displayNameEn || draft.displayNameAr || t('profile.nameFallback')

  return (
    <main className="profile-page">
      <header className="profile-header">
        <div>
          <h1>{t('profile.title')}</h1>
          <p>{t('profile.description')}</p>
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
                {visibilityBusy ? t('profile.updating') : t('profile.makePrivate')}
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
                {visibilityBusy ? t('profile.publishing') : t('profile.verifyPublish')}
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
            {saving ? t('profile.saving') : t('profile.save')}
          </CommandButton>
        </div>
      </header>

      <div className="profile-layout">
        <aside className="profile-identity">
          <img
            alt={t('profile.portraitAlt', { name: displayName })}
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
          <h2>{displayName}</h2>
          {locale === 'en' && draft.displayNameAr ? (
            <p dir="rtl" lang="ar">{draft.displayNameAr}</p>
          ) : locale === 'ar' && draft.displayNameEn ? (
            <p dir="ltr" lang="en">{draft.displayNameEn}</p>
          ) : (
            <p className="empty-profile-value">{t('profile.arabicNameMissing')}</p>
          )}
          <div className="profile-links">
            {socialFields.map(({ key, labelKey }) => {
              const value = draft[key]
              return typeof value === 'string' && value ? (
                <a href={value} key={key} rel="noreferrer" target="_blank">
                  {t(labelKey)}
                  <ArrowSquareOut aria-hidden="true" size={15} weight="bold" />
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
            <strong>
              {role === 'scholar' ? t('profile.scholarReviewTitle') : t('profile.adminEditTitle')}
            </strong>
            <p>
              {role === 'scholar'
                ? t('profile.scholarReviewDescription')
                : t('profile.adminEditDescription')}
            </p>
            {role === 'scholar' ? (
              <label>
                <input
                  checked={reviewResetConfirmed}
                  name="profile-review-confirmation"
                  onChange={(event) => setReviewResetConfirmed(event.target.checked)}
                  type="checkbox"
                />
                {t('profile.reviewConfirmation')}
              </label>
            ) : null}
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>{t('profile.englishName')}</span>
              <input
                dir="ltr"
                lang="en"
                name="display-name-en"
                onChange={(event) => update('displayNameEn', event.target.value)}
                required
                value={draft.displayNameEn}
              />
            </label>
            <label className="form-field">
              <span>{t('profile.arabicName')}</span>
              <input
                dir="rtl"
                lang="ar"
                name="display-name-ar"
                onChange={(event) => update('displayNameAr', event.target.value)}
                placeholder={t('profile.notProvided')}
                value={draft.displayNameAr}
              />
            </label>
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>{t('profile.englishTitle')}</span>
              <input
                dir="ltr"
                lang="en"
                name="title-en"
                onChange={(event) => update('titleEn', event.target.value)}
                placeholder={t('profile.notProvided')}
                value={draft.titleEn}
              />
            </label>
            <label className="form-field">
              <span>{t('profile.arabicTitle')}</span>
              <input
                dir="rtl"
                lang="ar"
                name="title-ar"
                onChange={(event) => update('titleAr', event.target.value)}
                placeholder={t('profile.notProvided')}
                value={draft.titleAr}
              />
            </label>
          </div>
          <div className="profile-form__pair">
            <label className="form-field">
              <span>{t('profile.englishBio')}</span>
              <textarea
                dir="ltr"
                lang="en"
                name="bio-en"
                onChange={(event) => update('bioEn', event.target.value)}
                placeholder={t('profile.notProvided')}
                rows={5}
                value={draft.bioEn}
              />
            </label>
            <label className="form-field">
              <span>{t('profile.arabicBio')}</span>
              <textarea
                dir="rtl"
                lang="ar"
                name="bio-ar"
                onChange={(event) => update('bioAr', event.target.value)}
                placeholder={t('profile.notProvided')}
                rows={5}
                value={draft.bioAr}
              />
            </label>
          </div>

          <fieldset className="social-fieldset">
            <legend>{t('profile.approvedLinks')}</legend>
            {socialFields.map(({ key, labelKey, placeholder }) => (
              <label className="form-field" key={key}>
                <span>{t(labelKey)}</span>
                <input
                  dir="ltr"
                  inputMode="url"
                  name={String(key)}
                  onChange={(event) => update(key, event.target.value)}
                  placeholder={placeholder ?? t('profile.notProvided')}
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
