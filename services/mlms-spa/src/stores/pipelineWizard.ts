import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

/** Passos do assistente alinhados ao manuscrito MS-ML (SOF-49). */
export const PIPELINE_STEPS = [
  {
    id: 'dataset' as const,
    label: 'Dataset',
    hint: 'Seleção da fonte de dados para o experimento.',
  },
  {
    id: 'preprocess' as const,
    label: 'Pré-processamento',
    hint: 'Redimensionamento, redução de ruído, correção de baseline, etc.',
  },
  {
    id: 'extraction' as const,
    label: 'Extração',
    hint: 'GA, ressonância de features, watchpoints.',
  },
  {
    id: 'mlp' as const,
    label: 'MLP',
    hint: 'Hiperparâmetros da rede — contrato de API ainda em evolução.',
  },
  {
    id: 'cross_validation' as const,
    label: 'Validação cruzada',
    hint: 'Estratégia de partição e repetições.',
  },
  {
    id: 'metrics' as const,
    label: 'Métricas',
    hint: 'O que reportar ao fim do treino / validação.',
  },
  {
    id: 'layers' as const,
    label: 'Camadas',
    hint: 'Nós por camada — estrutura do MLP.',
  },
] as const

export type PipelineStepId = (typeof PIPELINE_STEPS)[number]['id']

/** Blocos do construtor visual (todos os passos exceto dataset). */
export type VisualPipelineBlockKind = Exclude<PipelineStepId, 'dataset'>

export type VisualStageBlock = {
  id: string
  kind: VisualPipelineBlockKind
}

/** Passos disponíveis como blocos no canvas (exclui dataset). */
export const PIPELINE_PALETTE_ITEMS = PIPELINE_STEPS.filter(
  (s): s is (typeof PIPELINE_STEPS)[number] & { id: VisualPipelineBlockKind } =>
    s.id !== 'dataset',
)

export type PreprocessDraft = {
  resizeEnabled: boolean
  targetLength: number
  noiseReduction: boolean
  baselineCorrection: boolean
}

export type ExtractionDraft = {
  geneticAlgorithm: boolean
  featureResonance: boolean
  watchpoints: boolean
}

export type MlpDraft = {
  hiddenLayerCount: number
  learningRate: number
  epochs: number
}

export type CrossValidationDraft = {
  strategy: 'kfold' | 'stratified_kfold' | 'holdout'
  folds: number
}

export type MetricsDraft = {
  accuracy: boolean
  precisionRecall: boolean
  f1: boolean
  confusionMatrix: boolean
}

export type LayerRow = {
  id: string
  units: number
  activation: 'relu' | 'tanh' | 'sigmoid'
}

function randomId() {
  return `L-${Math.random().toString(36).slice(2, 10)}`
}

export const usePipelineWizardStore = defineStore('pipelineWizard', () => {
  const currentStepIndex = ref(0)

  /** String vazia = nenhum dataset (adequado a `<select v-model>`). */
  const selectedDatasetId = ref('')

  const preprocess = ref<PreprocessDraft>({
    resizeEnabled: true,
    targetLength: 1024,
    noiseReduction: true,
    baselineCorrection: false,
  })

  const extraction = ref<ExtractionDraft>({
    geneticAlgorithm: false,
    featureResonance: true,
    watchpoints: false,
  })

  const mlp = ref<MlpDraft>({
    hiddenLayerCount: 2,
    learningRate: 0.001,
    epochs: 50,
  })

  const crossValidation = ref<CrossValidationDraft>({
    strategy: 'kfold',
    folds: 5,
  })

  const metrics = ref<MetricsDraft>({
    accuracy: true,
    precisionRecall: true,
    f1: true,
    confusionMatrix: false,
  })

  const layers = ref<LayerRow[]>([
    { id: randomId(), units: 64, activation: 'relu' },
    { id: randomId(), units: 32, activation: 'relu' },
  ])

  /** Ordem do canvas = ordem do array `stages` no rascunho. */
  const visualStageBlocks = ref<VisualStageBlock[]>([])

  const totalSteps = computed(() => PIPELINE_STEPS.length)

  const currentStep = computed(() => PIPELINE_STEPS[currentStepIndex.value]!)

  const canGoPrev = computed(() => currentStepIndex.value > 0)

  const canGoNext = computed(() => currentStepIndex.value < totalSteps.value - 1)

  const isDatasetStepValid = computed(() => selectedDatasetId.value.trim().length > 0)

  function goNext() {
    if (canGoNext.value) currentStepIndex.value += 1
  }

  function goPrev() {
    if (canGoPrev.value) currentStepIndex.value -= 1
  }

  function goToStep(index: number) {
    if (index >= 0 && index < totalSteps.value) currentStepIndex.value = index
  }

  function addLayer() {
    layers.value.push({ id: randomId(), units: 16, activation: 'relu' })
  }

  function removeLayer(id: string) {
    if (layers.value.length <= 1) return
    layers.value = layers.value.filter((r) => r.id !== id)
  }

  function addVisualBlock(kind: VisualPipelineBlockKind, atIndex?: number) {
    const row: VisualStageBlock = { id: randomId(), kind }
    const list = visualStageBlocks.value
    if (atIndex === undefined || atIndex >= list.length) {
      list.push(row)
    } else {
      list.splice(atIndex, 0, row)
    }
  }

  function removeVisualBlock(id: string) {
    visualStageBlocks.value = visualStageBlocks.value.filter((b) => b.id !== id)
  }

  /** `toIndex` = posição final desejada antes do drop (inserir antes do elemento que estava nesse índice). */
  function moveVisualBlock(fromIndex: number, toIndex: number) {
    if (fromIndex === toIndex) return
    const arr = [...visualStageBlocks.value]
    const [item] = arr.splice(fromIndex, 1)
    if (!item) return
    let insertAt = toIndex
    if (fromIndex < toIndex) insertAt = toIndex - 1
    arr.splice(insertAt, 0, item)
    visualStageBlocks.value = arr
  }

  function reset() {
    currentStepIndex.value = 0
    selectedDatasetId.value = ''
    preprocess.value = {
      resizeEnabled: true,
      targetLength: 1024,
      noiseReduction: true,
      baselineCorrection: false,
    }
    extraction.value = {
      geneticAlgorithm: false,
      featureResonance: true,
      watchpoints: false,
    }
    mlp.value = { hiddenLayerCount: 2, learningRate: 0.001, epochs: 50 }
    crossValidation.value = { strategy: 'kfold', folds: 5 }
    metrics.value = {
      accuracy: true,
      precisionRecall: true,
      f1: true,
      confusionMatrix: false,
    }
    layers.value = [
      { id: randomId(), units: 64, activation: 'relu' },
      { id: randomId(), units: 32, activation: 'relu' },
    ]
    visualStageBlocks.value = []
  }

  /** Payload serializável para futuro POST de job (stub até contrato fechado). */
  function buildExperimentDraft() {
    return {
      datasetId: selectedDatasetId.value.trim() || null,
      stages: visualStageBlocks.value.map((b) => ({ kind: b.kind })),
      preprocess: { ...preprocess.value },
      extraction: { ...extraction.value },
      mlp: { ...mlp.value },
      crossValidation: { ...crossValidation.value },
      metrics: { ...metrics.value },
      layers: layers.value.map(({ units, activation }) => ({ units, activation })),
    }
  }

  return {
    currentStepIndex,
    selectedDatasetId,
    preprocess,
    extraction,
    mlp,
    crossValidation,
    metrics,
    layers,
    totalSteps,
    currentStep,
    canGoPrev,
    canGoNext,
    isDatasetStepValid,
    goNext,
    goPrev,
    goToStep,
    addLayer,
    removeLayer,
    visualStageBlocks,
    addVisualBlock,
    removeVisualBlock,
    moveVisualBlock,
    reset,
    buildExperimentDraft,
  }
})
