<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import D3SpectrumPreview from '../analytics/D3SpectrumPreview.vue'
import { fetchDatasetSpectrumPreview } from '../../api/datasets'
import {
  PIPELINE_PALETTE_ITEMS,
  usePipelineWizardStore,
  type VisualPipelineBlockKind,
} from '../../stores/pipelineWizard'
import { useDatasetsStore } from '../../stores/datasets'

const wizard = usePipelineWizardStore()
const { selectedDatasetId, visualStageBlocks } = storeToRefs(wizard)
const datasets = useDatasetsStore()

const mz = ref<number[]>([])
const intensity = ref<number[]>([])
const spectrumLoading = ref(false)
const spectrumError = ref<string | null>(null)

onMounted(() => {
  if (!datasets.items.length && !datasets.loading) {
    void datasets.load()
  }
})

watch(
  selectedDatasetId,
  async (id) => {
    spectrumError.value = null
    if (!id?.trim()) {
      mz.value = []
      intensity.value = []
      return
    }
    spectrumLoading.value = true
    try {
      const data = await fetchDatasetSpectrumPreview(id.trim())
      mz.value = data.mz
      intensity.value = data.intensity
    } catch (e) {
      spectrumError.value = e instanceof Error ? e.message : String(e)
      mz.value = []
      intensity.value = []
    } finally {
      spectrumLoading.value = false
    }
  },
  { immediate: true },
)

type DndPayload =
  | { source: 'palette'; kind: VisualPipelineBlockKind }
  | { source: 'canvas'; index: number }

function parsePayload(e: DragEvent): DndPayload | null {
  const raw = e.dataTransfer?.getData('application/json')
  if (!raw) return null
  try {
    return JSON.parse(raw) as DndPayload
  } catch {
    return null
  }
}

function onPaletteDragStart(e: DragEvent, kind: VisualPipelineBlockKind) {
  if (!e.dataTransfer) return
  e.dataTransfer.setData(
    'application/json',
    JSON.stringify({ source: 'palette', kind } satisfies DndPayload),
  )
  e.dataTransfer.effectAllowed = 'copy'
}

function onCanvasDragStart(e: DragEvent, index: number) {
  if (!e.dataTransfer) return
  e.dataTransfer.setData(
    'application/json',
    JSON.stringify({ source: 'canvas', index } satisfies DndPayload),
  )
  e.dataTransfer.effectAllowed = 'move'
}

function onCanvasDragOver(e: DragEvent) {
  e.preventDefault()
  if (e.dataTransfer) e.dataTransfer.dropEffect = 'move'
}

/** Inserir antes do bloco no índice `dropIndex`; se a lista está vazia, usa 0. */
function onDropAt(e: DragEvent, dropIndex: number) {
  e.preventDefault()
  e.stopPropagation()
  const p = parsePayload(e)
  if (!p) return
  if (p.source === 'palette') {
    wizard.addVisualBlock(p.kind, dropIndex)
    return
  }
  wizard.moveVisualBlock(p.index, dropIndex)
}

function onDropAppend(e: DragEvent) {
  e.preventDefault()
  const p = parsePayload(e)
  if (!p) return
  const n = visualStageBlocks.value.length
  if (p.source === 'palette') {
    wizard.addVisualBlock(p.kind, n)
    return
  }
  wizard.moveVisualBlock(p.index, n)
}

function blockLabel(kind: VisualPipelineBlockKind) {
  return PIPELINE_PALETTE_ITEMS.find((x) => x.id === kind)?.label ?? kind
}
</script>

<template>
  <div class="visual">
    <section class="visual__spectrum" aria-label="Pré-visualização espectral">
      <div class="visual__spectrum-head">
        <h2 class="visual__h2">Espectro (m/z × intensidade)</h2>
        <label class="field">
          <span class="field__label">Dataset</span>
          <select v-model="selectedDatasetId" class="field__input">
            <option value="" disabled>Escolher um dataset…</option>
            <option v-for="d in datasets.sortedItems" :key="d.id" :value="d.id">
              {{ d.name }}
            </option>
          </select>
        </label>
      </div>
      <p v-if="spectrumError" class="visual__err">{{ spectrumError }}</p>
      <p v-else-if="spectrumLoading" class="visual__muted">A carregar pré-visualização…</p>
      <D3SpectrumPreview :mz="mz" :intensity="intensity" />
    </section>

    <div class="visual__main">
      <aside class="visual__palette" aria-label="Paleta de blocos">
        <h3 class="visual__h3">Paleta</h3>
        <p class="visual__muted">Arraste para o canvas.</p>
        <ul class="visual__palette-list">
          <li
            v-for="item in PIPELINE_PALETTE_ITEMS"
            :key="item.id"
            class="visual__palette-item"
            draggable="true"
            @dragstart="onPaletteDragStart($event, item.id)"
          >
            {{ item.label }}
          </li>
        </ul>
      </aside>

      <section class="visual__canvas-wrap" aria-label="Canvas do pipeline">
        <h3 class="visual__h3">Canvas</h3>
        <p class="visual__hint">
          Ordem de cima para baixo corresponde ao array
          <code>stages</code> no rascunho.
        </p>
        <ul class="visual__canvas" role="list">
          <li
            v-if="!visualStageBlocks.length"
            class="visual__empty visual__dropzone"
            @dragover="onCanvasDragOver"
            @drop="onDropAt($event, 0)"
          >
            Largue blocos aqui para começar.
          </li>
          <li
            v-for="(block, index) in visualStageBlocks"
            :key="block.id"
            class="visual__block"
            draggable="true"
            @dragstart="onCanvasDragStart($event, index)"
            @dragover="onCanvasDragOver"
            @drop="onDropAt($event, index)"
          >
            <span class="visual__block-grip" aria-hidden="true">⋮⋮</span>
            <span class="visual__block-label">{{ blockLabel(block.kind) }}</span>
            <code class="visual__block-code">{{ block.kind }}</code>
            <button
              type="button"
              class="visual__remove"
              @click="wizard.removeVisualBlock(block.id)"
            >
              Remover
            </button>
          </li>
          <li
            v-if="visualStageBlocks.length"
            class="visual__dropzone visual__dropzone--tail"
            @dragover="onCanvasDragOver"
            @drop="onDropAppend"
          >
            Área de largar no fim da pipeline
          </li>
        </ul>
      </section>
    </div>

    <div class="visual__actions">
      <button type="button" class="btn btn--ghost" @click="wizard.reset">Repor rascunho</button>
    </div>

    <details class="visual__draft">
      <summary>Rascunho JSON (inclui <code>stages</code>)</summary>
      <pre class="visual__pre">{{ JSON.stringify(wizard.buildExperimentDraft(), null, 2) }}</pre>
    </details>
  </div>
</template>

<style scoped>
.visual {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.visual__spectrum {
  padding: 16px;
  border-radius: 12px;
  border: 1px solid var(--shell-border, #27272f);
  background: #0c0f14;
}

.visual__spectrum-head {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
}

.visual__h2 {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
}

.visual__h3 {
  margin: 0 0 6px;
  font-size: 0.9rem;
  font-weight: 600;
}

.visual__main {
  display: grid;
  grid-template-columns: minmax(160px, 200px) 1fr;
  gap: 20px;
  align-items: start;
}

@media (max-width: 640px) {
  .visual__main {
    grid-template-columns: 1fr;
  }
}

.visual__palette {
  padding: 14px;
  border-radius: 12px;
  border: 1px solid var(--shell-border, #27272f);
  background: #0f1419;
}

.visual__palette-list {
  list-style: none;
  margin: 10px 0 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.visual__palette-item {
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px dashed rgba(168, 85, 247, 0.45);
  background: rgba(124, 58, 237, 0.08);
  font-size: 0.8rem;
  font-weight: 500;
  cursor: grab;
  user-select: none;
}

.visual__palette-item:active {
  cursor: grabbing;
}

.visual__canvas-wrap {
  padding: 14px;
  border-radius: 12px;
  border: 1px solid var(--shell-border, #27272f);
  background: #0f1419;
  min-height: 120px;
}

.visual__hint {
  margin: 0 0 12px;
  font-size: 0.78rem;
  opacity: 0.65;
  line-height: 1.45;
}

.visual__canvas {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.visual__empty,
.visual__dropzone {
  padding: 20px;
  border-radius: 10px;
  border: 1px dashed #374151;
  font-size: 0.85rem;
  opacity: 0.75;
  text-align: center;
}

.visual__dropzone--tail {
  padding: 12px;
  font-size: 0.78rem;
}

.visual__block {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid #374151;
  background: #111827;
  cursor: grab;
  user-select: none;
}

.visual__block:active {
  cursor: grabbing;
}

.visual__block-grip {
  opacity: 0.35;
  font-size: 0.75rem;
  letter-spacing: -2px;
}

.visual__block-label {
  font-weight: 600;
  font-size: 0.85rem;
}

.visual__block-code {
  font-size: 0.72rem;
  opacity: 0.65;
  padding: 2px 6px;
  border-radius: 4px;
  background: #080a0f;
}

.visual__remove {
  margin-left: auto;
  font-size: 0.75rem;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #7f1d1d;
  background: #451a1a;
  color: #fecaca;
  cursor: pointer;
  font-family: inherit;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 200px;
}

.field__label {
  font-size: 0.72rem;
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

.visual__muted {
  margin: 0 0 8px;
  font-size: 0.8rem;
  opacity: 0.65;
}

.visual__err {
  margin: 0 0 8px;
  font-size: 0.8rem;
  color: #f87171;
}

.visual__actions {
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
  font-family: inherit;
}

.btn--ghost {
  background: #1f2937;
  color: #e5e7eb;
  border: 1px solid #374151;
}

.visual__draft {
  font-size: 0.8rem;
}

.visual__pre {
  margin: 8px 0 0;
  padding: 12px;
  border-radius: 8px;
  background: #080a0f;
  border: 1px solid #27272f;
  overflow: auto;
  max-height: 220px;
  font-size: 0.7rem;
  line-height: 1.4;
}
</style>
