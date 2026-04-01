/**
 * Cliente HTTP alinhado a `docs/api/openapi-v0.yaml` (BFF `/api/v1/…`).
 * O worker Rust permanece atrás do Node; não expor `/mlms-worker` ao browser em fluxo normal.
 */
const base = () => (import.meta.env.VITE_MLMS_API_BASE ?? '').replace(/\/$/, '')

export type HealthResponse = {
  status: string
  service: string
  version: string
}

export type JobSubmitBody = {
  job_id?: string
  job_type: string
  payload?: Record<string, unknown>
}

export type JobOkResponse = {
  job_id: string
  status: 'completed'
  result: Record<string, unknown>
}

export type JobErrResponse = {
  job_id: string
  status: 'failed'
  error: { code: string; message: string }
}

/** Reservado para ingestão alinhada a `w_data`; activar no worker/BFF antes de produção. */
export const MLMS_JOB_TYPE_INGEST_W_DATA = 'mlms.ingest_w_data' as const

export type IngestWDataJobPayload = {
  files: string[]
  all: number[][]
  mz: number[][]
}

export async function getHealth(): Promise<HealthResponse> {
  const r = await fetch(`${base()}/health`)
  if (!r.ok) throw new Error(`health ${r.status}`)
  return r.json() as Promise<HealthResponse>
}

export async function postJob(body: JobSubmitBody): Promise<JobOkResponse | JobErrResponse> {
  const r = await fetch(`${base()}/jobs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = (await r.json()) as JobOkResponse | JobErrResponse
  if (!r.ok && r.status !== 422) {
    throw new Error(`jobs ${r.status}: ${JSON.stringify(data)}`)
  }
  return data
}

export function postIngestWData(
  payload: IngestWDataJobPayload,
): Promise<JobOkResponse | JobErrResponse> {
  return postJob({
    job_type: MLMS_JOB_TYPE_INGEST_W_DATA,
    payload: {
      files: payload.files,
      all: payload.all,
      mz: payload.mz,
    },
  })
}
