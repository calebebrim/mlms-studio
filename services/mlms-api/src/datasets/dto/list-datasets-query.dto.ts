import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class ListDatasetsQueryDto {
  @ApiPropertyOptional({
    description: 'Filtrar por etiqueta (comparação case-insensitive).',
  })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsOptional()
  @IsString()
  @MaxLength(128)
  tag?: string;

  @ApiPropertyOptional({
    description: 'Incluir registos com eliminação lógica.',
  })
  @Transform(({ value }) => {
    if (value === 'true' || value === true) return true;
    if (value === 'false' || value === false) return false;
    return undefined;
  })
  @IsOptional()
  @IsBoolean()
  include_deleted?: boolean;
}
