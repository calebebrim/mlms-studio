import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DatasetResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiPropertyOptional({ nullable: true })
  description!: string | null;

  @ApiProperty({ type: [String] })
  tags!: string[];

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
  })
  metadata!: Record<string, unknown>;

  @ApiProperty({
    description: 'Caminho lógico validado relativamente ao volume.',
  })
  storage_ref!: string;

  @ApiPropertyOptional({
    nullable: true,
    description: 'Preenchido quando o registo foi eliminado logicamente.',
  })
  deleted_at!: string | null;

  @ApiProperty({ format: 'date-time' })
  created_at!: string;

  @ApiProperty({ format: 'date-time' })
  updated_at!: string;
}
