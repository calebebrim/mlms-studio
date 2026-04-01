import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { getHealth, postJob, type HealthResponse, type JobOkResponse } from '../api/mlmsWorker'

export type JobHistoryPoint = {
  at: number
  jobId: string
  stage: string
  ok: boolean
}

export type RealtimeEntry = { at: number; raw: string }

export const useAnalyticsShellStore = defineStore('analyticsShell', () => {
  const health = ref<HealthResponse | null>(null)
  const healthError = ref<string | null>(null)
  const jobLoading = ref(false)
  const jobError = ref<string | null>(null)
  const lastJob = ref<JobOkResponse | null>(null)
  const jobHistory = ref<JobHistoryPoint[]>([])
  const realtimeLog = ref<RealtimeEntry[]>([])

  const lastPipelineStage = computed(() => {
    const j = lastJob.value
    if (!j || !('result' in j) || !j.result) return null
    const stage = j.result.stage
    return typeof stage === 'string' ? stage : null
  })

  async function refreshHealth() {
    healthError.value = null
    try {
      health.value = await getHealth()
    } catch (e) {
      health.value = null
      healthError.value = e instanceof Error ? e.message : String(e)
    }
  }

  async function runPipelineStub(stage = 'default') {
    jobError.value = null
    jobLoading.value = true
    try {
      const res = await postJob({
        job_type: 'mlms.pipeline_stub',
        payload: { stage },
      })
      if (res.status === 'failed') {
        jobError.value = res.error.message
        lastJob.value = null
        return
      }
      lastJob.value = res
      const st = typeof res.result.stage === 'string' ? res.result.stage : stage
      jobHistory.value = [
        ...jobHistory.value,
        { at: Date.now(), jobId: res.job_id, stage: st, ok: true },
      ].slice(-64)
    } catch (e) {
      jobError.value = e instanceof Error ? e.message : String(e)
      lastJob.value = null
    } finally {
      jobLoading.value = false
    }
  }

  function pushRealtimeMessage(raw: string) {
    realtimeLog.value = [...realtimeLog.value, { at: Date.now(), raw }].slice(-100)
  }

  return {
    health,
    healthError,
    jobLoading,
    jobError,
    lastJob,
    jobHistory,
    realtimeLog,
    lastPipelineStage,
    refreshHealth,
    runPipelineStub,
    pushRealtimeMessage,
  }
})
