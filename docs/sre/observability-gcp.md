# Observabilidade — GCP (Cloud Run + GKE)

Objetivo: uma linha de base comum para **logs**, **métricas** e **tracing** nos dois runtimes do [ADR 0003](../adr/0003-cloud-run-vs-gke.md).

## Logs estruturados

### `mlms-worker` (Rust)

- **Desenvolvimento local / Tilt:** texto legível (default `tracing_subscriber::fmt`).
- **Cloud Run / GKE:** definir `MLMS_LOG_FORMAT=json` para linhas JSON consumíveis pelo **Cloud Logging** (severity inferida do nível `tracing`).
- **Porta:** o binário aceita `MLMS_WORKER_PORT` ou, em segundo lugar, `PORT` (padrão Cloud Run).

Campos recomendados em mensagens de negócio futuras (via `tracing` `fields!`): `job_id`, `job_type`, `trace_id` quando existir cabeçalho W3C Trace Context.

### API Node (futuro)

- Usar logger JSON (ex.: `pino` com destino stdout) em produção.
- Incluir `severity`, `message`, `service`, `httpRequest` (quando aplicável) alinhados ao [log entry model](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry) do GCP.

## Métricas (Cloud Monitoring)

Sem Prometheus obrigatório na fase inicial:

- **Cloud Run:** métricas gerenciadas `request_count`, `request_latencies`, `instance_count` por serviço e revisão.
- **GKE:** métricas de workload do Kubernetes (CPU, memória, restarts) +, se necessário, **Google Managed Service for Prometheus** numa fase posterior.

**Log-based metrics (opcional):** criar contadores a partir de logs JSON (ex.: contagem de `status=Failed` em respostas de job) quando o volume justificar.

## Tracing distribuído

- Propagar cabeçalhos **W3C** (`traceparent`) do BFF para o worker nas chamadas HTTP internas.
- Cloud Run integra com **Cloud Trace** quando a biblioteca cliente ou agente apropriado estiver configurado; detalhar no pipeline CI/CD ao adicionar dependências OpenTelemetry no Node e no Rust.

## Healthchecks

| Rota | Uso |
|------|-----|
| `GET /health` | Liveness — processo aceita tráfego. |
| `GET /ready` | Readiness — hoje equivalente à liveness; evoluir para checagens de dependências (fila, disco, licenças MATLAB, etc.). |

Manifests Kubernetes típicos:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

Cloud Run: configurar health check HTTP apontando para `/ready` (ou `/health` se apenas um endpoint for suportado na revisão inicial).
