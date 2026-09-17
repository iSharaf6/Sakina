import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'

// GitHub Pages cannot send response headers, so the production build carries
// its Content-Security-Policy as a meta tag. The dev server is left alone
// because React Fast Refresh needs an inline preamble and a websocket.
const contentSecurityPolicy = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https://*.supabase.co",
  "font-src 'self' data:",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ')

const securityMeta = (): Plugin => ({
  name: 'haneen-security-meta',
  apply: 'build',
  transformIndexHtml: () => [
    { tag: 'meta', attrs: { 'http-equiv': 'Content-Security-Policy', content: contentSecurityPolicy }, injectTo: 'head-prepend' },
    { tag: 'meta', attrs: { name: 'referrer', content: 'strict-origin-when-cross-origin' }, injectTo: 'head' },
  ],
})

export default defineConfig(({ mode }) => ({
  base: process.env.VITE_BASE_PATH?.trim() || '/',
  plugins: [react(), securityMeta()],
  build: {
    // Keep source maps available while developing without publishing source and
    // demo-only strings alongside the production GitHub Pages bundle.
    sourcemap: mode !== 'production',
  },
}))
