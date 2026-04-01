/** Valores aceites pelo `mlms-worker` no MVP; alinhar com `docs/api/openapi-v0.yaml` e NODE_CONTRACT. Inclui `mlms.experiment_snapshot` (pipeline persistido). Novos tipos: domínio + worker (ver SOF-28). */
export const MVP_JOB_TYPES = [
  'mlms.echo',
  'mlms.pipeline_stub',
  'mlms.genetic_algorithm',
  'mlms.watchpoints',
  'mlms.mlp',
  'mlms.random_forest',
  'mlms.experiment_snapshot',
] as const;

export type MvpJobType = (typeof MVP_JOB_TYPES)[number];
