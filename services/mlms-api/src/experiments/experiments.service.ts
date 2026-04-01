import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { ExperimentRecord, PipelineRevisionRecord } from './experiment-records';
import { ExperimentResponseDto } from './experiment-response.dto';
import { ExperimentsRepository } from './experiments.repository';
import type { AppendPipelineRevisionDto } from './dto/append-pipeline-revision.dto';
import type { CreateExperimentDto } from './dto/create-experiment.dto';
import { PipelineRevisionDetailDto } from './pipeline-revision-response.dto';
import {
  PIPELINE_SPEC_SCHEMA_VERSION,
  revisionIndexForExperiment,
  validatePipelineSpecPayload,
  type WorkerExperimentSnapshotBody,
} from '../pipeline/pipeline-spec.validation';

@Injectable()
export class ExperimentsService {
  constructor(private readonly repo: ExperimentsRepository) {}

  private summarize(
    r: PipelineRevisionRecord,
  ): ExperimentResponseDto['revisions'][number] {
    return {
      id: r.id,
      revision_index: r.revision_index,
      schema_version: r.schema_version,
      created_at: r.created_at,
    };
  }

  async create(dto: CreateExperimentDto): Promise<ExperimentResponseDto> {
    const now = new Date().toISOString();
    const row: ExperimentRecord = {
      id: randomUUID(),
      name: dto.name?.trim()?.length ? dto.name.trim().slice(0, 512) : null,
      created_at: now,
      updated_at: now,
    };
    const store = await this.repo.loadStore();
    store.experiments.push(row);
    await this.repo.saveStore(store);
    return {
      id: row.id,
      name: row.name,
      revisions: [],
      created_at: row.created_at,
      updated_at: row.updated_at,
    };
  }

  async appendRevision(
    experimentId: string,
    dto: AppendPipelineRevisionDto,
  ): Promise<PipelineRevisionDetailDto> {
    if (!validatePipelineSpecPayload(dto.spec)) {
      throw new ConflictException('spec inválido após validação');
    }
    const store = await this.repo.loadStore();
    const exp = store.experiments.find((e) => e.id === experimentId);
    if (!exp) {
      throw new NotFoundException(`Experiment ${experimentId} not found`);
    }
    const nextIdx = revisionIndexForExperiment(store.revisions, experimentId);
    const now = new Date().toISOString();
    const rev: PipelineRevisionRecord = {
      id: randomUUID(),
      experiment_id: experimentId,
      revision_index: nextIdx,
      schema_version: PIPELINE_SPEC_SCHEMA_VERSION,
      spec: { ...dto.spec },
      state:
        dto.state != null &&
        typeof dto.state === 'object' &&
        !Array.isArray(dto.state) &&
        Object.keys(dto.state).length > 0
          ? { ...dto.state }
          : null,
      created_at: now,
    };
    store.revisions.push(rev);
    exp.updated_at = now;
    await this.repo.saveStore(store);
    return this.revisionToDetail(rev);
  }

  async getById(experimentId: string): Promise<ExperimentResponseDto> {
    const store = await this.repo.loadStore();
    const exp = store.experiments.find((e) => e.id === experimentId);
    if (!exp) {
      throw new NotFoundException(`Experiment ${experimentId} not found`);
    }
    const revs = store.revisions
      .filter((r) => r.experiment_id === experimentId)
      .sort((a, b) => a.revision_index - b.revision_index)
      .map((r) => this.summarize(r));
    return {
      id: exp.id,
      name: exp.name,
      revisions: revs,
      created_at: exp.created_at,
      updated_at: exp.updated_at,
    };
  }

  async getRevision(
    experimentId: string,
    revisionId: string,
  ): Promise<PipelineRevisionDetailDto> {
    const store = await this.repo.loadStore();
    const exp = store.experiments.find((e) => e.id === experimentId);
    if (!exp) {
      throw new NotFoundException(`Experiment ${experimentId} not found`);
    }
    const rev = store.revisions.find(
      (r) => r.id === revisionId && r.experiment_id === experimentId,
    );
    if (!rev) {
      throw new NotFoundException(
        `Revision ${revisionId} not found for experiment ${experimentId}`,
      );
    }
    return this.revisionToDetail(rev);
  }

  /** Snapshot imutável para `POST /v1/jobs` (`mlms.experiment_snapshot`). */
  async resolveWorkerSnapshot(
    experimentId: string,
    revisionId: string,
  ): Promise<WorkerExperimentSnapshotBody> {
    const rev = await this.getRevision(experimentId, revisionId);
    const inner: Record<string, unknown> = { ...rev.spec };
    if (rev.state !== null && Object.keys(rev.state).length > 0) {
      inner.execution_state = rev.state;
    }
    return {
      schema_version: rev.schema_version,
      payload: inner,
    };
  }

  private revisionToDetail(r: PipelineRevisionRecord): PipelineRevisionDetailDto {
    return {
      id: r.id,
      experiment_id: r.experiment_id,
      revision_index: r.revision_index,
      schema_version: r.schema_version,
      spec: { ...r.spec },
      state: r.state === null ? null : { ...r.state },
      created_at: r.created_at,
    };
  }
}
