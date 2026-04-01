# SRE — MLMS Studio (baseline)

Entregáveis de confiabilidade e observabilidade alinhados ao [ADR 0003 — Cloud Run e GKE](../adr/0003-cloud-run-vs-gke.md) e à task [SOF-13](http://127.0.0.1:3100/issues/42f71da2-5362-48d5-a8be-023021e983fe).

| Documento | Conteúdo |
|-----------|----------|
| [slo-baseline.md](slo-baseline.md) | SLIs, SLOs iniciais, política de error budget |
| [observability-gcp.md](observability-gcp.md) | Logs estruturados, métricas Cloud Monitoring, tracing |
| [alerts-minimal-gcp.md](alerts-minimal-gcp.md) | Alertas mínimos (Run/GKE) e exemplos Terraform |
| [runbook-incident.md](runbook-incident.md) | Resposta a incidente e escalonamento |

**Handoff DevOps Lead:** usar probes `GET /health` (liveness) e `GET /ready` (readiness) no `mlms-worker`; em Cloud Run definir `MLMS_LOG_FORMAT=json` e confiar em `PORT` ou mapear para o binário (ver observability-gcp).
