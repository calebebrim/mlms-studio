import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateDatasetDto } from './dto/create-dataset.dto';

describe('CreateDatasetDto — validação class-validator', () => {
  async function validateBody(body: Record<string, unknown>) {
    const dto = plainToInstance(CreateDatasetDto, body);
    return validate(dto);
  }

  it('rejeita nome vazio', async () => {
    const errors = await validateBody({
      name: '   ',
      storage_ref: 'studies/a',
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('rejeita ausência de storage_ref', async () => {
    const errors = await validateBody({
      name: 'Dataset A',
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('aceita corpo mínimo válido', async () => {
    const errors = await validateBody({
      name: 'Cohort A',
      storage_ref: 'studies/cohort-a/run-001',
    });
    expect(errors).toHaveLength(0);
  });

  it('rejeita tag não string no array', async () => {
    const errors = await validateBody({
      name: 'X',
      storage_ref: 'r',
      tags: ['ok', 1 as unknown as string],
    });
    expect(errors.length).toBeGreaterThan(0);
  });
});
