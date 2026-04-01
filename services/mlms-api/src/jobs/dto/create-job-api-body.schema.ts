import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Esquemas usados só em `@ApiBody` (OpenAPI `CreateJobRequest` + discriminador).
 * A validação em runtime continua em {@link CreateJobDto} e {@link CreateJobPayloadForTypeConstraint}.
 */
export class CreateEchoJobRequestSchema {
  @ApiProperty({ enum: ['mlms.echo'] })
  job_type!: 'mlms.echo';

  @ApiPropertyOptional({
    type: 'object',
    additionalProperties: true,
    description: 'Opcional; ver `EchoJobPayload` em docs/api/openapi-v0.yaml.',
  })
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({
    maxLength: 256,
    description: 'Alternativa ao header Idempotency-Key.',
  })
  idempotency_key?: string;
}

export class PipelineStubJobPayloadSchema {
  @ApiPropertyOptional({
    description:
      'Ecoado em `result.stage`; omissão → `"default"` no worker (NODE_CONTRACT).',
  })
  stage?: string;
}

export class CreatePipelineStubJobRequestSchema {
  @ApiProperty({ enum: ['mlms.pipeline_stub'] })
  job_type!: 'mlms.pipeline_stub';

  @ApiPropertyOptional({ type: PipelineStubJobPayloadSchema })
  payload?: PipelineStubJobPayloadSchema;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}

export class GeneticAlgorithmJobPayloadSchema {
  @ApiProperty({ minimum: 1, description: 'Inteiro JSON > 0 (u32 no worker).' })
  population_size!: number;

  @ApiProperty({ minimum: 1, description: 'Inteiro JSON > 0 (u32 no worker).' })
  generations!: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 1, default: 0.8 })
  crossover_rate?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 1, default: 0.01 })
  mutation_rate?: number;

  @ApiPropertyOptional({
    minLength: 1,
    maxLength: 64,
    description:
      'Perfil nomeado de GA (SOF-53); validado e ecoado; sem efeito no stub numérico MVP.',
  })
  ga_profile?: string;

  @ApiPropertyOptional({
    minimum: 1,
    description:
      'Loop externo (conceito `cicles` em ga_fr.m); inteiro > 0; ecoado, sem execução real MVP.',
  })
  outer_iterations?: number;

  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 65536,
    description: 'Eixo m/z; monotonia estrita após ordenação no worker.',
  })
  mz!: number[];

  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 65536,
    description: 'Mesmo comprimento que `mz`.',
  })
  intensity!: number[];
}

export class CreateGeneticAlgorithmJobRequestSchema {
  @ApiProperty({ enum: ['mlms.genetic_algorithm'] })
  job_type!: 'mlms.genetic_algorithm';

  @ApiProperty({ type: GeneticAlgorithmJobPayloadSchema })
  payload!: GeneticAlgorithmJobPayloadSchema;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}

export class WatchpointsJobPayloadSchema {
  @ApiProperty({ minLength: 1 })
  spectrum_ref!: string;

  @ApiProperty({ type: 'array', items: { type: 'number' }, minItems: 1 })
  watchpoint_positions!: number[];

  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 65536,
  })
  mz!: number[];

  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 65536,
  })
  intensity!: number[];
}

export class CreateWatchpointsJobRequestSchema {
  @ApiProperty({ enum: ['mlms.watchpoints'] })
  job_type!: 'mlms.watchpoints';

  @ApiProperty({ type: WatchpointsJobPayloadSchema })
  payload!: WatchpointsJobPayloadSchema;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}

/** Alinhado a NODE_CONTRACT § `mlms.mlp` e ao estágio `model.mlp_stub` (uma camada densa + `tanh`). Apenas estas chaves são aceites no worker. */
export class MlpJobPayloadSchema {
  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 8192,
    description: 'Vector de entrada; números finitos.',
  })
  input!: number[];

  @ApiPropertyOptional({
    minimum: 1,
    maximum: 256,
    default: 4,
    description: 'Dimensão de saída; inteiro JSON 1–256; padrão 4 no worker.',
  })
  out_dim?: number;

  @ApiPropertyOptional({
    minimum: 0,
    maximum: 9007199254740991,
    default: 42,
    description: 'Semente u64 em JSON (inteiro não negativo); padrão 42.',
  })
  seed?: number;
}

export class CreateMlpJobRequestSchema {
  @ApiProperty({ enum: ['mlms.mlp'] })
  job_type!: 'mlms.mlp';

  @ApiProperty({ type: MlpJobPayloadSchema })
  payload!: MlpJobPayloadSchema;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}

/** Alinhado ao job de topo `mlms.random_forest` no worker (`run_standalone_rf` / `model.rf_stub`). */
export class RandomForestJobPayloadSchema {
  @ApiProperty({
    type: 'array',
    items: { type: 'number' },
    minItems: 1,
    maxItems: 8192,
    description: 'Vector de features de uma amostra; números finitos.',
  })
  input!: number[];

  @ApiPropertyOptional({
    minimum: 1,
    maximum: 512,
    default: 10,
    description: 'Número de árvores sintéticas; inteiro JSON 1–512; padrão 10 no worker.',
  })
  n_trees?: number;

  @ApiPropertyOptional({
    minimum: 2,
    maximum: 64,
    default: 2,
    description: 'Classes para voto determinístico; inteiro JSON 2–64; padrão 2.',
  })
  n_classes?: number;

  @ApiPropertyOptional({
    minimum: 0,
    default: 42,
    description: 'Semente u64 em JSON (inteiro não negativo); padrão 42.',
  })
  seed?: number;
}

export class CreateRandomForestJobRequestSchema {
  @ApiProperty({ enum: ['mlms.random_forest'] })
  job_type!: 'mlms.random_forest';

  @ApiProperty({ type: RandomForestJobPayloadSchema })
  payload!: RandomForestJobPayloadSchema;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}

export class CreateExperimentSnapshotJobRequestSchema {
  @ApiProperty({ enum: ['mlms.experiment_snapshot'] })
  job_type!: 'mlms.experiment_snapshot';

  @ApiPropertyOptional({
    format: 'uuid',
    description:
      'Obrigatório junto com `pipeline_revision_id` quando não há `payload` inline.',
  })
  experiment_id?: string;

  @ApiPropertyOptional({
    format: 'uuid',
    description: 'Revisão append-only em `/experiments`.',
  })
  pipeline_revision_id?: string;

  @ApiPropertyOptional({
    type: 'object',
    additionalProperties: true,
    description:
      'Inline: `ExperimentSnapshotJobPayload` ou envelope `{ schema_version, payload }` (OpenAPI `ExperimentSnapshotRequestPayload`). XOR com `experiment_id`+`pipeline_revision_id`.',
  })
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({ format: 'uuid' })
  job_id?: string;

  @ApiPropertyOptional({ maxLength: 256 })
  idempotency_key?: string;
}
