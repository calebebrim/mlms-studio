import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import {
  postIngestWData,
  type JobErrResponse,
  type JobOkResponse,
} from '../api/mlmsWorker'
import type { WDataSample } from '../types/wData'

function buildDemoSamples(): WDataSample[] {
  const count = 3
  const points = 160
  return Array.from({ length: count }, (_, s) => {
    const mz = Array.from({ length: points }, (_, i) => 50 + i * 0.4)
    const all = mz.map((_, i) => {
      const g1 = Math.exp(-((i - 35 - s * 6) ** 2) / 180)
      const g2 = Math.exp(-((i - 95 + s * 4) ** 2) / 240) * 0.45
      return g1 + g2 + Math.random() * 0.04
    })
    return { file: `demo_amostra_${s + 1}.mzML`, mz, all }
  })
}

export const useWDataStore = defineStore('wData', () => {
  const samples = ref<WDataSample[]>([])
  const selectedIndex = ref(0)
  const ingestLoading = ref(false)
  const ingestError = ref<string | null>(null)
  const lastIngestResult = ref<JobOkResponse | null>(null)
  const lastIngestFailure = ref<JobErrResponse | null>(null)

  const selectedSample = computed(() => {
    const list = samples.value
    const i = selectedIndex.value
    if (list.length === 0 || i < 0 || i >= list.length) return null
    return list[i]!
  })

  watch(samples, (list) => {
    if (selectedIndex.value >= list.length) {
      selectedIndex.value = list.length > 0 ? list.length - 1 : 0
    }
  })

  function selectSample(index: number) {
    if (index >= 0 && index < samples.value.length) selectedIndex.value = index
  }

  function loadDemoSamples() {
    samples.value = buildDemoSamples()
    selectedIndex.value = 0
    ingestError.value = null
    lastIngestResult.value = null
    lastIngestFailure.value = null
  }

  function clearSamples() {
    samples.value = []
    selectedIndex.value = 0
    ingestError.value = null
    lastIngestResult.value = null
    lastIngestFailure.value = null
  }

  async function submitIngestJob() {
    ingestError.value = null
    lastIngestResult.value = null
    lastIngestFailure.value = null
    if (samples.value.length === 0) {
      ingestError.value = 'Nenhuma amostra para enviar.'
      return
    }
    ingestLoading.value = true
    try {
      const res = await postIngestWData({
        files: samples.value.map((s) => s.file),
        all: samples.value.map((s) => s.all),
        mz: samples.value.map((s) => s.mz),
      })
      if (res.status === 'failed') {
        lastIngestFailure.value = res
        const c = res.error.code
        ingestError.value =
          c === 'invalid_job_type' || c === 'unknown_job_type'
            ? 'Ingestão ainda não disponível no worker/BFF — tipo de job não reconhecido.'
            : res.error.message
        return
      }
      lastIngestResult.value = res
    } catch (e) {
      ingestError.value = e instanceof Error ? e.message : String(e)
    } finally {
      ingestLoading.value = false
    }
  }

  return {
    samples,
    selectedIndex,
    selectedSample,
    ingestLoading,
    ingestError,
    lastIngestResult,
    lastIngestFailure,
    selectSample,
    loadDemoSamples,
    clearSamples,
    submitIngestJob,
  }
})
