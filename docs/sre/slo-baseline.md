# SLO baseline — MLMS Studio

**Âmbito:** serviços expostos na borda HTTP descritos no [ADR 0003](../adr/0003-cloud-run-vs-gke.md) (API Node em Cloud Run, worker Rust em Cloud Run ou GKE). Valores são **iniciais**; revisar após 30 dias de métricas reais.

## Serviço: `mlms-worker` (HTTP)

| SLI | Definição | SLO (janela 30d) | Notas |
|-----|-----------|------------------|--------|
| Disponibilidade | Proporção de probes `GET /ready` com HTTP 2xx, amostrada pelo orquestrador (kubelet / Cloud Run health) | **99,5%** | Excluir janelas de deploy anunciadas se a política de erro o permitir. |
| Latência de jobs síncronos | p95 de `POST /v1/jobs` para `job_type` documentados como “rápidos” (ex.: `mlms.echo`, `mlms.pipeline_stub`) | **p95 < 2 s** | Jobs futuros longos devem sair do caminho síncrono (Pub/Sub / job queue) — ver [ADR 0001](../adr/0001-internal-async-messaging.md). |
| Taxa de erro de aplicação | Respostas HTTP 5xx / todas as respostas `POST /v1/jobs` | **< 0,5%** | 4xx por payload inválido não contam contra este SLI. |

## Serviço: API Node (BFF) — placeholder

Até o BFF publicar métricas e rotas estáveis, usar apenas:

- disponibilidade do endpoint de health documentado pelo DevOps;
- SLO provisório **99,5%** na mesma janela, alinhado ao worker.

Refinar quando existir tráfego real e SLIs de latência por rota.

## Política de error budget

- **Orçamento mensal** para disponibilidade 99,5%: ~3h36m de indisponibilidade acumulada na janela de 30 dias.
- **Consumo > 50%** do orçamento antes do dia 15: congelar mudanças não essenciais (features) no serviço afetado; priorizar correções e hardening.
- **Esgotamento do orçamento:** exigir post-mortem breve e aprovação explícita do DevOps Lead / owner do serviço antes de deploys de risco até a virada da janela.

## Revisão

- Reavaliar SLOs após primeiros manifests em produção e após definir limites de timeout Pub/Sub ↔ Run/GKE ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)).
