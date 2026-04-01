import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateDatasetDto {
  @ApiProperty({ example: 'Cohort A — MALDI batch 2024' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(512)
  name!: string;

  @ApiPropertyOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsOptional()
  @IsString()
  @MaxLength(8192)
  description?: string;

  @ApiPropertyOptional({
    description: 'Etiquetas livres (normalizadas para minúsculas na persistência).',
    example: ['proteomics', 'internal'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MaxLength(128, { each: true })
  tags?: string[];

  @ApiPropertyOptional({
    description: 'Metadados JSON arbitrários (sem processamento pesado no BFF).',
  })
  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;

  @ApiProperty({
    description:
      'Referência ao artefacto sob o volume configurado em MLMS_DATA_VOLUME_PREFIX (caminho relativo, sem `..`).',
    example: 'studies/cohort-a/run-001',
  })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(2048)
  storage_ref!: string;
}
