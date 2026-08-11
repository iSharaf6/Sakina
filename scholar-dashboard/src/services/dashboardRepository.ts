import { supabase, translationFunctionName } from '../lib/supabase'
import type {
  AppRole,
  GuidanceItem,
  Insight,
  InsightStatus,
  ReferenceMaterial,
  ScholarProfile,
} from '../types'

interface InsightRow {
  id: string
  scholar_id: string
  body_ar: string | null
  body_en: string | null
  reference_material: unknown
  status: InsightStatus
  translation_status: Insight['translationStatus']
  revision_number: number
  published_at: string | null
  updated_at: string | null
}

interface GuidanceRow {
  id: string
  situation_id: string
  title_en: string
  title_ar: string | null
  verse_key: string
  surah_name_en: string
  verse_ar: string
  verse_en: string
  context_en: string
  source_revision: number
  needs_review: boolean
  active: boolean
  scholar_insights: InsightRow[] | null
}

function emptyInsight(userId: string): Insight {
  return {
    id: null,
    scholarId: userId,
    bodyAr: '',
    bodyEn: '',
    references: [],
    status: 'draft',
    translationStatus: 'not_started',
    revisionNumber: 0,
    updatedAt: null,
  }
}

function safeHttpsUrl(value: unknown): string | undefined {
  if (typeof value !== 'string' || !value.trim() || value.length > 2048) return undefined
  try {
    const parsed = new URL(value.trim())
    return parsed.protocol === 'https:' && parsed.hostname ? parsed.toString() : undefined
  } catch {
    return undefined
  }
}

function mapReferences(value: unknown): ReferenceMaterial[] {
  if (!Array.isArray(value)) return []
  return value.flatMap((entry, index) => {
    if (!entry || typeof entry !== 'object') return []
    const candidate = entry as Record<string, unknown>
    const rawLabel = typeof candidate.label === 'string'
      ? candidate.label
      : typeof candidate.title === 'string'
        ? candidate.title
        : ''
    const label = rawLabel.trim()
    if (!label || label.length > 300) return []
    if (
      candidate.id !== undefined &&
      (typeof candidate.id !== 'string' || !candidate.id.trim() || candidate.id.length > 128)
    ) return []
    const id = typeof candidate.id === 'string' ? candidate.id.trim() : `reference-${index + 1}`
    const hasUrl = candidate.url !== undefined && candidate.url !== null && candidate.url !== ''
    const url = hasUrl ? safeHttpsUrl(candidate.url) : undefined
    if (hasUrl && !url) return []
    return [{ id, label, ...(url ? { url } : {}) }]
  })
}

function mapInsight(row: InsightRow | undefined, userId: string): Insight {
  if (!row) return emptyInsight(userId)
  return {
    id: row.id,
    scholarId: row.scholar_id,
    bodyAr: row.body_ar ?? '',
    bodyEn: row.body_en ?? '',
    references: mapReferences(row.reference_material),
    status: row.status,
    translationStatus: row.translation_status,
    revisionNumber: row.revision_number,
    updatedAt: row.updated_at,
  }
}

export async function loadGuidanceItems(userId: string, role: AppRole): Promise<GuidanceItem[]> {
  if (!supabase) throw new Error('Supabase is not configured.')
  const { data, error } = await supabase
    .from('guidance_items')
    .select(
      'id,situation_id,verse_key,title_en,title_ar,context_en,context_ar,surah_name_en,surah_name_ar,verse_ar,verse_en,source_hash,source_revision,needs_review,active,source_changed_at,last_synced_at,scholar_insights(id,guidance_item_id,scholar_id,supersedes_insight_id,body_ar,body_en,reference_material,status,translation_status,reviewed_source_hash,submitted_at,published_at,revision_number,created_at,updated_at)',
    )
    .eq('active', true)
    .order('source_changed_at', { ascending: false, nullsFirst: false })

  if (error) throw error
  return ((data ?? []) as unknown as GuidanceRow[]).map((row) => {
    const insights = [...(row.scholar_insights ?? [])]
    const working = insights
      .filter((item) => {
        if (item.status !== 'draft' && item.status !== 'submitted') return false
        return role === 'admin' ? item.status === 'submitted' : item.scholar_id === userId
      })
      .sort((left, right) => {
        if (left.status !== right.status) return left.status === 'submitted' ? -1 : 1
        return (right.updated_at ?? '').localeCompare(left.updated_at ?? '')
      })[0]
    const published = insights
      .filter((item) => item.status === 'published')
      .sort((left, right) => {
        const leftDate = left.published_at ?? left.updated_at ?? ''
        const rightDate = right.published_at ?? right.updated_at ?? ''
        return rightDate.localeCompare(leftDate)
      })[0]
    const workingInsight = working ? mapInsight(working, userId) : null
    const publishedInsight = published ? mapInsight(published, userId) : null

    return {
      id: row.id,
      situationId: row.situation_id,
      titleEn: row.title_en,
      titleAr: row.title_ar ?? '',
      verseKey: row.verse_key,
      surahNameEn: row.surah_name_en,
      ayahAr: row.verse_ar,
      meaningEn: row.verse_en,
      orientationEn: row.context_en,
      reviewState: row.needs_review && row.source_revision > 1 ? 'changed' : 'needs_review',
      needsReview: row.needs_review,
      active: row.active,
      workingInsight,
      publishedInsight,
      insight: workingInsight ?? publishedInsight ?? emptyInsight(userId),
    }
  })
}

export async function saveInsight(
  guidanceItemId: string,
  insight: Insight,
  nextStatus: InsightStatus,
): Promise<Insight> {
  if (!supabase) throw new Error('Supabase is not configured.')

  if (insight.id && insight.status === 'published') {
    if (nextStatus !== 'draft') {
      throw new Error('Create a replacement draft before submitting published content.')
    }
    const { data: replacement, error: replacementError } = await supabase.rpc(
      'create_scholar_replacement_draft',
      { p_published_insight_id: insight.id },
    )
    if (replacementError) throw replacementError
    return mapInsight(replacement as InsightRow, insight.scholarId)
  }

  let insightId = insight.id
  let expectedRevisionNumber = insight.revisionNumber
  if (!insightId || insight.status === 'archived') {
    const { data: created, error: createError } = await supabase.rpc(
      'create_scholar_insight_draft',
      { p_guidance_item_id: guidanceItemId },
    )
    if (createError) throw createError
    const createdInsight = mapInsight(created as InsightRow, insight.scholarId)
    insightId = createdInsight.id
    expectedRevisionNumber = createdInsight.revisionNumber
  }
  if (!insightId) throw new Error('The draft could not be created.')

  const { data: saved, error: saveError } = await supabase.rpc('save_scholar_insight_draft', {
    p_insight_id: insightId,
    p_body_ar: insight.bodyAr,
    p_body_en: insight.bodyEn || null,
    p_reference_material: insight.references,
    p_expected_revision_number: expectedRevisionNumber,
  })
  if (saveError) throw saveError
  const savedInsight = mapInsight(saved as InsightRow, insight.scholarId)

  if (nextStatus === 'submitted') {
    const { data: submitted, error: submitError } = await supabase.rpc('submit_scholar_insight', {
      p_insight_id: insightId,
      p_expected_revision_number: savedInsight.revisionNumber,
    })
    if (submitError) throw submitError
    return mapInsight(submitted as InsightRow, insight.scholarId)
  }

  return savedInsight
}

export async function updateInsightStatus(
  insightId: string,
  status: 'published' | 'archived',
  scholarId: string,
): Promise<Insight> {
  if (!supabase) throw new Error('Supabase is not configured.')
  const functionName = status === 'published' ? 'publish_scholar_insight' : 'archive_scholar_insight'
  const { data, error } = await supabase.rpc(functionName, { p_insight_id: insightId })
  if (error) throw error
  return mapInsight(data as InsightRow, scholarId)
}

export async function generateEnglishDraft(
  insightId: string,
): Promise<{ bodyEn: string; revisionNumber: number }> {
  if (!supabase) throw new Error('Supabase is not configured.')
  const { data, error } = await supabase.functions.invoke(translationFunctionName, {
    body: {
      insight_id: insightId,
    },
  })
  if (error) throw error
  const translation = typeof data?.body_en === 'string' ? data.body_en.trim() : ''
  if (!translation) throw new Error('The translation function returned an empty draft.')
  const revisionNumber = data?.revision_number
  if (!Number.isInteger(revisionNumber) || revisionNumber < 1) {
    throw new Error('The translation function returned an invalid source revision.')
  }
  return { bodyEn: translation, revisionNumber }
}

export async function reviewEnglishDraft(insight: Insight): Promise<Insight> {
  if (!supabase) throw new Error('Supabase is not configured.')
  if (!insight.id) throw new Error('Save the insight before reviewing its translation.')
  const { data, error } = await supabase.rpc('review_scholar_insight_translation', {
    p_insight_id: insight.id,
    p_body_en: insight.bodyEn,
    p_expected_revision_number: insight.revisionNumber,
  })
  if (error) throw error
  return mapInsight(data as InsightRow, insight.scholarId)
}

export async function loadScholarProfile(
  userId: string,
  role: 'admin' | 'scholar',
): Promise<ScholarProfile> {
  if (!supabase) throw new Error('Supabase is not configured.')
  let request = supabase
    .from('scholar_profiles')
    .select(
      'user_id,display_name_en,display_name_ar,title_en,title_ar,bio_en,bio_ar,avatar_path,facebook_url,instagram_url,youtube_url,tiktok_url,website_url,verified,is_public',
    )
  request = role === 'admin'
    ? request.order('updated_at', { ascending: false }).limit(1)
    : request.eq('user_id', userId)
  const { data, error } = await request.maybeSingle()
  if (error) throw error
  return {
    userId: data?.user_id ?? userId,
    displayNameEn: data?.display_name_en ?? '',
    displayNameAr: data?.display_name_ar ?? '',
    titleEn: data?.title_en ?? '',
    titleAr: data?.title_ar ?? '',
    bioEn: data?.bio_en ?? '',
    bioAr: data?.bio_ar ?? '',
    avatarPath: data?.avatar_path ?? '',
    facebookUrl: data?.facebook_url ?? '',
    instagramUrl: data?.instagram_url ?? '',
    youtubeUrl: data?.youtube_url ?? '',
    tiktokUrl: data?.tiktok_url ?? '',
    websiteUrl: data?.website_url ?? '',
    verified: data?.verified ?? false,
    isPublic: data?.is_public ?? false,
  }
}

export async function saveScholarProfile(
  profile: ScholarProfile,
  role: 'admin' | 'scholar',
): Promise<void> {
  if (!supabase) throw new Error('Supabase is not configured.')
  if (role === 'admin') {
    const { error } = await supabase.rpc('admin_upsert_scholar_profile', {
      p_user_id: profile.userId,
      p_display_name_en: profile.displayNameEn,
      p_display_name_ar: profile.displayNameAr || null,
      p_title_en: profile.titleEn || null,
      p_title_ar: profile.titleAr || null,
      p_bio_en: profile.bioEn || null,
      p_bio_ar: profile.bioAr || null,
      p_avatar_path: profile.avatarPath || null,
      p_instagram_url: profile.instagramUrl || null,
      p_youtube_url: profile.youtubeUrl || null,
      p_facebook_url: profile.facebookUrl || null,
      p_tiktok_url: profile.tiktokUrl || null,
      p_website_url: profile.websiteUrl || null,
    })
    if (error) throw error
    return
  }

  const { error } = await supabase.from('scholar_profiles').update({
    display_name_en: profile.displayNameEn,
    display_name_ar: profile.displayNameAr || null,
    title_en: profile.titleEn || null,
    title_ar: profile.titleAr || null,
    bio_en: profile.bioEn || null,
    bio_ar: profile.bioAr || null,
    facebook_url: profile.facebookUrl || null,
    instagram_url: profile.instagramUrl || null,
    youtube_url: profile.youtubeUrl || null,
    tiktok_url: profile.tiktokUrl || null,
    website_url: profile.websiteUrl || null,
  }).eq('user_id', profile.userId)
  if (error) throw error
}

export async function setScholarProfileVisibility(
  userId: string,
  verified: boolean,
  isPublic: boolean,
): Promise<void> {
  if (!supabase) throw new Error('Supabase is not configured.')
  const { error } = await supabase.rpc('admin_set_scholar_profile_visibility', {
    p_user_id: userId,
    p_verified: verified,
    p_is_public: isPublic,
  })
  if (error) throw error
}
