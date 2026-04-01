import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type { DatasetRecord } from './dataset-record';
import { DatasetResponseDto } from './dataset-response.dto';
import { DatasetsRepository } from './datasets.repository';
import type { CreateDatasetDto } from './dto/create-dataset.dto';
import type { ListDatasetsQueryDto } from './dto/list-datasets-query.dto';
import type { UpdateDatasetDto } from './dto/update-dataset.dto';
import type { UploadDatasetFieldsDto } from './dto/upload-dataset-fields.dto';
import { VolumePathService } from './volume-path.service';

@Injectable()
export class DatasetsService {
  constructor(
    private readonly repo: DatasetsRepository,
    private readonly volumePath: VolumePathService,
  ) {}

  private normalizeTags(tags: string[] | undefined): string[] {
    if (!tags?.length) return [];
    const seen = new Set<string>();
    for (const t of tags) {
      const k = t.trim().toLowerCase();
      if (k.length) seen.add(k);
    }
    return [...seen].sort();
  }

  private safeBasename(original: string | undefined): string {
    const base = path.basename(original ?? 'upload').replace(/\0/g, '');
    const cleaned = base.replace(/[^\w.\-()+ ]/g, '_').trim();
    return (cleaned.length ? cleaned : 'upload').slice(0, 255);
  }

  private tagsFromCsv(raw?: string): string[] | undefined {
    if (!raw?.trim()) return undefined;
    const parts = raw
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    return parts.length ? this.normalizeTags(parts) : undefined;
  }

  /**
   * Grava o ficheiro em `uploads/<folder>/<filename>` sob o volume e cria o registo.
   */
  async createFromUploadedFile(
    file: Express.Multer.File | undefined,
    fields: UploadDatasetFieldsDto,
  ): Promise<DatasetResponseDto> {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Campo multipart `file` obrigatório e não vazio');
    }
    const folder = randomUUID();
    const safeName = this.safeBasename(file.originalname);
    const storageRefRaw = `uploads/${folder}/${safeName}`;
    const storage_ref = this.volumePath.normalizeAndAssertStorageRef(storageRefRaw);
    const absPath = path.join(
      this.volumePath.getVolumeRootAbs(),
      ...storage_ref.split('/'),
    );
    await fs.mkdir(path.dirname(absPath), { recursive: true });
    await fs.writeFile(absPath, file.buffer);

    const technical: Record<string, unknown> = {
      original_filename: file.originalname ?? safeName,
      byte_size: file.size,
      content_type: file.mimetype || 'application/octet-stream',
    };
    if (fields.metadata?.trim()) {
      let extra: Record<string, unknown>;
      try {
        extra = JSON.parse(fields.metadata) as Record<string, unknown>;
      } catch {
        throw new BadRequestException('metadata deve ser JSON object válido');
      }
      if (!extra || typeof extra !== 'object' || Array.isArray(extra)) {
        throw new BadRequestException('metadata deve ser um object JSON');
      }
      Object.assign(technical, extra);
    }

    const tagList = this.tagsFromCsv(fields.tags);
    const displayName = fields.name?.trim() || safeName;
    const dto: CreateDatasetDto = {
      name: displayName.slice(0, 512),
      description: fields.description?.trim()?.length
        ? fields.description.trim().slice(0, 8192)
        : undefined,
      tags: tagList,
      metadata: technical,
      storage_ref,
    };
    return this.create(dto);
  }

  private toDto(r: DatasetRecord): DatasetResponseDto {
    return {
      id: r.id,
      name: r.name,
      description: r.description,
      tags: r.tags,
      metadata: r.metadata,
      storage_ref: r.storage_ref,
      deleted_at: r.deleted_at,
      created_at: r.created_at,
      updated_at: r.updated_at,
    };
  }

  private findIndexById(rows: DatasetRecord[], id: string): number {
    return rows.findIndex((d) => d.id === id);
  }

  async create(dto: CreateDatasetDto): Promise<DatasetResponseDto> {
    const storage_ref = this.volumePath.normalizeAndAssertStorageRef(
      dto.storage_ref,
    );
    const now = new Date().toISOString();
    const row: DatasetRecord = {
      id: randomUUID(),
      name: dto.name,
      description: dto.description?.length ? dto.description : null,
      tags: this.normalizeTags(dto.tags),
      metadata:
        dto.metadata && Object.keys(dto.metadata).length
          ? { ...dto.metadata }
          : {},
      storage_ref,
      deleted_at: null,
      created_at: now,
      updated_at: now,
    };
    const all = await this.repo.loadAll();
    all.push(row);
    await this.repo.saveAll(all);
    return this.toDto(row);
  }

  async list(query: ListDatasetsQueryDto): Promise<DatasetResponseDto[]> {
    const all = await this.repo.loadAll();
    const includeDeleted = query.include_deleted === true;
    let rows = includeDeleted ? all : all.filter((d) => d.deleted_at === null);
    if (query.tag?.length) {
      const want = query.tag.trim().toLowerCase();
      rows = rows.filter((d) => d.tags.includes(want));
    }
    rows.sort((a, b) => a.created_at.localeCompare(b.created_at));
    return rows.map((r) => this.toDto(r));
  }

  async getById(id: string): Promise<DatasetResponseDto> {
    const all = await this.repo.loadAll();
    const row = all.find((d) => d.id === id);
    if (!row || row.deleted_at !== null) {
      throw new NotFoundException(`Dataset ${id} not found`);
    }
    return this.toDto(row);
  }

  /**
   * Pré-visualização espectral MVP: curva sintética determinística por id do dataset.
   * Substituir por leitura do ficheiro / amostra real quando o contrato fechar.
   */
  async spectrumPreview(id: string): Promise<{ mz: number[]; intensity: number[] }> {
    await this.getById(id);
    return this.syntheticSpectrumForDatasetId(id);
  }

  private syntheticSpectrumForDatasetId(id: string): {
    mz: number[];
    intensity: number[];
  } {
    let h = 0;
    for (let i = 0; i < id.length; i++) {
      h = (Math.imul(31, h) + id.charCodeAt(i)) >>> 0;
    }
    const points = 180;
    const mz = Array.from({ length: points }, (_, i) => 80 + i * 0.35);
    const rnd = (n: number) => {
      h = Math.imul(h ^ n, 2654435761) >>> 0;
      return h / 0xffffffff;
    };
    const peak1 = 45 + (h % 25);
    const peak2 = 100 - (h % 18);
    const intensity = mz.map((_, i) => {
      const g1 = Math.exp(-((i - peak1) ** 2) / 200);
      const g2 = Math.exp(-((i - peak2) ** 2) / 280) * 0.52;
      return g1 + g2 + rnd(i) * 0.055;
    });
    return { mz, intensity };
  }

  async update(id: string, dto: UpdateDatasetDto): Promise<DatasetResponseDto> {
    if (
      dto.name === undefined &&
      dto.description === undefined &&
      dto.tags === undefined &&
      dto.metadata === undefined &&
      dto.storage_ref === undefined
    ) {
      throw new UnprocessableEntityException(
        'At least one field must be provided for update',
      );
    }
    const all = await this.repo.loadAll();
    const idx = this.findIndexById(all, id);
    if (idx < 0 || all[idx].deleted_at !== null) {
      throw new NotFoundException(`Dataset ${id} not found`);
    }
    const cur = all[idx];
    const now = new Date().toISOString();
    const next: DatasetRecord = {
      ...cur,
      name: dto.name ?? cur.name,
      description:
        dto.description !== undefined
          ? dto.description.length
            ? dto.description
            : null
          : cur.description,
      tags: dto.tags !== undefined ? this.normalizeTags(dto.tags) : cur.tags,
      metadata:
        dto.metadata !== undefined
          ? { ...dto.metadata }
          : { ...cur.metadata },
      storage_ref:
        dto.storage_ref !== undefined
          ? this.volumePath.normalizeAndAssertStorageRef(dto.storage_ref)
          : cur.storage_ref,
      updated_at: now,
    };
    all[idx] = next;
    await this.repo.saveAll(all);
    return this.toDto(next);
  }

  async removeLogical(id: string): Promise<DatasetResponseDto> {
    const all = await this.repo.loadAll();
    const idx = this.findIndexById(all, id);
    if (idx < 0 || all[idx].deleted_at !== null) {
      throw new NotFoundException(`Dataset ${id} not found`);
    }
    const now = new Date().toISOString();
    all[idx] = {
      ...all[idx],
      deleted_at: now,
      updated_at: now,
    };
    await this.repo.saveAll(all);
    return this.toDto(all[idx]);
  }
}
