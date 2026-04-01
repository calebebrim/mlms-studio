import {
  BadRequestException,
  Injectable,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'node:fs';
import * as path from 'node:path';

/**
 * Garante que `storage_ref` é um caminho lógico sob o root do volume montado,
 * sem segmentos `..` nem bytes nulos (mitiga path traversal).
 */
@Injectable()
export class VolumePathService implements OnModuleInit {
  private volumeRootAbs!: string;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const raw =
      this.config.get<string>('MLMS_DATA_VOLUME_PREFIX') ?? 'data';
    this.volumeRootAbs = path.resolve(process.cwd(), raw);
    try {
      fs.mkdirSync(this.volumeRootAbs, { recursive: true });
    } catch {
      // Diretório pode ser só referência lógica em alguns ambientes; falha em runtime ao aceder ficheiros.
    }
  }

  getVolumeRootAbs(): string {
    return this.volumeRootAbs;
  }

  /**
   * Valida e devolve `storage_ref` normalizado (separadores POSIX, sem `/` inicial).
   */
  normalizeAndAssertStorageRef(ref: string): string {
    if (typeof ref !== 'string') {
      throw new BadRequestException('storage_ref must be a string');
    }
    const trimmed = ref.trim();
    if (!trimmed.length) {
      throw new BadRequestException('storage_ref cannot be empty');
    }
    if (trimmed.includes('\0')) {
      throw new BadRequestException('storage_ref contains invalid characters');
    }
    const withSlashes = trimmed.replace(/\\/g, '/');
    const segments = withSlashes.split('/').filter((s) => s.length > 0);
    if (segments.some((s) => s === '..')) {
      throw new BadRequestException(
        'storage_ref must not contain parent directory segments',
      );
    }
    if (segments.some((s) => s === '.')) {
      throw new BadRequestException(
        'storage_ref must not contain "." path segments',
      );
    }
    const joined = path.resolve(this.volumeRootAbs, ...segments);
    const base = path.resolve(this.volumeRootAbs);
    const rel = path.relative(base, joined);
    if (rel.startsWith('..') || path.isAbsolute(rel)) {
      throw new BadRequestException('storage_ref escapes volume root');
    }
    return segments.join('/');
  }
}
