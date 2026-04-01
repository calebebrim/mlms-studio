import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type { ExperimentsStoreFile } from './experiment-records';

@Injectable()
export class ExperimentsRepository implements OnModuleInit {
  private readonly storePath: string;
  private chain: Promise<void> = Promise.resolve();

  constructor(private readonly config: ConfigService) {
    const rel =
      this.config.get<string>('MLMS_EXPERIMENTS_STORE_PATH') ??
      'var/experiments.json';
    this.storePath = path.isAbsolute(rel)
      ? rel
      : path.resolve(process.cwd(), rel);
  }

  async onModuleInit(): Promise<void> {
    await fs.mkdir(path.dirname(this.storePath), { recursive: true });
    try {
      await fs.access(this.storePath);
    } catch {
      const initial: ExperimentsStoreFile = { experiments: [], revisions: [] };
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

  async loadStore(): Promise<ExperimentsStoreFile> {
    return this.enqueue(async () => {
      const raw = await fs.readFile(this.storePath, 'utf8');
      const parsed = JSON.parse(raw) as ExperimentsStoreFile;
      return {
        experiments: Array.isArray(parsed.experiments)
          ? parsed.experiments
          : [],
        revisions: Array.isArray(parsed.revisions) ? parsed.revisions : [],
      };
    });
  }

  async saveStore(store: ExperimentsStoreFile): Promise<void> {
    return this.enqueue(async () => {
      await fs.writeFile(
        this.storePath,
        JSON.stringify(store, null, 2),
        'utf8',
      );
    });
  }
}
