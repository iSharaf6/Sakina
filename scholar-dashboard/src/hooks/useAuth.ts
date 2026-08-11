import { useCallback, useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { isDevelopmentDemo, supabase } from '../lib/supabase'
import type { AppRole, AuthUser } from '../types'

type AuthStatus = 'loading' | 'ready' | 'signed_out' | 'unauthorized' | 'misconfigured'

interface AuthState {
  status: AuthStatus
  user: AuthUser | null
}

const allowedRoles = new Set<AppRole>(['admin', 'scholar'])

function demoRole(): AppRole {
  const role = new URLSearchParams(window.location.search).get('demoRole')
  return role === 'admin' ? 'admin' : 'scholar'
}

export function useAuth() {
  const [state, setState] = useState<AuthState>(() => {
    if (isDevelopmentDemo) {
      return {
        status: 'ready',
        user: {
          id: 'demo-scholar',
          email: 'development-demo@localhost',
          role: demoRole(),
        },
      }
    }
    if (!supabase) return { status: 'misconfigured', user: null }
    return { status: 'loading', user: null }
  })

  const validateSession = useCallback(async (session: Session | null) => {
    if (!supabase || isDevelopmentDemo) return
    if (!session?.user) {
      setState({ status: 'signed_out', user: null })
      return
    }

    const { data, error } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', session.user.id)
      .maybeSingle()

    const role = data?.role as AppRole | undefined
    if (error || !role || !allowedRoles.has(role)) {
      await supabase.auth.signOut()
      setState({ status: 'unauthorized', user: null })
      return
    }

    setState({
      status: 'ready',
      user: {
        id: session.user.id,
        email: session.user.email ?? '',
        role,
      },
    })
  }, [])

  useEffect(() => {
    if (!supabase || isDevelopmentDemo) return

    let current = true
    void supabase.auth.getSession().then(({ data }) => {
      if (current) void validateSession(data.session)
    })

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (current) void validateSession(session)
    })

    return () => {
      current = false
      listener.subscription.unsubscribe()
    }
  }, [validateSession])

  const sendMagicLink = useCallback(async (email: string) => {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: false,
        emailRedirectTo: window.location.origin,
      },
    })
    if (error) throw error
  }, [])

  const verifyCode = useCallback(async (email: string, token: string) => {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { error } = await supabase.auth.verifyOtp({ email, token, type: 'email' })
    if (error) throw error
  }, [])

  const signOut = useCallback(async () => {
    if (isDevelopmentDemo) return
    await supabase?.auth.signOut()
    setState({ status: 'signed_out', user: null })
  }, [])

  return { ...state, sendMagicLink, verifyCode, signOut }
}
