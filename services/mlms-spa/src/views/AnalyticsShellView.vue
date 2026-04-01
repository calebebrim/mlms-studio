<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useAnalyticsShellStore } from '../stores/analyticsShell'
import { useWDataStore } from '../stores/wData'
import { useRealtimeChannel } from '../composables/useRealtimeChannel'
import D3JobTimeline from '../components/analytics/D3JobTimeline.vue'
import D3SpectrumPreview from '../components/analytics/D3SpectrumPreview.vue'
import ThreePipelineStage from '../components/analytics/ThreePipelineStage.vue'

const store = useAnalyticsShellStore()
const wData = useWDataStore()
const { health, healthError, jobLoading, jobError, jobHistory, lastPipelineStage, realtimeLog } =
  storeToRefs(store)
const {
  samples: wSamples,
  selectedIndex: wSelectedIndex,
  selectedSample,
  ingestLoading,
  ingestError,
  lastIngestResult,
} = storeToRefs(wData)

const { status: wsStatus, lastError: wsError } = useRealtimeChannel()

const lastRealtime = computed(() => realtimeLog.value[realtimeLog.value.length - 1] ?? null)

onMounted(() => {
  store.refreshHealth()
})
</script>

<template>
  <div class="shell">
    <header class="shell__bar">
      <div class="shell__brand">
        <span class="shell__title">MLMS Studio</span>
        <span class="shell__sub">Shell analítico · Vue 3</span>
      </div>
      <div class="shell__status">
        <span v-if="health" class="pill pill--ok">Worker {{ health.version }}</span>
        <span v-else-if="healthError" class="pill pill--err">{{ healthError }}</span>
        <span v-else class="pill">Health…</span>
        <span class="pill" :data-state="wsStatus">WS: {{ wsStatus }}</span>
        <span v-if="wsError" class="pill pill--warn">{{ wsError }}</span>
      </div>
    </header>

    <section class="shell__actions">
      <button
        type="button"
        class="btn"
        :disabled="jobLoading"
        @click="store.runPipelineStub('default')"
      >
        {{ jobLoading ? 'Job…' : 'Executar mlms.pipeline_stub' }}
      </button>
      <button type="button" class="btn btn--ghost" :disabled="jobLoading" @click="store.refreshHealth()">
        Atualizar health
      </button>
      <p v-if="jobError" class="shell__err">{{ jobError }}</p>
    </section>

    <main class="shell__grid">
      <article class="panel panel--wide">
        <h2 class="panel__h">Amostras (<code>w_data</code>)</h2>
        <p class="panel__p">
          Estado mínimo alinhado ao GUI legacy: ficheiros, eixo m/z e intensidades por amostra.
          A submissão ao worker usa <code>postJob</code> com <code>mlms.ingest_w_data</code> quando o BFF
          expuser o tipo.
        </p>
        <div class="wdata__toolbar">
          <button type="button" class="btn btn--ghost" @click="wData.loadDemoSamples()">
            Carregar demo
          </button>
          <button
            type="button"
            class="btn btn--ghost"
            :disabled="wSamples.length === 0"
            @click="wData.clearSamples()"
          >
            Limpar
          </button>
          <button
            type="button"
            class="btn"
            :disabled="ingestLoading || wSamples.length === 0"
            @click="wData.submitIngestJob()"
          >
            {{ ingestLoading ? 'A enviar…' : 'Submeter ingestão (worker)' }}
          </button>
        </div>
        <p v-if="ingestError" class="shell__err">{{ ingestError }}</p>
        <p v-else-if="lastIngestResult" class="shell__ok">
          Ingestão aceite — job <code>{{ lastIngestResult.job_id }}</code>
        </p>
        <div class="wdata__split">
          <ul v-if="wSamples.length" class="wdata__list" role="listbox" aria-label="Amostras">
            <li
              v-for="(s, i) in wSamples"
              :key="`${s.file}-${i}`"
              role="option"
              :aria-selected="i === wSelectedIndex"
              :class="['wdata__item', { 'wdata__item--active': i === wSelectedIndex }]"
              @click="wData.selectSample(i)"
            >
              {{ s.file }}
            </li>
          </ul>
          <p v-else class="muted wdata__empty">Sem amostras — use «Carregar demo» ou aguarde ingestão via API.</p>
          <div class="wdata__chart">
            <h3 class="wdata__subh">Pré-visualização 1D (D3)</h3>
            <D3SpectrumPreview
              :mz="selectedSample?.mz ?? []"
              :intensity="selectedSample?.all ?? []"
            />
          </div>
        </div>
      </article>
      <article class="panel">
        <h2 class="panel__h">Série (D3) — histórico de jobs</h2>
        <p class="panel__p">Atualiza quando o fluxo conclui chamadas à API (não é demo isolada).</p>
        <D3JobTimeline :points="jobHistory" />
      </article>
      <article class="panel">
        <h2 class="panel__h">Estágio (Three.js)</h2>
        <p class="panel__p">Cor derivada do último <code>result.stage</code> devolvido pelo worker.</p>
        <ThreePipelineStage :stage="lastPipelineStage" />
      </article>
    </main>

    <footer class="shell__footer">
      <span class="shell__footer-label">Tempo real (última mensagem)</span>
      <code v-if="lastRealtime" class="shell__code">{{ lastRealtime.raw }}</code>
      <span v-else class="muted">Configure <code>VITE_REALTIME_WS_URL</code> no BFF Node.</span>
    </footer>
  </div>
</template>

<style scoped>
.shell {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  background: var(--shell-bg, #0b0c10);
  color: var(--shell-fg, #e5e7eb);
}

.shell__bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--shell-border, #27272f);
}

.shell__brand {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.shell__title {
  font-weight: 600;
  font-size: 1.1rem;
  letter-spacing: -0.02em;
}

.shell__sub {
  font-size: 0.8rem;
  opacity: 0.65;
}

.shell__status {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.pill {
  font-size: 0.75rem;
  padding: 4px 10px;
  border-radius: 999px;
  background: #1f2937;
  border: 1px solid #374151;
}

.pill--ok {
  border-color: #059669;
  color: #6ee7b7;
}

.pill--err {
  border-color: #b91c1c;
  color: #fca5a5;
}

.pill--warn {
  border-color: #b45309;
  color: #fcd34d;
}

.shell__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  padding: 12px 20px;
  border-bottom: 1px solid var(--shell-border, #27272f);
}

.btn {
  cursor: pointer;
  border: none;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: 0.875rem;
  font-weight: 500;
  background: linear-gradient(135deg, #7c3aed, #a855f7);
  color: #fff;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn--ghost {
  background: #1f2937;
  color: #e5e7eb;
  border: 1px solid #374151;
}

.shell__err {
  margin: 0;
  font-size: 0.85rem;
  color: #fca5a5;
}

.shell__grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
  padding: 16px 20px 24px;
}

.panel--wide {
  grid-column: 1 / -1;
}

.wdata__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 10px;
}

.wdata__split {
  display: grid;
  grid-template-columns: minmax(160px, 220px) 1fr;
  gap: 16px;
  align-items: start;
}

@media (max-width: 720px) {
  .wdata__split {
    grid-template-columns: 1fr;
  }
}

.wdata__list {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--shell-border, #27272f);
  border-radius: 8px;
  max-height: 240px;
  overflow: auto;
}

.wdata__item {
  padding: 8px 10px;
  font-size: 0.8rem;
  cursor: pointer;
  border-bottom: 1px solid #1f2937;
  word-break: break-all;
}

.wdata__item:last-child {
  border-bottom: none;
}

.wdata__item:hover {
  background: #1f2937;
}

.wdata__item--active {
  background: #312e81;
  color: #e0e7ff;
}

.wdata__empty {
  margin: 0;
  align-self: center;
}

.wdata__subh {
  margin: 0 0 8px;
  font-size: 0.85rem;
  font-weight: 600;
  opacity: 0.85;
}

.wdata__chart {
  min-width: 0;
}

.shell__ok {
  margin: 0 0 8px;
  font-size: 0.85rem;
  color: #6ee7b7;
}

.panel {
  background: #111827;
  border: 1px solid var(--shell-border, #27272f);
  border-radius: 12px;
  padding: 16px;
}

.panel__h {
  margin: 0 0 6px;
  font-size: 1rem;
  font-weight: 600;
}

.panel__p {
  margin: 0 0 12px;
  font-size: 0.8rem;
  opacity: 0.7;
  line-height: 1.4;
}

.shell__footer {
  padding: 12px 20px 20px;
  border-top: 1px solid var(--shell-border, #27272f);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.shell__footer-label {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  opacity: 0.5;
}

.shell__code {
  font-size: 0.8rem;
  word-break: break-all;
  background: #0f172a;
  padding: 8px 10px;
  border-radius: 6px;
  border: 1px solid #1e293b;
}

.muted {
  font-size: 0.85rem;
  opacity: 0.55;
}
</style>
