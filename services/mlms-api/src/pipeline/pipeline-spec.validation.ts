/** Versão do envelope `{ schema_version, payload }` enviado ao worker para `mlms.experiment_snapshot`. */
export const PIPELINE_SPEC_SCHEMA_VERSION = 1 as const;

const MAX_EXPERIMENT_STAGES = 32;
const MAX_STAGE_KIND_LEN = 64;
const MAX_EXPERIMENT_ID_LEN = 256;

export function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * Corpo lógico do pipeline (estágios) + metadados opcionais.
 * `execution_state` é permitido quando o BFF junta estado persistido à spec para o worker.
 */
export function validatePipelineSpecPayload(payload: unknown): boolean {
  if (!isPlainObject(payload)) return false;
  const expState = payload.execution_state;
  if (
    expState !== undefined &&
    expState !== null &&
    !isPlainObject(expState)
  ) {
    return false;
  }
  const ver = payload.snapshot_version;
  if (ver !== undefined && ver !== 1) return false;
  const expId = payload.experiment_id;
  if (expId !== undefined) {
    if (typeof expId !== 'string' || expId.length > MAX_EXPERIMENT_ID_LEN)
      return false;
  }
  const stages = payload.stages;
  if (!Array.isArray(stages)) return false;
  if (stages.length === 0 || stages.length > MAX_EXPERIMENT_STAGES) return false;
  for (const st of stages) {
    if (!isPlainObject(st)) return false;
    const kind = st.kind;
    if (typeof kind !== 'string') return false;
    const kt = kind.trim();
    if (kt.length === 0 || kt.length > MAX_STAGE_KIND_LEN) return false;
    const pr = st.params;
    if (pr !== undefined && pr !== null && !isPlainObject(pr)) return false;
  }
  return true;
}

/** Payload inline no `CreateJobDto`: envelope `{ schema_version, payload }` ou só o interior. */
export function validateExperimentJobInlinePayload(payload: unknown): boolean {
  if (!isPlainObject(payload)) return false;
  const looksEnvelope =
    payload.schema_version !== undefined ||
    (Object.prototype.hasOwnProperty.call(payload, 'payload') &&
      payload.payload !== undefined);
  if (looksEnvelope) {
    if (payload.schema_version !== undefined && payload.schema_version !== 1) {
      return false;
    }
    const inner = payload.payload;
    if (!isPlainObject(inner)) return false;
    return validatePipelineSpecPayload(inner);
  }
  return validatePipelineSpecPayload(payload);
}

export interface WorkerExperimentSnapshotBody {
  schema_version: number;
  payload: Record<string, unknown>;
}

export function toWorkerExperimentEnvelope(
  inline: Record<string, unknown>,
): WorkerExperimentSnapshotBody {
  if (
    typeof inline.schema_version === 'number' &&
    isPlainObject(inline.payload)
  ) {
    return {
      schema_version: inline.schema_version,
      payload: { ...inline.payload },
    };
  }
  return {
    schema_version: PIPELINE_SPEC_SCHEMA_VERSION,
    payload: { ...inline },
  };
}

export function validateWorkerExperimentSnapshotBody(
  body: WorkerExperimentSnapshotBody,
): boolean {
  if (body.schema_version !== 1) return false;
  return validatePipelineSpecPayload(body.payload);
}

export function revisionIndexForExperiment(
  revisions: { experiment_id: string; revision_index: number }[],
  experimentId: string,
): number {
  let max = -1;
  for (const r of revisions) {
    if (r.experiment_id === experimentId && r.revision_index > max) {
      max = r.revision_index;
    }
  }
  return max + 1;
}
