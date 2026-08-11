import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL?.trim() ?? ''
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim() ?? ''
const requestedDevelopmentDemo =
  import.meta.env.DEV && new URLSearchParams(window.location.search).has('demoRole')

export const hasSupabaseConfiguration = Boolean(url && publishableKey)
export const isDevelopmentDemo =
  import.meta.env.DEV && (!hasSupabaseConfiguration || requestedDevelopmentDemo)
export const translationFunctionName =
  import.meta.env.VITE_TRANSLATION_FUNCTION?.trim() || 'translate-scholar-insight'

export function publicScholarAvatarURL(path: string): string | null {
  const segments = path
    .trim()
    .split('/')
    .filter(Boolean)
  if (
    !hasSupabaseConfiguration ||
    segments.length === 0 ||
    segments.some((segment) => segment === '.' || segment === '..')
  ) return null

  try {
    const encodedPath = segments.map((segment) => encodeURIComponent(segment)).join('/')
    return new URL(
      `/storage/v1/object/public/scholar-avatars/${encodedPath}`,
      url,
    ).toString()
  } catch {
    return null
  }
}

export const supabase = hasSupabaseConfiguration
  ? createClient(url, publishableKey, {
      auth: {
        detectSessionInUrl: true,
        persistSession: true,
        autoRefreshToken: true,
      },
    })
  : null
