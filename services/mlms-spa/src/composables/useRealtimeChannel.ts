import { onBeforeUnmount, ref, watch } from 'vue'
import { useAnalyticsShellStore } from '../stores/analyticsShell'

export type RealtimeStatus = 'disabled' | 'connecting' | 'open' | 'closed' | 'error'

/**
 * WebSocket opcional exposto pelo BFF Node (`VITE_REALTIME_WS_URL`).
 * Mensagens texto são anexadas ao store para o shell analítico (gráficos podem reagir depois).
 */
export function useRealtimeChannel() {
  const store = useAnalyticsShellStore()
  const status = ref<RealtimeStatus>('disabled')
  const lastError = ref<string | null>(null)
  let ws: WebSocket | null = null
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null
  let stopped = false

  const url = (import.meta.env.VITE_REALTIME_WS_URL ?? '').trim()

  function clearReconnect() {
    if (reconnectTimer) {
      clearTimeout(reconnectTimer)
      reconnectTimer = null
    }
  }

  function connect() {
    if (!url) {
      status.value = 'disabled'
      return
    }
    clearReconnect()
    ws?.close()
    status.value = 'connecting'
    lastError.value = null
    try {
      ws = new WebSocket(url)
    } catch (e) {
      status.value = 'error'
      lastError.value = e instanceof Error ? e.message : String(e)
      return
    }

    ws.onopen = () => {
      if (stopped) return
      status.value = 'open'
    }
    ws.onmessage = (ev) => {
      const raw = typeof ev.data === 'string' ? ev.data : '[binary]'
      store.pushRealtimeMessage(raw)
    }
    ws.onerror = () => {
      lastError.value = 'websocket error'
    }
    ws.onclose = () => {
      if (stopped) {
        status.value = 'closed'
        return
      }
      status.value = 'closed'
      reconnectTimer = setTimeout(connect, 4000)
    }
  }

  function disconnect() {
    stopped = true
    clearReconnect()
    ws?.close()
    ws = null
    status.value = url ? 'closed' : 'disabled'
  }

  watch(
    () => url,
    (u) => {
      stopped = false
      if (u) connect()
      else {
        disconnect()
        status.value = 'disabled'
      }
    },
    { immediate: true },
  )

  onBeforeUnmount(() => disconnect())

  return { status, lastError, reconnect: connect }
}
