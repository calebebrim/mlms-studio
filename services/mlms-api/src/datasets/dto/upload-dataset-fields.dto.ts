import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

/** Campos multipart para `POST /datasets/upload` (além de `file`). */
export class UploadDatasetFieldsDto {
  @ApiPropertyOptional({ maxLength: 512 })
  @IsOptional()
  @IsString()
  @MaxLength(512)
  name?: string;

  @ApiPropertyOptional({ maxLength: 8192 })
  @IsOptional()
  @IsString()
  @MaxLength(8192)
  description?: string;

  @ApiPropertyOptional({
    description: 'Etiquetas separadas por vírgula (normalizadas como em create).',
  })
  @IsOptional()
  @IsString()
  @MaxLength(4096)
  tags?: string;

  /**
   * JSON opcional (object) fundido em `metadata` juntamente com campos técnicos
   * (`original_filename`, `byte_size`, `content_type`).
   */
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(65536)
  metadata?: string;
}
