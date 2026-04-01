import type { ValidationArguments } from 'class-validator';
import { ValidatorConstraint, ValidatorConstraintInterface } from 'class-validator';
import { validateExperimentJobInlinePayload } from '../../pipeline/pipeline-spec.validation';
import type { MvpJobType } from '../job-types';

const U32_MAX = 0xffff_ffff;

/** Alinhado a `mlms-worker` (`MAX_GA_PROFILE_LEN`, SOF-53 / OpenAPI). */
const MAX_GA_PROFILE_LEN = 64;

/** Alinhado a `mlms-worker` (`MAX_SPECTRUM_POINTS`). */
const MAX_SPECTRUM_POINTS = 65_536;

/** Alinhado a entrada MLP no worker (`mlms.mlp` / `model.mlp_stub`). */
const MAX_MLP_INPUT_LEN = 8192;

const MLP_PAYLOAD_KEYS = new Set(['input', 'out_dim', 'seed']);

const RF_PAYLOAD_KEYS = new Set(['input', 'n_trees', 'n_classes', 'seed']);

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function isPositiveU32JsonNumber(n: unknown): boolean {
  return (
    typeof n === 'number' &&
    Number.isFinite(n) &&
    Number.isInteger(n) &&
    n > 0 &&
    n <= U32_MAX
  );
}

function isOptionalRate01(n: unknown): boolean {
  if (n === undefined) return true;
  return typeof n === 'number' && Number.isFinite(n) && n >= 0 && n <= 1;
}

function isFiniteNumber(n: unknown): n is number {
  return typeof n === 'number' && Number.isFinite(n);
}

function optionalGaProfileOk(v: unknown): boolean {
  if (v === undefined || v === null) return true;
  if (typeof v !== 'string') return false;
  const t = v.trim();
  if (t.length === 0) return false;
  return t.length <= MAX_GA_PROFILE_LEN;
}

/** Inteiro JSON estrito (como `Value::as_u64` no worker), > 0 e ≤ u32::MAX. */
function optionalOuterIterationsOk(v: unknown): boolean {
  if (v === undefined || v === null) return true;
  return isPositiveU32JsonNumber(v);
}

/** `mz` / `intensity` obrigatórios; monotonia estrita após ordenação só no worker. */
function spectrumMzIntensityOk(payload: Record<string, unknown>): boolean {
  const mz = payload.mz;
  const intensity = payload.intensity;
  if (!Array.isArray(mz) || !Array.isArray(intensity)) return false;
  if (mz.length === 0 || intensity.length === 0) return false;
  if (mz.length !== intensity.length) return false;
  if (mz.length > MAX_SPECTRUM_POINTS) return false;
  return mz.every(isFiniteNumber) && intensity.every(isFiniteNumber);
}

@ValidatorConstraint({ name: 'createJobPayloadForType', async: false })
export class CreateJobPayloadForTypeConstraint
  implements ValidatorConstraintInterface
{
  validate(payload: unknown, args: ValidationArguments): boolean {
    const jobType = (args.object as { job_type: MvpJobType }).job_type;
    switch (jobType) {
      case 'mlms.echo':
        return (
          payload === undefined ||
          payload === null ||
          isPlainObject(payload)
        );
      case 'mlms.pipeline_stub':
        return (
          payload === undefined ||
          payload === null ||
          isPlainObject(payload)
        );
      case 'mlms.genetic_algorithm':
        return this.geneticAlgorithmOk(payload);
      case 'mlms.watchpoints':
        return this.watchpointsOk(payload);
      case 'mlms.mlp':
        return this.mlpOk(payload);
      case 'mlms.random_forest':
        return this.rfOk(payload);
      case 'mlms.experiment_snapshot': {
        const o = args.object as {
          job_type: MvpJobType;
          payload?: unknown;
          experiment_id?: string;
          pipeline_revision_id?: string;
        };
        const exp = o.experiment_id?.trim();
        const rev = o.pipeline_revision_id?.trim();
        const hasRef = !!(exp && rev);
        const hasPay =
          payload !== undefined &&
          payload !== null &&
          typeof payload === 'object' &&
          !Array.isArray(payload);
        if (hasRef && hasPay) return false;
        if (!hasRef && !hasPay) return false;
        if (hasRef) return true;
        return validateExperimentJobInlinePayload(payload);
      }
      default:
        return true;
    }
  }

  defaultMessage(): string {
    return 'Payload inválido para job_type (alinhar com NODE_CONTRACT / docs/api/openapi-v0.yaml).';
  }

  private geneticAlgorithmOk(payload: unknown): boolean {
    if (!isPlainObject(payload)) return false;
    if (!isPositiveU32JsonNumber(payload.population_size)) return false;
    if (!isPositiveU32JsonNumber(payload.generations)) return false;
    if (!isOptionalRate01(payload.crossover_rate)) return false;
    if (!isOptionalRate01(payload.mutation_rate)) return false;
    if (!optionalGaProfileOk(payload.ga_profile)) return false;
    if (!optionalOuterIterationsOk(payload.outer_iterations)) return false;
    return spectrumMzIntensityOk(payload);
  }

  private watchpointsOk(payload: unknown): boolean {
    if (!isPlainObject(payload)) return false;
    const ref = payload.spectrum_ref;
    if (typeof ref !== 'string' || ref.trim() === '') return false;
    const positions = payload.watchpoint_positions;
    if (!Array.isArray(positions) || positions.length === 0) return false;
    if (
      !positions.every(
        (x) => typeof x === 'number' && Number.isFinite(x),
      )
    ) {
      return false;
    }
    return spectrumMzIntensityOk(payload);
  }

  /** Chaves estritas: só `input`, `out_dim`, `seed` (NODE_CONTRACT § `mlms.mlp`). */
  private mlpOk(payload: unknown): boolean {
    if (!isPlainObject(payload)) return false;
    for (const k of Object.keys(payload)) {
      if (!MLP_PAYLOAD_KEYS.has(k)) return false;
    }
    const input = payload.input;
    if (!Array.isArray(input) || input.length === 0) return false;
    if (input.length > MAX_MLP_INPUT_LEN) return false;
    if (!input.every((x) => typeof x === 'number' && Number.isFinite(x))) {
      return false;
    }
    if (
      payload.out_dim !== undefined &&
      payload.out_dim !== null &&
      !isPositiveU32JsonNumber(payload.out_dim)
    ) {
      return false;
    }
    if (
      payload.out_dim !== undefined &&
      payload.out_dim !== null &&
      typeof payload.out_dim === 'number' &&
      payload.out_dim > 256
    ) {
      return false;
    }
    if (payload.seed !== undefined && payload.seed !== null) {
      if (
        typeof payload.seed !== 'number' ||
        !Number.isInteger(payload.seed) ||
        payload.seed < 0
      ) {
        return false;
      }
    }
    return true;
  }

  /** Chaves estritas: `input`, `n_trees`, `n_classes`, `seed` (NODE_CONTRACT § `mlms.random_forest`). */
  private rfOk(payload: unknown): boolean {
    if (!isPlainObject(payload)) return false;
    for (const k of Object.keys(payload)) {
      if (!RF_PAYLOAD_KEYS.has(k)) return false;
    }
    const input = payload.input;
    if (!Array.isArray(input) || input.length === 0) return false;
    if (input.length > MAX_MLP_INPUT_LEN) return false;
    if (!input.every((x) => typeof x === 'number' && Number.isFinite(x))) {
      return false;
    }
    if (
      payload.n_trees !== undefined &&
      payload.n_trees !== null &&
      !isPositiveU32JsonNumber(payload.n_trees)
    ) {
      return false;
    }
    if (
      payload.n_trees !== undefined &&
      payload.n_trees !== null &&
      typeof payload.n_trees === 'number' &&
      payload.n_trees > 512
    ) {
      return false;
    }
    if (
      payload.n_classes !== undefined &&
      payload.n_classes !== null &&
      (typeof payload.n_classes !== 'number' ||
        !Number.isInteger(payload.n_classes) ||
        payload.n_classes < 2 ||
        payload.n_classes > 64)
    ) {
      return false;
    }
    if (payload.seed !== undefined && payload.seed !== null) {
      if (
        typeof payload.seed !== 'number' ||
        !Number.isInteger(payload.seed) ||
        payload.seed < 0
      ) {
        return false;
      }
    }
    return true;
  }

}
