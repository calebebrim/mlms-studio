import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PipelineRevisionSummaryDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  revision_index!: number;

  @ApiProperty()
  schema_version!: number;

  @ApiProperty({ format: 'date-time' })
  created_at!: string;
}

export class ExperimentResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiPropertyOptional({ nullable: true })
  name!: string | null;

  @ApiProperty({ type: [PipelineRevisionSummaryDto] })
  revisions!: PipelineRevisionSummaryDto[];

  @ApiProperty({ format: 'date-time' })
  created_at!: string;

  @ApiProperty({ format: 'date-time' })
  updated_at!: string;
}
