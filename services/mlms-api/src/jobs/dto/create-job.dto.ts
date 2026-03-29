import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsObject, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateJobDto {
  @ApiProperty({ example: 'mlms.pipeline_stub' })
  @IsString()
  @MaxLength(128)
  job_type!: string;

  @ApiPropertyOptional({
    description: 'Parâmetros opacos; semântica depende de job_type.',
  })
  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;

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
