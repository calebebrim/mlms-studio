import { ApiProperty } from '@nestjs/swagger';

export class DatasetSpectrumPreviewDto {
  @ApiProperty({ type: [Number], description: 'Valores m/z (eixo X)' })
  mz!: number[];

  @ApiProperty({ type: [Number], description: 'Intensidades alinhadas a mz' })
  intensity!: number[];
}
