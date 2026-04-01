import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface WorkerSubmitBody {
  job_type: string;
  job_id?: string;
  payload?: Record<string, unknown>;
}

@Injectable()
export class WorkerClientService {
  constructor(private readonly config: ConfigService) {}

  get baseUrl(): string {
    return this.config.get<string>('MLMS_WORKER_URL') ?? 'http://127.0.0.1:8080';
  }

  private get internalToken(): string | undefined {
    const t = this.config.get<string>('MLMS_WORKER_INTERNAL_TOKEN');
    if (t == null || t.trim() === '') return undefined;
    return t;
  }

  async postJob(body: WorkerSubmitBody): Promise<{ status: number; json: unknown }> {
    const url = `${this.baseUrl.replace(/\/$/, '')}/v1/jobs`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };
    const token = this.internalToken;
    if (token) headers.Authorization = `Bearer ${token}`;

    const workerBody: Record<string, unknown> = {
      job_type: body.job_type.trim(),
    };
    if (body.job_id) workerBody.job_id = body.job_id;
    if (body.payload !== undefined) workerBody.payload = body.payload;

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(workerBody),
      });
      const text = await res.text();
      let json: unknown = null;
      if (text) {
        try {
          json = JSON.parse(text) as unknown;
        } catch {
          json = { raw: text };
        }
      }
      return { status: res.status, json };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`worker_unreachable:${message}`);
    }
  }
}
