import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ExperimentsService } from '../experiments/experiments.service';
import {
  toWorkerExperimentEnvelope,
  validateWorkerExperimentSnapshotBody,
} from '../pipeline/pipeline-spec.validation';
import { WorkerClientService } from '../worker/worker-client.service';
import { CreateJobDto } from './dto/create-job.dto';
import type { JobResponseDto } from './job-response.dto';

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function problem(
  status: HttpStatus,
  title: string,
  detail: string,
  extra?: Record<string, unknown>,
): never {
  throw new HttpException(
    {
      type: 'about:blank',
      title,
      status,
      detail,
      ...extra,
    },
    status,
  );
}

@Injectable()
export class JobsService {
  private readonly log = new Logger(JobsService.name);

  constructor(
    private readonly worker: WorkerClientService,
    private readonly experiments: ExperimentsService,
  ) {}

  async createJob(dto: CreateJobDto): Promise<JobResponseDto> {
    const workerPayload = await this.resolveWorkerPayload(dto);
    let status: number;
    let json: unknown;
    try {
      ({ status, json } = await this.worker.postJob({
        job_type: dto.job_type,
        job_id: dto.job_id,
        payload: workerPayload,
      }));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.startsWith('worker_unreachable:')) {
        this.log.warn(`Worker unreachable: ${msg}`);
        problem(
          HttpStatus.SERVICE_UNAVAILABLE,
          'Service Unavailable',
          'Não foi possível contactar o mlms-worker.',
        );
      }
      throw e;
    }

    if (status === HttpStatus.UNAUTHORIZED) {
      problem(
        HttpStatus.BAD_GATEWAY,
        'Bad Gateway',
        'O worker rejeitou a autenticação serviço-a-serviço (token interno).',
      );
    }

    if (status === HttpStatus.PAYLOAD_TOO_LARGE) {
      problem(
        HttpStatus.PAYLOAD_TOO_LARGE,
        'Payload Too Large',
        'Corpo do pedido excede o limite aceite pelo worker.',
      );
    }

    if (status === HttpStatus.BAD_REQUEST) {
      problem(
        HttpStatus.BAD_REQUEST,
        'Bad Request',
        'Corpo JSON inválido ou campos não suportados para o worker.',
      );
    }

    if (status === HttpStatus.UNPROCESSABLE_ENTITY && isRecord(json)) {
      const err = json.error;
      const detail =
        isRecord(err) && typeof err.message === 'string'
          ? err.message
          : 'Pedido rejeitado pelo worker.';
      const code =
        isRecord(err) && typeof err.code === 'string' ? err.code : undefined;
      problem(HttpStatus.UNPROCESSABLE_ENTITY, 'Unprocessable Entity', detail, {
        ...(code ? { code } : {}),
      });
    }

    if (status !== HttpStatus.OK || !isRecord(json)) {
      this.log.warn(`Resposta inesperada do worker: status=${status}`);
      problem(
        HttpStatus.BAD_GATEWAY,
        'Bad Gateway',
        'Resposta inesperada do mlms-worker.',
      );
    }

    const workerStatus = String(json.status ?? '').toLowerCase();
    if (workerStatus !== 'completed') {
      problem(
        HttpStatus.BAD_GATEWAY,
        'Bad Gateway',
        'Estado de job inesperado no worker.',
      );
    }

    if (typeof json.job_id !== 'string') {
      problem(
        HttpStatus.BAD_GATEWAY,
        'Bad Gateway',
        'Resposta do worker sem job_id.',
      );
    }
    const id = json.job_id;

    const now = new Date().toISOString();
    const result =
      json.result !== undefined && json.result !== null && isRecord(json.result)
        ? (json.result as Record<string, unknown>)
        : null;

    const out: JobResponseDto = {
      id,
      status: 'completed',
      job_type: dto.job_type.trim(),
      payload: workerPayload ?? null,
      result,
      error: null,
      created_at: now,
      updated_at: now,
    };
    return out;
  }

  private async resolveWorkerPayload(
    dto: CreateJobDto,
  ): Promise<Record<string, unknown> | undefined> {
    if (dto.job_type !== 'mlms.experiment_snapshot') {
      return dto.payload;
    }
    const exp = dto.experiment_id?.trim();
    const rev = dto.pipeline_revision_id?.trim();
    let envelope: ReturnType<typeof toWorkerExperimentEnvelope>;
    if (exp && rev) {
      envelope = await this.experiments.resolveWorkerSnapshot(exp, rev);
    } else if (dto.payload && typeof dto.payload === 'object' && !Array.isArray(dto.payload)) {
      envelope = toWorkerExperimentEnvelope(dto.payload);
    } else {
      problem(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Unprocessable Entity',
        'mlms.experiment_snapshot requer revisão persistida ou payload inline.',
      );
    }
    if (!validateWorkerExperimentSnapshotBody(envelope)) {
      problem(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Unprocessable Entity',
        'Snapshot de experimento inválido após montagem (schema_version / PipelineSpec).',
      );
    }
    return {
      schema_version: envelope.schema_version,
      payload: envelope.payload,
    };
  }
}
