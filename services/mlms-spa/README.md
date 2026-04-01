# MLMS Studio — frontend (Vue 3)

- **Dev:** em `services/mlms-spa`, `npm install` e `npm run dev`. O proxy Vite encaminha `/api` → BFF (`MLMS_API_PROXY_TARGET`, padrão `http://127.0.0.1:3000`). Use `VITE_MLMS_API_BASE=/api/v1` (ver `.env.development`).
- **API:** cliente em `src/api/mlmsWorker.ts` alinhado a `docs/api/openapi-v0.yaml` (`/api/v1/health`, `POST /api/v1/jobs`).
- **Tempo real:** `VITE_REALTIME_WS_URL` (ex.: WebSocket do Node). Vazio = canal desligado no UI.
