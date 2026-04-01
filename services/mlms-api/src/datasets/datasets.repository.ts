import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type { DatasetRecord, DatasetsStoreFile } from './dataset-record';

@Injectable()
export class DatasetsRepository implements OnModuleInit {
  private readonly storePath: string;
  private chain: Promise<void> = Promise.resolve();

  constructor(private readonly config: ConfigService) {
    const rel =
      this.config.get<string>('MLMS_DATASETS_STORE_PATH') ?? 'var/datasets.json';
    this.storePath = path.isAbsolute(rel)
      ? rel
      : path.resolve(process.cwd(), rel);
  }

  async onModuleInit(): Promise<void> {
    await fs.mkdir(path.dirname(this.storePath), { recursive: true });
    try {
      await fs.access(this.storePath);
    } catch {
      const initial: DatasetsStoreFile = { datasets: [] };
      await fs.writeFile(
        this.storePath,
        JSON.stringify(initial, null, 2),
        'utf8',
      );
    }
  }

  private enqueue<T>(fn: () => Promise<T>): Promise<T> {
    const next = this.chain.then(fn, fn);
    this.chain = next.then(
      () => undefined,
      () => undefined,
    );
    return next;
  }

  async loadAll(): Promise<DatasetRecord[]> {
    return this.enqueue(async () => {
      const raw = await fs.readFile(this.storePath, 'utf8');
      const parsed = JSON.parse(raw) as DatasetsStoreFile;
      return Array.isArray(parsed.datasets) ? parsed.datasets : [];
    });
  }

  async saveAll(records: DatasetRecord[]): Promise<void> {
    return this.enqueue(async () => {
      const body: DatasetsStoreFile = { datasets: records };
      await fs.writeFile(
        this.storePath,
        JSON.stringify(body, null, 2),
        'utf8',
      );
    });
  }
}
