import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => ({
  base: process.env.VITE_BASE_PATH?.trim() || '/',
  plugins: [react()],
  build: {
    // Keep source maps available while developing without publishing source and
    // demo-only strings alongside the production GitHub Pages bundle.
    sourcemap: mode !== 'production',
  },
}))
