import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsObject,
  IsOptional,
  Validate,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { validatePipelineSpecPayload } from '../../pipeline/pipeline-spec.validation';

@ValidatorConstraint({ name: 'appendRevisionSpec', async: false })
class PipelineSpecObjectConstraint implements ValidatorConstraintInterface {
  validate(spec: unknown): boolean {
    return validatePipelineSpecPayload(spec);
  }
  defaultMessage(): string {
    return 'spec inválido para PipelineSpec (stages, kind, params — ver NODE_CONTRACT / OpenAPI).';
  }
}

@ValidatorConstraint({ name: 'appendRevisionState', async: false })
class OptionalStateObjectConstraint implements ValidatorConstraintInterface {
  validate(state: unknown): boolean {
    if (state === undefined || state === null) return true;
    return (
      typeof state === 'object' &&
      state !== null &&
      !Array.isArray(state)
    );
  }
}

export class AppendPipelineRevisionDto {
  @ApiProperty({
    description:
      'Definição imutável do pipeline (estágios). Validada antes de gravar a revisão.',
  })
  @Validate(PipelineSpecObjectConstraint)
  @IsObject()
  @Type(() => Object)
  spec!: Record<string, unknown>;

  @ApiPropertyOptional({
    description:
      'Estado opcional persistido nesta revisão (append-only; não substitui revisões anteriores).',
  })
  @IsOptional()
  @Validate(OptionalStateObjectConstraint)
  @IsObject()
  @Type(() => Object)
  state?: Record<string, unknown>;
}
