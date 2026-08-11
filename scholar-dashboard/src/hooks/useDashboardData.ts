import { useCallback, useEffect, useState } from 'react'
import { freshDemoItems, freshDemoProfile } from '../data/demoData'
import { isDevelopmentDemo } from '../lib/supabase'
import { useTranslation } from '../i18n/useTranslation'
import { LocalizedUIError, localizedErrorMessage } from '../i18n/localizedError'
import {
  generateEnglishDraft as requestEnglishDraft,
  loadGuidanceItems,
  loadScholarProfile,
  reviewEnglishDraft as persistReviewedEnglish,
  saveInsight as persistInsight,
  saveScholarProfile as persistProfile,
  setScholarProfileVisibility as persistProfileVisibility,
  updateInsightStatus,
} from '../services/dashboardRepository'
import type {
  AppRole,
  GuidanceItem,
  Insight,
  InsightStatus,
  ScholarProfile,
} from '../types'

interface DataState {
  loading: boolean
  error: string
  items: GuidanceItem[]
  profile: ScholarProfile
}

export function useDashboardData(userId: string, role: AppRole) {
  const { locale, t } = useTranslation()
  const [state, setState] = useState<DataState>(() => ({
    loading: true,
    error: '',
    items: [],
    profile: freshDemoProfile(),
  }))

  useEffect(() => {
    let current = true
    const load = async () => {
      try {
        const [items, profile] = isDevelopmentDemo
          ? [freshDemoItems(role), freshDemoProfile()]
          : await Promise.all([loadGuidanceItems(userId, role), loadScholarProfile(userId, role)])
        if (current) setState({ loading: false, error: '', items, profile })
      } catch (error) {
        if (current) {
          setState((previous) => ({
            ...previous,
            loading: false,
            error: localizedErrorMessage(error, locale, t),
          }))
        }
      }
    }
    void load()
    return () => {
      current = false
    }
  }, [locale, role, t, userId])

  const replaceInsight = useCallback((itemId: string, insight: Insight) => {
    setState((previous) => ({
      ...previous,
      items: previous.items.map((item) => {
        if (item.id !== itemId) return item
        if (insight.status === 'draft' || insight.status === 'submitted') {
          return { ...item, workingInsight: insight, insight }
        }
        if (insight.status === 'published') {
          const workingInsight = item.workingInsight?.id === insight.id ? null : item.workingInsight
          return {
            ...item,
            workingInsight,
            publishedInsight: insight,
            insight: workingInsight ?? insight,
          }
        }
        const workingInsight = item.workingInsight?.id === insight.id ? null : item.workingInsight
        const publishedInsight = item.publishedInsight?.id === insight.id ? null : item.publishedInsight
        return {
          ...item,
          workingInsight,
          publishedInsight,
          insight: workingInsight ?? publishedInsight ?? insight,
        }
      }),
    }))
  }, [])

  const saveInsight = useCallback(
    async (itemId: string, insight: Insight, nextStatus: InsightStatus): Promise<Insight> => {
      const saved: Insight = isDevelopmentDemo
        ? {
            ...insight,
            id:
              !insight.id || insight.status === 'published' || insight.status === 'archived'
                ? `demo-draft-${itemId}`
                : insight.id,
            status: nextStatus,
            translationStatus:
              insight.status === 'published' || insight.status === 'archived'
                ? insight.bodyEn.trim() ? 'generated' : 'not_started'
                : insight.translationStatus,
            revisionNumber:
              insight.status === 'published' || insight.status === 'archived'
                ? 1
                : insight.revisionNumber + 1,
            updatedAt: new Date('2026-08-11T00:00:00.000Z').toISOString(),
          }
        : await persistInsight(itemId, insight, nextStatus)
      replaceInsight(itemId, saved)
      return saved
    },
    [replaceInsight],
  )

  const generateEnglishDraft = useCallback(
    async (itemId: string, insight: Insight): Promise<Insight> => {
      if (!insight.id) throw new LocalizedUIError(t('errors.saveBeforeTranslate'))
      const translation = isDevelopmentDemo
        ? {
            bodyEn: 'Development preview only. Configure the protected translation Edge Function to generate a real draft.',
            revisionNumber: insight.revisionNumber,
          }
        : await requestEnglishDraft(insight.id)
      const translated: Insight = {
        ...insight,
        bodyEn: translation.bodyEn,
        translationStatus: 'generated',
        revisionNumber: translation.revisionNumber,
      }
      replaceInsight(itemId, translated)
      return translated
    },
    [replaceInsight, t],
  )

  const reviewEnglishDraft = useCallback(
    async (itemId: string, insight: Insight): Promise<Insight> => {
      if (!insight.bodyEn.trim()) throw new LocalizedUIError(t('errors.emptyReviewedEnglish'))
      const reviewed = isDevelopmentDemo
        ? { ...insight, translationStatus: 'reviewed' as const }
        : await persistReviewedEnglish(insight)
      replaceInsight(itemId, reviewed)
      return reviewed
    },
    [replaceInsight, t],
  )

  const setStatus = useCallback(
    async (itemId: string, insight: Insight, status: 'published' | 'archived') => {
      if (!insight.id) throw new LocalizedUIError(t('errors.noSavedInsight'))
      const updated = isDevelopmentDemo
        ? { ...insight, status }
        : await updateInsightStatus(insight.id, status, insight.scholarId)
      replaceInsight(itemId, updated)
    },
    [replaceInsight, t],
  )

  const saveProfile = useCallback(async (profile: ScholarProfile) => {
    if (!isDevelopmentDemo) await persistProfile(profile, role)
    const savedProfile = role === 'scholar'
      ? { ...profile, verified: false, isPublic: false }
      : profile
    setState((previous) => ({ ...previous, profile: savedProfile }))
  }, [role])

  const setProfileVisibility = useCallback(async (verified: boolean, isPublic: boolean) => {
    if (role !== 'admin') throw new LocalizedUIError(t('errors.adminVisibilityOnly'))
    if (!isDevelopmentDemo) {
      await persistProfileVisibility(state.profile.userId, verified, isPublic)
    }
    setState((previous) => ({
      ...previous,
      profile: { ...previous.profile, verified, isPublic },
    }))
  }, [role, state.profile.userId, t])

  return {
    ...state,
    role,
    replaceInsight,
    saveInsight,
    generateEnglishDraft,
    reviewEnglishDraft,
    setStatus,
    saveProfile,
    setProfileVisibility,
  }
}
