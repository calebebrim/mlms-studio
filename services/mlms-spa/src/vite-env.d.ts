/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_MLMS_API_BASE: string
  readonly VITE_REALTIME_WS_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
