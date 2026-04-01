export interface DatasetRecord {
  id: string;
  name: string;
  description: string | null;
  tags: string[];
  metadata: Record<string, unknown>;
  /** Caminho lógico relativo ao prefixo do volume (validado no create/update). */
  storage_ref: string;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface DatasetsStoreFile {
  datasets: DatasetRecord[];
}
