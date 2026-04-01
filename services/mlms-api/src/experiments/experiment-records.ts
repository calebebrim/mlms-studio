export interface ExperimentRecord {
  id: string;
  name: string | null;
  created_at: string;
  updated_at: string;
}

/** Revisão append-only: spec + estado opcional; nunca actualizar in-place. */
export interface PipelineRevisionRecord {
  id: string;
  experiment_id: string;
  revision_index: number;
  /** Versão do esquema da spec (igual a `schema_version` do envelope do worker). */
  schema_version: number;
  spec: Record<string, unknown>;
  state: Record<string, unknown> | null;
  created_at: string;
}

export interface ExperimentsStoreFile {
  experiments: ExperimentRecord[];
  revisions: PipelineRevisionRecord[];
}
