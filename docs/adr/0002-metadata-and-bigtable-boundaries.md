# ADR 0002 — Metadados operacionais vs dados importados (Bigtable)

- **Status:** proposta
- **Data:** 2026-03-29
- **Contexto:** O produto precisa armazenar (a) estado operacional pequeno e consultável por usuário/sessão e (b) volumes grandes de dados científicos importados. O brief cita **Bigtable** para gestão dos dados importados.

## Decisão

1. **Bigtable:** reservado a **dados de domínio científico em larga escala** (séries, features, resultados de pipeline) modelados com **row key** explícita (ex.: prefixo por estudo/usuário + ordenação para leitura por intervalo). Não armazenar blobs; usar **GCS** + referência na linha.
2. **Metadados operacionais:** **Cloud SQL (PostgreSQL)** ou **Firestore** (escolha final em conjunto com [SOF-8](http://127.0.0.1:3100/issues/56119fa8-88c4-429e-b51e-9c4db8f3db08) — Data Lead) para:
   - contas, preferências, permissões de estudo;
   - jobs, estados, checkpoints, auditoria de modo IA;
   - índices e caches de catálogo que não pertencem ao workload scan-heavy do Bigtable.
3. **Fronteira:** serviços Rust leem/escrevem Bigtable e GCS; Node é dono de transações de orquestração e expõe API ao frontend; nenhum acesso direto do browser a Bigtable.

## Alternativas consideradas

- **Bigtable para tudo:** rejeitado para metadados relacionais e consultas ad hoc de baixa cardinalidade — custo e modelagem menos adequados.
- **Somente SQL:** rejeitado como único store para séries massivas — escala de escrita/leitura por intervalo pior que wide-column.

## Consequências

- **Positivas:** separação clara de responsabilidades; equipes podem evoluir schema BT e SQL independentemente com contratos de API.
- **Negativas:** consistência eventual entre stores; necessidade de sagas/outbox (ver ADR 0001) para alinhar estado de job e artefatos.
- **Handoff:** [SOF-8](http://127.0.0.1:3100/issues/56119fa8-88c4-429e-b51e-9c4db8f3db08) define famílias de colunas, row key e política de TTL; Node/Rust respeitam SDKs e quotas na [SOF-4](http://127.0.0.1:3100/issues/3aa7acfa-0c5c-4193-baa8-561d595f4ac9) / [SOF-6](http://127.0.0.1:3100/issues/c28316bb-6bf8-44b4-889c-4189836bf09a).
