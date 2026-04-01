import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  Validate,
  ValidateIf,
} from 'class-validator';
import { MVP_JOB_TYPES, type MvpJobType } from '../job-types';
import { CreateJobPayloadForTypeConstraint } from '../validators/create-job-payload.constraint';

export class CreateJobDto {
  @ApiProperty({ enum: MVP_JOB_TYPES, example: 'mlms.pipeline_stub' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  @IsIn(MVP_JOB_TYPES)
  job_type!: MvpJobType;

  @ApiPropertyOptional({
    description:
      'Semântica por `job_type` (ver NODE_CONTRACT / OpenAPI). Obrigatório para `mlms.genetic_algorithm` (incl. `ga_profile` / `outer_iterations` opcionais, SOF-53), `mlms.watchpoints`, `mlms.mlp` e `mlms.random_forest`; opcional para `mlms.echo` e `mlms.pipeline_stub`; para `mlms.experiment_snapshot`, `payload` inline OU `experiment_id`+`pipeline_revision_id` (XOR).',
  })
  @Validate(CreateJobPayloadForTypeConstraint)
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({
    description:
      'Com `pipeline_revision_id`, carrega snapshot imutável de `/experiments` (XOR com `payload` para mlms.experiment_snapshot).',
  })
  @ValidateIf((o) => o.job_type === 'mlms.experiment_snapshot')
  @IsOptional()
  @IsUUID()
  experiment_id?: string;

  @ApiPropertyOptional({
    description:
      'Revisão append-only; o BFF monta `{ schema_version, payload }` validado antes do worker.',
  })
  @ValidateIf((o) => o.job_type === 'mlms.experiment_snapshot')
  @IsOptional()
  @IsUUID()
  pipeline_revision_id?: string;

  @ApiPropertyOptional({
    description: 'Correlaciona com o worker quando o BFF reencaminha.',
  })
  @IsOptional()
  @IsUUID()
  job_id?: string;

  @ApiPropertyOptional({
    description:
      'Alternativa ao header Idempotency-Key (MVP: aceito, sem persistência de dedupe).',
    maxLength: 256,
  })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  idempotency_key?: string;
}
