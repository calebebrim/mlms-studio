import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class JobErrorDto {
  @ApiProperty({ example: 'unknown_job_type' })
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

  @ApiProperty()
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
