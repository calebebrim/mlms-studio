# GitHub Actions — CD (GCP, GKE, Cloud Run)

**Alinhamento:** [ADR 0003 — Cloud Run vs GKE](../adr/0003-cloud-run-vs-gke.md) (worker pesado → **GKE**; front estático → **Cloud Run**).  
**Segredos e WIF:** [Segredos — GCP, Tilt, CI](../security/secrets-gcp-tilt-ci.md).

## Workflows

| Ficheiro | Função |
|----------|--------|
| [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) | CI: `fmt` / `clippy` / `test` (Rust), build Vue, smoke Docker nas pushes a `main`/`master`. |
| [`.github/workflows/cd.yml`](../../.github/workflows/cd.yml) | CD manual: build + push para **Artifact Registry**, deploy **mlms-worker** no GKE (opcional) e **web** no Cloud Run. |

O CD corre apenas por **`workflow_dispatch`** ( separação **dev** / **staging** / **prod**). Cada execução deve usar um **GitHub Environment** com o mesmo nome (`dev`, `staging`, `prod`) para aprovações e segredos por ambiente.

## Variáveis e segredos (repositório ou por environment)

### Obrigatórios para CD

| Nome | Tipo | Descrição |
|------|------|-----------|
| `GCP_PROJECT_ID` | Variable | ID do projeto GCP. |
| `GCP_REGION` | Variable | Região (ex.: `us-central1`). Repositório do Artifact Registry: `{REGION}-docker.pkg.dev`. |
| `GCP_ARTIFACT_REPO` | Variable | Nome do repositório Docker no Artifact Registry (ex.: `mlms-studio`). |
| `GCP_SERVICE_ACCOUNT` | Variable | E-mail da service account federada (ex.: `gha-mlms@PROJETO.iam.gserviceaccount.com`). |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Secret | Resource name do provider WIF (pool GitHub → GCP). |

### Opcionais

| Nome | Descrição |
|------|-----------|
| `GKE_CLUSTER_NAME` | Se definido, o job **Deploy GKE** corre; caso contrário, só build/push e Cloud Run. |
| `GKE_CLUSTER_LOCATION` | Região ou zona do cluster (Autopilot usa região). |
| `K8S_NAMESPACE` | Sobrepõe o namespace padrão (`mlms-dev`, `mlms-staging`, `mlms-prod`). |
| `CLOUD_RUN_SERVICE_WEB_PREFIX` | Prefixo do serviço Cloud Run; o sufixo é o ambiente (ex.: prefixo `mlms-web` → `mlms-web-prod`). |

## Imagens

- **Worker:** `{REGION}-docker.pkg.dev/{PROJECT}/{REPO}/mlms-worker:{GITHUB_SHA}`
- **Web:** `{REGION}-docker.pkg.dev/{PROJECT}/{REPO}/mlms-web:{GITHUB_SHA}`

## Kubernetes

Manifestos base: [`infra/k8s/mlms-worker/`](../../infra/k8s/mlms-worker/). O pipeline aplica os YAMLs e atualiza a imagem com `kubectl set image` para o digest da execução.

## Cloud Run (web)

O serviço nginx escuta na porta **80** (`services/mlms-spa/Dockerfile`). O deploy usa `--allow-unauthenticated` para o front público; em produção restrita, substituir por IAM / Load Balancer conforme o desenho de tráfego (ADR 0003).

## Pré-requisitos na GCP (resumo)

1. Repositório **Artifact Registry** (formato Docker) com o nome em `GCP_ARTIFACT_REPO`.
2. **Workload Identity Federation** ligando o repositório GitHub à service account em `GCP_SERVICE_ACCOUNT` (sem JSON em GitHub).
3. Permissões mínimas na SA: `artifactregistry.writer`, `run.admin` (Cloud Run), e para GKE `container.developer` (ou papel equivalente ao vosso modelo de deploy).
4. Criar os **GitHub Environments** `dev`, `staging`, `prod` e associar os segredos/variáveis sensíveis ao ambiente correto.

## Handoff

**DevOps Lead** ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)): validar WIF, políticas IAM e revisores nos environments de produção.
