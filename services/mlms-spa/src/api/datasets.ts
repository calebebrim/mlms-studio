/**
 * Cliente datasets alinhado a `docs/api/openapi-v0.yaml` (`/api/v1/datasets`, `/datasets/upload`).
 */
const base = () => (import.meta.env.VITE_MLMS_API_BASE ?? '').replace(/\/$/, '')

export type Dataset = {
  id: string
  name: string
  description: string | null
  tags: string[]
  metadata: Record<string, unknown>
  storage_ref: string
  deleted_at: string | null
  created_at: string
  updated_at: string
}

export type UpdateDatasetBody = {
  name?: string
  description?: string | null
  tags?: string[]
  metadata?: Record<string, unknown>
  storage_ref?: string
}

async function errorMessage(r: Response): Promise<string> {
  const text = await r.text()
  try {
    const j = JSON.parse(text) as {
      detail?: string
      message?: string | string[]
      title?: string
    }
    if (Array.isArray(j.message)) return j.message.join('; ')
    return j.detail ?? j.message ?? j.title ?? text
  } catch {
    return text || r.statusText
  }
}

export async function listDatasets(params?: { tag?: string }): Promise<Dataset[]> {
  const q = new URLSearchParams()
  if (params?.tag?.trim()) q.set('tag', params.tag.trim())
  const qs = q.toString()
  const url = qs ? `${base()}/datasets?${qs}` : `${base()}/datasets`
  const r = await fetch(url)
  if (!r.ok) throw new Error(await errorMessage(r))
  return r.json() as Promise<Dataset[]>
}

/** `FormData` deve incluir `file`; opcionais: `name`, `description`, `tags`, `metadata`. */
export async function uploadDataset(form: FormData): Promise<Dataset> {
  const r = await fetch(`${base()}/datasets/upload`, {
    method: 'POST',
    body: form,
  })
  if (!r.ok) throw new Error(await errorMessage(r))
  return r.json() as Promise<Dataset>
}

export async function updateDataset(
  id: string,
  body: UpdateDatasetBody,
): Promise<Dataset> {
  const r = await fetch(`${base()}/datasets/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!r.ok) throw new Error(await errorMessage(r))
  return r.json() as Promise<Dataset>
}

export async function deleteDataset(id: string): Promise<Dataset> {
  const r = await fetch(`${base()}/datasets/${id}`, { method: 'DELETE' })
  if (!r.ok) throw new Error(await errorMessage(r))
  return r.json() as Promise<Dataset>
}

export type DatasetSpectrumPreview = {
  mz: number[]
  intensity: number[]
}

/** `GET /datasets/:id/spectrum-preview` — MVP na API (curva sintética por dataset). */
export async function fetchDatasetSpectrumPreview(
  id: string,
): Promise<DatasetSpectrumPreview> {
  const r = await fetch(`${base()}/datasets/${id}/spectrum-preview`)
  if (!r.ok) throw new Error(await errorMessage(r))
  return r.json() as Promise<DatasetSpectrumPreview>
}
