import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MVP_JOB_TYPES } from './job-types';

/** Códigos `error.code` do worker documentados em NODE_CONTRACT (422). */
export const WORKER_JOB_ERROR_CODES = [
  'invalid_job_type',
  'unknown_job_type',
  'invalid_genetic_algorithm_payload',
  'invalid_watchpoints_payload',
  'invalid_mlp_payload',
  'invalid_rf_payload',
  'invalid_experiment_snapshot',
] as const;

export class JobErrorDto {
  @ApiProperty({
    example: 'unknown_job_type',
    enum: WORKER_JOB_ERROR_CODES,
    description:
      'Códigos alinhados ao `mlms-worker` (ver services/mlms-worker/docs/NODE_CONTRACT.md).',
  })
  code!: string;

  @ApiProperty()
  message!: string;
}

export class JobResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    enum: ['queued', 'running', 'completed', 'failed', 'cancelled'],
  })
  status!: 'queued' | 'running' | 'completed' | 'failed' | 'cancelled';

  @ApiProperty({ enum: MVP_JOB_TYPES })
  job_type!: string;

  @ApiPropertyOptional({ nullable: true })
  payload?: Record<string, unknown> | null;

  @ApiPropertyOptional({ nullable: true })
  result?: Record<string, unknown> | null;

  @ApiPropertyOptional({ type: JobErrorDto, nullable: true })
  error?: JobErrorDto | null;

  @ApiProperty({ format: 'date-time' })
  created_at!: string;

  @ApiProperty({ format: 'date-time' })
  updated_at!: string;
}
