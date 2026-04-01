/**
 * Subconjunto mínimo do `w_data` legacy (MATLAB): lista de amostras com
 * ficheiro, eixo m/z e intensidades (`all`), por amostra.
 */
export type WDataSample = {
  file: string
  mz: number[]
  /** Intensidades 1D (equivalente a `w_data.all{i}` no GUI legacy). */
  all: number[]
}

/** Corpo `payload` acordado para `job_type` `mlms.ingest_w_data` (quando o BFF/worker expuser). */
export type WDataIngestPayload = {
  files: string[]
  all: number[][]
  mz: number[][]
}
