export type AppRole = 'admin' | 'scholar'
export type InsightStatus = 'draft' | 'submitted' | 'published' | 'archived'
export type ReviewState = 'needs_review' | 'changed'
export type TranslationStatus = 'not_started' | 'generated' | 'reviewed'

export interface ReferenceMaterial {
  id: string
  label: string
  url?: string
}

export interface Insight {
  id: string | null
  scholarId: string
  bodyAr: string
  bodyEn: string
  references: ReferenceMaterial[]
  status: InsightStatus
  translationStatus: TranslationStatus
  revisionNumber: number
  updatedAt: string | null
}

export interface GuidanceItem {
  id: string
  situationId: string
  titleEn: string
  titleAr: string
  verseKey: string
  surahNameEn: string
  surahNameAr: string
  ayahAr: string
  meaningEn: string
  orientationEn: string
  orientationAr: string
  reviewState: ReviewState
  needsReview?: boolean
  active: boolean
  workingInsight: Insight | null
  publishedInsight: Insight | null
  insight: Insight
}

export interface ScholarProfile {
  userId: string
  displayNameEn: string
  displayNameAr: string
  titleEn: string
  titleAr: string
  bioEn: string
  bioAr: string
  avatarPath: string
  facebookUrl: string
  instagramUrl: string
  youtubeUrl: string
  tiktokUrl: string
  websiteUrl: string
  verified: boolean
  isPublic: boolean
}

export interface AuthUser {
  id: string
  email: string
  role: AppRole
}

export type NavDestination = 'queue' | 'drafts' | 'submitted' | 'published' | 'profile'
