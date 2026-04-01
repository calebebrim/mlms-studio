<script setup lang="ts">
import { onMounted, computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { PIPELINE_STEPS, usePipelineWizardStore } from '../../stores/pipelineWizard'
import { useDatasetsStore } from '../../stores/datasets'
import PipelineVisualBuilder from '../../components/pipeline/PipelineVisualBuilder.vue'

const pipelineTab = ref<'wizard' | 'visual'>('wizard')

const wizard = usePipelineWizardStore()
const {
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
} = storeToRefs(wizard)

const datasets = useDatasetsStore()

onMounted(() => {
  if (!datasets.items.length && !datasets.loading) {
    void datasets.load()
  }
})

const nextDisabled = computed(() => {
  if (!canGoNext.value) return true
  if (currentStep.value.id === 'dataset' && !isDatasetStepValid.value) return true
  return false
})

function onStepClick(index: number) {
  wizard.goToStep(index)
}
</script>

<template>
  <div class="wizard">
    <header class="wizard__head">
      <h1 class="wizard__h">Pipeline de experimentação</h1>
      <p class="wizard__p">
        Assistente em passos alinhado ao fluxo MS-ML. O estado fica no Pinia até existir endpoint de jobs;
        use «Repor rascunho» para limpar.
      </p>
    </header>

    <div class="wizard__tabs" role="tablist" aria-label="Modo do pipeline">
      <button
        type="button"
        role="tab"
        class="wizard__tab"
        :class="{ 'wizard__tab--active': pipelineTab === 'wizard' }"
        :aria-selected="pipelineTab === 'wizard'"
        @click="pipelineTab = 'wizard'"
      >
        Assistente
      </button>
      <button
        type="button"
        role="tab"
        class="wizard__tab"
        :class="{ 'wizard__tab--active': pipelineTab === 'visual' }"
        :aria-selected="pipelineTab === 'visual'"
        @click="pipelineTab = 'visual'"
      >
        Construtor visual
      </button>
    </div>

    <PipelineVisualBuilder v-if="pipelineTab === 'visual'" class="wizard__visual" />

    <template v-else>
    <ol class="wizard__steps" aria-label="Progresso do assistente">
      <li
        v-for="(stepDef, i) in PIPELINE_STEPS"
        :key="stepDef.id"
        class="wizard__step"
        :class="{
          'wizard__step--done': i < currentStepIndex,
          'wizard__step--current': i === currentStepIndex,
        }"
      >
        <button type="button" class="wizard__step-btn" @click="onStepClick(i)">
          <span class="wizard__step-num">{{ i + 1 }}</span>
          <span class="wizard__step-label">{{ stepDef.label }}</span>
        </button>
      </li>
    </ol>

    <p class="wizard__hint">{{ currentStep.hint }}</p>

    <div
      class="wizard__panel"
      role="region"
      :aria-label="`Passo ${currentStepIndex + 1} de ${totalSteps}: ${currentStep.label}`"
    >
      <!-- Dataset -->
      <div v-if="currentStep.id === 'dataset'" class="panel">
        <p v-if="datasets.error" class="panel__err">{{ datasets.error }}</p>
        <p v-if="datasets.loading" class="panel__muted">A carregar datasets…</p>
        <template v-else>
          <label class="field">
            <span class="field__label">Dataset</span>
            <select v-model="selectedDatasetId" class="field__input">
              <option value="" disabled>Escolher um dataset…</option>
              <option v-for="d in datasets.sortedItems" :key="d.id" :value="d.id">
                {{ d.name }}
              </option>
            </select>
          </label>
          <p v-if="!datasets.sortedItems.length" class="panel__muted">
            Nenhum dataset na API. Carregue ficheiros em <strong>Datasets</strong>.
          </p>
        </template>
      </div>

      <!-- Pré-processamento -->
      <div v-else-if="currentStep.id === 'preprocess'" class="panel panel--grid">
        <label class="check">
          <input v-model="preprocess.resizeEnabled" type="checkbox" />
          Redimensionar espectros
        </label>
        <label class="field">
          <span class="field__label">Comprimento alvo</span>
          <input
            v-model.number="preprocess.targetLength"
            type="number"
            min="64"
            max="65536"
            step="64"
            class="field__input"
            :disabled="!preprocess.resizeEnabled"
          />
        </label>
        <label class="check">
          <input v-model="preprocess.noiseReduction" type="checkbox" />
          Redução de ruído
        </label>
        <label class="check">
          <input v-model="preprocess.baselineCorrection" type="checkbox" />
          Correção de baseline
        </label>
      </div>

      <!-- Extração -->
      <div v-else-if="currentStep.id === 'extraction'" class="panel panel--stack">
        <label class="check">
          <input v-model="extraction.geneticAlgorithm" type="checkbox" />
          Algoritmo genético (seleção de regiões)
        </label>
        <label class="check">
          <input v-model="extraction.featureResonance" type="checkbox" />
          Ressonância de features
        </label>
        <label class="check">
          <input v-model="extraction.watchpoints" type="checkbox" />
          Watchpoints espectrais
        </label>
      </div>

      <!-- MLP -->
      <div v-else-if="currentStep.id === 'mlp'" class="panel panel--grid">
        <label class="field">
          <span class="field__label">Camadas ocultas (contagem)</span>
          <input v-model.number="mlp.hiddenLayerCount" type="number" min="0" max="32" class="field__input" />
        </label>
        <label class="field">
          <span class="field__label">Learning rate</span>
          <input v-model.number="mlp.learningRate" type="number" min="1e-6" max="1" step="0.0001" class="field__input" />
        </label>
        <label class="field">
          <span class="field__label">Épocas</span>
          <input v-model.number="mlp.epochs" type="number" min="1" max="10000" class="field__input" />
        </label>
      </div>

      <!-- Validação cruzada -->
      <div v-else-if="currentStep.id === 'cross_validation'" class="panel panel--stack">
        <label class="field">
          <span class="field__label">Estratégia</span>
          <select v-model="crossValidation.strategy" class="field__input">
            <option value="kfold">K-fold</option>
            <option value="stratified_kfold">K-fold estratificado</option>
            <option value="holdout">Holdout</option>
          </select>
        </label>
        <label v-if="crossValidation.strategy !== 'holdout'" class="field">
          <span class="field__label">K (folds)</span>
          <input v-model.number="crossValidation.folds" type="number" min="2" max="20" class="field__input" />
        </label>
      </div>

      <!-- Métricas -->
      <div v-else-if="currentStep.id === 'metrics'" class="panel panel--stack">
        <label class="check"><input v-model="metrics.accuracy" type="checkbox" /> Accuracy</label>
        <label class="check"><input v-model="metrics.precisionRecall" type="checkbox" /> Precision / Recall</label>
        <label class="check"><input v-model="metrics.f1" type="checkbox" /> F1</label>
        <label class="check"><input v-model="metrics.confusionMatrix" type="checkbox" /> Matriz de confusão</label>
      </div>

      <!-- Camadas -->
      <div v-else-if="currentStep.id === 'layers'" class="panel panel--layers">
        <div class="layers__toolbar">
          <button type="button" class="btn btn--small btn--ghost" @click="wizard.addLayer">Adicionar camada</button>
        </div>
        <ul class="layers__list">
          <li v-for="(row, idx) in layers" :key="row.id" class="layers__row">
            <span class="layers__idx">{{ idx + 1 }}</span>
            <label class="field field--inline">
              <span class="field__label sr-only">Unidades</span>
              <input v-model.number="row.units" type="number" min="1" max="4096" class="field__input" />
            </label>
            <label class="field field--inline">
              <span class="field__label sr-only">Ativação</span>
              <select v-model="row.activation" class="field__input">
                <option value="relu">ReLU</option>
                <option value="tanh">Tanh</option>
                <option value="sigmoid">Sigmoid</option>
              </select>
            </label>
            <button
              type="button"
              class="btn btn--small btn--danger"
              :disabled="layers.length <= 1"
              @click="wizard.removeLayer(row.id)"
            >
              Remover
            </button>
          </li>
        </ul>
        <details class="draft">
          <summary>Rascunho JSON (stub de payload)</summary>
          <pre class="draft__pre">{{ JSON.stringify(wizard.buildExperimentDraft(), null, 2) }}</pre>
        </details>
      </div>
    </div>

    <div class="wizard__actions">
      <button type="button" class="btn btn--ghost" :disabled="!canGoPrev" @click="wizard.goPrev">Anterior</button>
      <button type="button" class="btn btn--ghost" @click="wizard.reset">Repor rascunho</button>
      <button type="button" class="btn" :disabled="nextDisabled" @click="wizard.goNext">Seguinte</button>
    </div>
    </template>
  </div>
</template>

<style scoped>
.wizard {
  flex: 1;
  padding: 24px 28px 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 56rem;
}

.wizard__tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.wizard__tab {
  cursor: pointer;
  border-radius: 8px;
  border: 1px solid var(--shell-border, #27272f);
  background: #111827;
  color: inherit;
  padding: 8px 14px;
  font-size: 0.85rem;
  font-weight: 500;
  font-family: inherit;
  opacity: 0.65;
}

.wizard__tab--active {
  opacity: 1;
  border-color: rgba(168, 85, 247, 0.45);
  background: rgba(124, 58, 237, 0.12);
}

.wizard__visual {
  width: 100%;
}

.wizard__head {
  max-width: 100%;
}

.wizard__h {
  margin: 0 0 8px;
  font-size: 1.35rem;
  font-weight: 600;
  letter-spacing: -0.02em;
}

.wizard__p {
  margin: 0;
  font-size: 0.9rem;
  opacity: 0.72;
  line-height: 1.5;
}

.wizard__hint {
  margin: 0;
  font-size: 0.8rem;
  opacity: 0.65;
  line-height: 1.45;
}

.wizard__steps {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.wizard__step {
  margin: 0;
  padding: 0;
}

.wizard__step-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid var(--shell-border, #27272f);
  background: #111827;
  font-size: 0.8rem;
  opacity: 0.55;
  color: inherit;
  cursor: pointer;
  font-family: inherit;
}

.wizard__step--current .wizard__step-btn {
  opacity: 1;
  border-color: rgba(168, 85, 247, 0.45);
  background: rgba(124, 58, 237, 0.12);
}

.wizard__step--done .wizard__step-btn {
  opacity: 0.85;
  border-color: #059669;
}

.wizard__step-btn:hover {
  opacity: 1;
}

.wizard__step-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1.5rem;
  height: 1.5rem;
  border-radius: 999px;
  background: #1f2937;
  font-weight: 600;
  font-size: 0.75rem;
}

.wizard__step--current .wizard__step-num {
  background: #6d28d9;
  color: #fff;
}

.wizard__step-label {
  font-weight: 500;
}

.wizard__panel {
  min-height: 160px;
  padding: 20px;
  border-radius: 12px;
  border: 1px solid var(--shell-border, #27272f);
  background: #0f1419;
}

.panel {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.panel--grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 14px;
  align-items: start;
}

.panel--stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.panel__muted {
  margin: 0;
  font-size: 0.875rem;
  opacity: 0.65;
}

.panel__err {
  margin: 0;
  font-size: 0.875rem;
  color: #f87171;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field--inline {
  flex: 1;
  min-width: 0;
}

.field__label {
  font-size: 0.75rem;
  font-weight: 500;
  opacity: 0.75;
}

.field__input {
  border-radius: 8px;
  border: 1px solid #374151;
  background: #111827;
  color: #e5e7eb;
  padding: 8px 10px;
  font-size: 0.875rem;
}

.field__input:disabled {
  opacity: 0.45;
}

.check {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.875rem;
  cursor: pointer;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.panel--layers {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.layers__toolbar {
  display: flex;
  gap: 8px;
}

.layers__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.layers__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}

.layers__idx {
  width: 1.5rem;
  font-size: 0.75rem;
  opacity: 0.55;
  font-weight: 600;
}

.draft {
  font-size: 0.8rem;
}

.draft__pre {
  margin: 8px 0 0;
  padding: 12px;
  border-radius: 8px;
  background: #080a0f;
  border: 1px solid #27272f;
  overflow: auto;
  max-height: 240px;
  font-size: 0.72rem;
  line-height: 1.4;
}

.wizard__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.btn {
  cursor: pointer;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 0.875rem;
  font-weight: 500;
  background: linear-gradient(135deg, #7c3aed, #a855f7);
  color: #fff;
}

.btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.btn--ghost {
  background: #1f2937;
  color: #e5e7eb;
  border: 1px solid #374151;
}

.btn--small {
  padding: 6px 12px;
  font-size: 0.8rem;
}

.btn--danger {
  background: #7f1d1d;
  border: 1px solid #991b1b;
}

.btn--danger:disabled {
  opacity: 0.35;
}
</style>
