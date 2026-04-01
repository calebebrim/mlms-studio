# ADR 0005 — Fronteira BFF Node e worker Rust (HTTP, sync/async, stack local)

- **Status:** proposta
- **Data:** 2026-03-29
- **Contexto:** O SPA Vue (Vite) em desenvolvimento proxifica `/mlms-worker` para o binário `mlms-worker` (Rust) na porta 8080, com injeção opcional de `Authorization: Bearer` para `MLMS_WORKER_INTERNAL_TOKEN`. O `compose.yaml` sobe apenas `mlms-worker` + `web`; não existe processo Node na stack Docker. Já existem o contrato HTTP Node↔Rust em [`services/mlms-worker/docs/NODE_CONTRACT.md`](../../services/mlms-worker/docs/NODE_CONTRACT.md) e a superfície pública alvo do BFF em [`docs/api/openapi-v0.yaml`](../api/openapi-v0.yaml). O diagrama C4 alvo já prevê API Node separada da SPA ([`docs/architecture/c4-mlms-studio.md`](../architecture/c4-mlms-studio.md)).

## Decisão

1. **Superfície pública para o browser:** apenas o **BFF Node** sob o prefixo **`/api/v1/`** (versionamento conforme [ADR 0004](0004-api-versioning.md)). O SPA não deve chamar URLs do worker Rust em produção.
2. **Worker Rust como dependência interna:** o Node é o único cliente HTTP “de confiança” para `POST /v1/jobs` (e rotas futuras do worker). O token `MLMS_WORKER_INTERNAL_TOKEN` permanece **somente** em serviço-a-serviço (Node → worker, ou testes); nunca embutido no bundle do browser.
3. **MVP síncrono:** o BFF implementa `POST /api/v1/jobs` (e rotas correlatas do OpenAPI) encaminhando para `POST {MLMS_WORKER_URL}/v1/jobs`, mapeando corpos e erros (`422` de negócio, `413`, etc.) para o contrato público (`application/problem+json` onde o OpenAPI define).
4. **Alvo assíncrono:** evolução alinhada ao [ADR 0001](0001-internal-async-messaging.md) (Pub/Sub): o BFF aceita jobs com `202`, persiste metadado mínimo, publica mensagem; workers Rust consomem; progresso via **SSE** (`/api/v1/jobs/{id}/events` no OpenAPI v0). O caminho síncrono pode permanecer para `job_type` leves ou stubs.
5. **Stack local (Compose + Tilt):** introduzir serviço **`mlms-api`** (imagem Node) na mesma rede Compose que `mlms-worker`. Variáveis típicas: `MLMS_WORKER_URL=http://mlms-worker:8080`, segredo interno partilhado só entre `mlms-api` e `mlms-worker`. O serviço `web` (Vite) passa a proxificar **`/api`** → `mlms-api` (ex.: `http://mlms-api:3000`), em vez de expor o worker diretamente ao dev server do browser.
6. **Migração do proxy Vite atual:** deprecar o uso de `/mlms-worker` no cliente (`services/mlms-spa`): `VITE_MLMS_API_BASE` deve apontar para `/api/v1` (ou origem do BFF). Remover o proxy `/mlms-worker` → worker após o BFF estar funcional em dev, ou mantê-lo apenas com comentário explícito “legado / testes de integração direta”, sem uso pelo código da SPA.

## Alternativas consideradas

- **CORS no worker e chamadas diretas do browser:** rejeitado — expõe superfície interna, complica auth e observabilidade na borda.
- **Manter apenas proxy Vite em produção:** rejeitado — não existe Vite em runtime de produção; o BFF é necessário para auth, rate limit, e contrato estável.

## Consequências

- **Positivas:** contrato único para o frontend; segredo do worker só server-side; alinhamento com OpenAPI e C4; caminho claro para Pub/Sub sem mudar a URL que o SPA usa.
- **Negativas:** mais um serviço a construir, observar e publicar em imagem; latência extra hop Node→Rust no MVP síncrono (aceitável para jobs não massivos).
- **Handoff:** **Node Backend Engineer** — serviço `mlms-api`, Compose/Tilt, integração com worker; **Rust Engineer** — novos `job_type` e semântica de payload conforme pipelines MLMS; **Frontend Lead** — base URL, cliente HTTP e remoção do atalho `/mlms-worker`; **DevOps Lead** — pipelines de imagem e envs entre ambientes, em coordenação com [ADR 0001](0001-internal-async-messaging.md) quando o async entrar.
