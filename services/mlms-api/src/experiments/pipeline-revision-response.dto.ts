import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PipelineRevisionDetailDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  experiment_id!: string;

  @ApiProperty()
  revision_index!: number;

  @ApiProperty()
  schema_version!: number;

  @ApiProperty({ type: 'object', additionalProperties: true })
  spec!: Record<string, unknown>;

  @ApiPropertyOptional({ type: 'object', additionalProperties: true, nullable: true })
  state!: Record<string, unknown> | null;

  @ApiProperty({ format: 'date-time' })
  created_at!: string;
}
