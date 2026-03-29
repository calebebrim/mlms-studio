# Segredos — GCP Secret Manager, desenvolvimento local, Tilt, CI

**Task:** [SOF-15](http://127.0.0.1:3100/issues/4ec3218e-ad4f-4de0-8a3e-cb8b457f9634)  
**Plano pai:** [SOF-10](http://127.0.0.1:3100/issues/413e4bf8-b419-44d9-b3bb-9a7f85ca8028)  
**OAuth / OIDC (MVP):** [oauth-google-oidc-mvp.md](./oauth-google-oidc-mvp.md)

## Princípios

1. **Nada de segredos no Git** — chaves, client secrets, strings de sessão e URLs com credenciais ficam fora do repositório.
2. **Produção:** [Google Cloud Secret Manager](https://cloud.google.com/secret-manager) como padrão; outro backend só com aprovação explícita do CTO/Security Lead.
3. **Local:** ficheiro `.env` (não versionado), derivado de `.env.example` na raiz e de `projeto-web/.env.example` para o front.

## Nomes sugeridos (Secret Manager)

Prefixar por ambiente e serviço, por exemplo:

| Segredo | Exemplo de ID do secret | Consumidor |
|--------|-------------------------|------------|
| Client secret Google OAuth | `mlms-prod-api-google-oauth-client-secret` | API Node |
| Segredo de sessão | `mlms-prod-api-session-secret` | API Node |
| String de base de dados | `mlms-prod-api-database-url` | API Node |

A API Node (quando existir) deve ler segredos na arranque ou via biblioteca cliente com cache curto; **não** embutir valores em imagem Docker.

## Rotação mínima (baseline)

| Artefacto | Política sugerida | Notas |
|-----------|-------------------|--------|
| OAuth client secret (Google) | Rodar a cada **90 dias** ou após suspeita de vazamento | Gerar novo secret na consola Google; atualizar Secret Manager; redeploy; revogar o antigo após janela curta. |
| Segredo de sessão / assinatura JWT interna | **90 dias** ou após incidente | Invalidar sessões antigas aceitável no MVP se o store for server-side. |
| Chaves de conta de serviço JSON | **Evitar** em CI; preferir **WIF + OIDC** | Se inevitável, rotação manual alinhada à política org. |

Registar data da última rotação no runbook de incidentes ou na folha de controlo interna do projeto.

## Tilt e Docker Compose (local)

- **Tilt** (`Tiltfile`): usa `docker_compose('./compose.yaml')`. Variáveis podem ser exportadas no shell antes de `tilt up` ou colocadas em `.env` na raiz; o Compose lê substituições quando usas `docker compose --env-file .env up` (o Tilt invoca o Compose com o mesmo ficheiro).
- **Compose:** valores não sensíveis podem permanecer em `compose.yaml`; credenciais de desenvolvimento apenas em `.env` local.
- O serviço **web** usa `MLMS_WORKER_PROXY_TARGET`; o exemplo está em [`.env.example`](../../.env.example).

## GitHub Actions e identidade (OIDC / Workload Identity)

O workflow [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) declara `permissions.id-token: write` para permitir **OIDC** com o GitHub.

O pipeline de **deploy** (build/push, GKE, Cloud Run) está em [`.github/workflows/cd.yml`](../../.github/workflows/cd.yml) com a lista completa de variáveis em [**docs/devops/github-actions-cd.md**](../devops/github-actions-cd.md).

Para jobs que publiquem imagens ou acedam ao GCP **sem** chave JSON de longa duração:

1. Criar **Workload Identity Federation** no GCP a federar o repositório GitHub.
2. Mapear o pool a uma service account com permissões mínimas (ex.: Artifact Registry, Cloud Run deploy).
3. No job, usar `google-github-actions/auth` com `workload_identity_provider` e `service_account`.

Variáveis `GCP_WORKLOAD_IDENTITY_PROVIDER` e `GCP_SERVICE_ACCOUNT` devem ser configuradas como **secrets** ou **variables** do repositório — não no código.

## Verificação rápida antes de commit

```bash
git grep -nE '(client_secret|CLIENT_SECRET|password\s*=\s*["\x27]|BEGIN (RSA |OPENSSH )?PRIVATE KEY)' -- . ':!*.md' || true
```

Rever manualmente qualquer correspondência; ajustar padrões conforme a stack crescer.

## Handoff

- **Security Lead:** validar política de rotação e exceções.  
- **Infra / DevOps:** ligar WIF, Secret Manager e injeção em Cloud Run/GKE quando o pipeline de deploy existir.
