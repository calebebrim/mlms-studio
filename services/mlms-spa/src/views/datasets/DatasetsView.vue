<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import type { DatasetDraft } from '../../stores/datasets'
import { useDatasetsStore } from '../../stores/datasets'

const store = useDatasetsStore()

const upload = reactive({
  name: '',
  description: '',
  tags: '',
  file: null as File | null,
})

const drafts = reactive<Record<string, DatasetDraft>>({})
const fileInput = ref<HTMLInputElement | null>(null)

function onFilePick(e: Event) {
  const input = e.target as HTMLInputElement
  const f = input.files?.[0]
  upload.file = f ?? null
  if (f && !upload.name.trim()) upload.name = f.name.replace(/\.[^.]+$/, '') || f.name
}

function formatBytes(n: unknown) {
  if (typeof n !== 'number' || !Number.isFinite(n)) return '—'
  if (n < 1024) return `${n} B`
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KiB`
  return `${(n / (1024 * 1024)).toFixed(1)} MiB`
}

function syncDrafts() {
  for (const d of store.items) {
    if (!drafts[d.id]) drafts[d.id] = store.draftFrom(d)
  }
  const ids = new Set(store.items.map((d) => d.id))
  for (const k of Object.keys(drafts)) {
    if (!ids.has(k)) delete drafts[k]
  }
}

watch(
  () => store.items,
  () => syncDrafts(),
  { deep: true, immediate: true },
)

async function submitUpload() {
  if (!upload.file) return
  await store.upload(upload.file, {
    name: upload.name,
    description: upload.description,
    tags: upload.tags,
  })
  upload.file = null
  upload.name = ''
  upload.description = ''
  upload.tags = ''
  if (fileInput.value) fileInput.value.value = ''
}

async function onSave(id: string) {
  const d = drafts[id]
  if (!d) return
  await store.save(id, d)
}

async function onRemove(id: string) {
  if (!confirm('Remover este dataset? (eliminação lógica no servidor)')) return
  await store.remove(id)
  delete drafts[id]
}

onMounted(async () => {
  await store.load()
  syncDrafts()
})
</script>

<template>
  <div class="ds">
    <header class="ds__head">
      <h1 class="ds__h">Datasets</h1>
      <p class="ds__sub">
        Lista, carregamento de ficheiros, nome e etiquetas via BFF
        <code class="ds__code">/api/v1/datasets</code>.
      </p>
    </header>

    <div v-if="store.error" class="ds__alert" role="alert">
      {{ store.error }}
    </div>

    <section class="ds__panel" aria-labelledby="upload-title">
      <h2 id="upload-title" class="ds__panel-title">Carregar</h2>
      <div class="ds__grid">
        <label class="ds__field">
          <span class="ds__label">Ficheiro</span>
          <input
            ref="fileInput"
            class="ds__input"
            type="file"
            @change="onFilePick"
          />
        </label>
        <label class="ds__field">
          <span class="ds__label">Nome</span>
          <input
            v-model="upload.name"
            class="ds__input"
            type="text"
            placeholder="Nome a mostrar"
            autocomplete="off"
          />
        </label>
        <label class="ds__field ds__field--wide">
          <span class="ds__label">Descrição</span>
          <textarea
            v-model="upload.description"
            class="ds__textarea"
            rows="2"
            placeholder="Opcional"
          />
        </label>
        <label class="ds__field ds__field--wide">
          <span class="ds__label">Tags</span>
          <input
            v-model="upload.tags"
            class="ds__input"
            type="text"
            placeholder="Separadas por vírgula"
            autocomplete="off"
          />
        </label>
      </div>
      <div class="ds__actions">
        <button
          type="button"
          class="ds__btn ds__btn--primary"
          :disabled="!upload.file || store.uploading"
          @click="submitUpload"
        >
          {{ store.uploading ? 'A enviar…' : 'Enviar dataset' }}
        </button>
      </div>
    </section>

    <section class="ds__panel" aria-labelledby="list-title">
      <div class="ds__panel-row">
        <h2 id="list-title" class="ds__panel-title">Registos</h2>
        <button
          type="button"
          class="ds__btn ds__btn--ghost"
          :disabled="store.loading"
          @click="store.load"
        >
          {{ store.loading ? 'A atualizar…' : 'Atualizar' }}
        </button>
      </div>

      <p v-if="!store.loading && store.sortedItems.length === 0" class="ds__empty">
        Nenhum dataset. Envie um ficheiro acima ou crie via API JSON (<code class="ds__code">POST /datasets</code>).
      </p>

      <ul v-else class="ds__list">
        <li
          v-for="d in store.sortedItems"
          :key="d.id"
          class="ds__card"
        >
          <template v-if="drafts[d.id]">
          <div class="ds__card-head">
            <span class="ds__id">{{ d.id.slice(0, 8) }}…</span>
            <span class="ds__meta-inline">
              {{ formatBytes(d.metadata.byte_size) }}
              <span v-if="typeof d.metadata.content_type === 'string'" class="ds__mime">
                · {{ d.metadata.content_type }}
              </span>
            </span>
          </div>
          <label class="ds__field">
            <span class="ds__label">Nome</span>
            <input
              v-model="drafts[d.id]!.name"
              class="ds__input"
              type="text"
              :disabled="store.savingId === d.id"
            />
          </label>
          <label class="ds__field">
            <span class="ds__label">Descrição</span>
            <textarea
              v-model="drafts[d.id]!.description"
              class="ds__textarea"
              rows="2"
              :disabled="store.savingId === d.id"
            />
          </label>
          <label class="ds__field">
            <span class="ds__label">Tags</span>
            <input
              v-model="drafts[d.id]!.tagsText"
              class="ds__input"
              type="text"
              placeholder="vírgulas"
              :disabled="store.savingId === d.id"
            />
          </label>
          <p class="ds__storage" title="storage_ref">
            {{ d.storage_ref }}
          </p>
          <div class="ds__card-actions">
            <button
              type="button"
              class="ds__btn ds__btn--primary"
              :disabled="store.savingId === d.id || !drafts[d.id]!.name.trim()"
              @click="onSave(d.id)"
            >
              {{ store.savingId === d.id ? 'A guardar…' : 'Guardar' }}
            </button>
            <button
              type="button"
              class="ds__btn ds__btn--danger"
              :disabled="store.savingId === d.id"
              @click="onRemove(d.id)"
            >
              Remover
            </button>
          </div>
          </template>
        </li>
      </ul>
    </section>
  </div>
</template>

<style scoped>
.ds {
  flex: 1;
  padding: 24px 28px 40px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  max-width: 56rem;
}

.ds__head {
  max-width: 48rem;
}

.ds__h {
  margin: 0 0 6px;
  font-size: 1.35rem;
  font-weight: 600;
  letter-spacing: -0.02em;
}

.ds__sub {
  margin: 0;
  font-size: 0.9rem;
  opacity: 0.72;
  line-height: 1.55;
}

.ds__code {
  font-size: 0.8em;
  padding: 2px 6px;
  border-radius: 6px;
  background: #1f2937;
  border: 1px solid var(--shell-border, #27272f);
}

.ds__alert {
  padding: 12px 14px;
  border-radius: 10px;
  background: rgba(239, 68, 68, 0.12);
  border: 1px solid rgba(248, 113, 113, 0.35);
  color: #fecaca;
  font-size: 0.875rem;
}

.ds__panel {
  padding: 20px;
  border-radius: 12px;
  border: 1px solid var(--shell-border, #27272f);
  background: #111827;
}

.ds__panel-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.ds__panel-title {
  margin: 0 0 16px;
  font-size: 1rem;
  font-weight: 600;
}

.ds__panel-row .ds__panel-title {
  margin-bottom: 0;
}

.ds__grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px 16px;
}

@media (max-width: 640px) {
  .ds__grid {
    grid-template-columns: 1fr;
  }
}

.ds__field--wide {
  grid-column: 1 / -1;
}

.ds__field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.ds__label {
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  opacity: 0.55;
}

.ds__input,
.ds__textarea {
  font: inherit;
  font-size: 0.875rem;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid var(--shell-border, #27272f);
  background: #0b0c10;
  color: var(--shell-fg, #e5e7eb);
}

.ds__input:focus,
.ds__textarea:focus {
  outline: none;
  border-color: rgba(168, 85, 247, 0.55);
  box-shadow: 0 0 0 1px rgba(168, 85, 247, 0.25);
}

.ds__input:disabled,
.ds__textarea:disabled {
  opacity: 0.55;
}

.ds__actions {
  margin-top: 16px;
  display: flex;
  gap: 10px;
}

.ds__btn {
  font: inherit;
  font-size: 0.875rem;
  font-weight: 500;
  padding: 10px 16px;
  border-radius: 8px;
  border: 1px solid var(--shell-border, #27272f);
  background: #1f2937;
  color: var(--shell-fg, #e5e7eb);
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease;
}

.ds__btn:hover:not(:disabled) {
  background: #374151;
}

.ds__btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.ds__btn--primary {
  background: linear-gradient(135deg, rgba(124, 58, 237, 0.35), rgba(168, 85, 247, 0.2));
  border-color: rgba(168, 85, 247, 0.45);
  color: #f3e8ff;
}

.ds__btn--primary:hover:not(:disabled) {
  background: linear-gradient(135deg, rgba(124, 58, 237, 0.45), rgba(168, 85, 247, 0.28));
}

.ds__btn--ghost {
  background: transparent;
}

.ds__btn--danger {
  border-color: rgba(248, 113, 113, 0.35);
  color: #fecaca;
  background: rgba(127, 29, 29, 0.2);
}

.ds__btn--danger:hover:not(:disabled) {
  background: rgba(127, 29, 29, 0.35);
}

.ds__empty {
  margin: 0;
  font-size: 0.875rem;
  opacity: 0.6;
  line-height: 1.5;
}

.ds__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.ds__card {
  padding: 16px;
  border-radius: 10px;
  border: 1px dashed rgba(168, 85, 247, 0.22);
  background: rgba(15, 23, 42, 0.65);
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.ds__card-head {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 8px;
  font-size: 0.8rem;
  opacity: 0.75;
}

.ds__id {
  font-family: ui-monospace, monospace;
}

.ds__meta-inline {
  font-size: 0.8rem;
}

.ds__mime {
  opacity: 0.85;
}

.ds__storage {
  margin: 0;
  font-size: 0.75rem;
  font-family: ui-monospace, monospace;
  opacity: 0.45;
  word-break: break-all;
}

.ds__card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
</style>
