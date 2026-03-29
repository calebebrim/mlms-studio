import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/** BFF Nest (`services/mlms-api`). Em Compose: `http://mlms-api:3000`. */
const apiTarget = process.env.MLMS_API_PROXY_TARGET ?? 'http://127.0.0.1:3000'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    // Dev: CSP permissivo para HMR/Vite; produção deve endurecer no host (CDN/nginx).
    headers: {
      'Content-Security-Policy':
        "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self' ws: wss: http://127.0.0.1:* http://localhost:*;",
    },
    proxy: {
      '/api': { target: apiTarget, changeOrigin: true },
    },
  },
})
