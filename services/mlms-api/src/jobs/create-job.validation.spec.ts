import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateJobDto } from './dto/create-job.dto';

describe('CreateJobDto — mlms.random_forest (rejeição 422 / class-validator)', () => {
  async function validateBody(body: Record<string, unknown>) {
    const dto = plainToInstance(CreateJobDto, body);
    return validate(dto);
  }

  it('rejeita chave desconhecida no payload', async () => {
    const errors = await validateBody({
      job_type: 'mlms.random_forest',
      payload: { input: [1], extra: 1 },
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('rejeita payload sem input', async () => {
    const errors = await validateBody({
      job_type: 'mlms.random_forest',
      payload: { n_trees: 4 },
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('rejeita n_trees fora do intervalo do worker', async () => {
    const errors = await validateBody({
      job_type: 'mlms.random_forest',
      payload: { input: [1.0], n_trees: 600 },
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('aceita payload alinhado ao parse_rf_standalone_payload', async () => {
    const errors = await validateBody({
      job_type: 'mlms.random_forest',
      payload: {
        input: [1.0, -0.5, 2.0],
        n_trees: 8,
        n_classes: 3,
        seed: 7,
      },
    });
    expect(errors).toHaveLength(0);
  });
});
