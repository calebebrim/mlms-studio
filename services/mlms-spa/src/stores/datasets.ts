import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import * as api from '../api/datasets'

export type DatasetDraft = {
  name: string
  description: string
  tagsText: string
}

function tagsToText(tags: string[]) {
  return tags.join(', ')
}

function parseTags(text: string): string[] {
  return text
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
}

export const useDatasetsStore = defineStore('datasets', () => {
  const items = ref<api.Dataset[]>([])
  const loading = ref(false)
  const savingId = ref<string | null>(null)
  const uploading = ref(false)
  const error = ref<string | null>(null)

  const sortedItems = computed(() => {
    return [...items.value].sort((a, b) =>
      a.updated_at < b.updated_at ? 1 : a.updated_at > b.updated_at ? -1 : 0,
    )
  })

  function draftFrom(d: api.Dataset): DatasetDraft {
    return {
      name: d.name,
      description: d.description ?? '',
      tagsText: tagsToText(d.tags),
    }
  }

  async function load() {
    loading.value = true
    error.value = null
    try {
      items.value = await api.listDatasets()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erro ao carregar datasets'
    } finally {
      loading.value = false
    }
  }

  async function upload(file: File, fields: { name: string; description: string; tags: string }) {
    uploading.value = true
    error.value = null
    try {
      const fd = new FormData()
      fd.append('file', file)
      if (fields.name.trim()) fd.append('name', fields.name.trim())
      if (fields.description.trim()) fd.append('description', fields.description.trim())
      if (fields.tags.trim()) fd.append('tags', fields.tags.trim())
      await api.uploadDataset(fd)
      await load()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Falha no envio'
      throw e
    } finally {
      uploading.value = false
    }
  }

  async function save(id: string, draft: DatasetDraft) {
    savingId.value = id
    error.value = null
    try {
      const tags = parseTags(draft.tagsText)
      await api.updateDataset(id, {
        name: draft.name.trim(),
        description: draft.description.trim().length ? draft.description.trim() : null,
        tags,
      })
      await load()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Falha ao guardar'
      throw e
    } finally {
      savingId.value = null
    }
  }

  async function remove(id: string) {
    savingId.value = id
    error.value = null
    try {
      await api.deleteDataset(id)
      await load()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Falha ao remover'
      throw e
    } finally {
      savingId.value = null
    }
  }

  return {
    items,
    sortedItems,
    loading,
    savingId,
    uploading,
    error,
    draftFrom,
    load,
    upload,
    save,
    remove,
  }
})
