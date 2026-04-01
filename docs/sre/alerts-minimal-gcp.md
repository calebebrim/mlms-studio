# Alertas mínimos — GCP

Conjunto **mínimo** para detectar indisponibilidade e degradação grave antes de dashboards avançados. Ajustar labels (`project_id`, `service_name`) ao materializar.

## 1. Uptime (sintético)

- **Tipo:** uptime check HTTP contra URL pública do worker ou do BFF (após ingress).
- **Caminho:** `/ready` (worker) ou rota de health do BFF.
- **Frequência:** 1–5 minutos.
- **Condição de alerta:** falha em N regiões consecutivas ou taxa de falha > limiar acordado.

## 2. Cloud Run — taxa de erro 5xx

Usar métrica `run.googleapis.com/request_count` filtrando `response_code_class=5xx`.

**Política (conceito):**

- **Threshold:** taxa de 5xx > 1% durante 5–10 minutos (suavizar falsos positivos em deploy).
- **Canal:** e-mail / Slack do canal de plantão (definir no DevOps).

## 3. Cloud Run — latência

- Métrica: `run.googleapis.com/request_latencies` (ou distribuição equivalente).
- **Threshold inicial:** p95 > 5 s por 10 minutos no serviço worker (revisar quando SLI real estiver no [slo-baseline.md](slo-baseline.md)).

## 4. GKE — restarts e OOM

- **kube_pod_container_status_restarts** (ou métrica GCP equivalente para GKE) acima de limiar em janela curta.
- **Memory limit** próximo de esgotamento sustentado no container do worker.

## Exemplo Terraform (Cloud Run 5xx — esboço)

Adaptar `project`, `notification_channels` e filtro de serviço.

```hcl
resource "google_monitoring_alert_policy" "run_5xx_rate" {
  display_name = "MLMS worker Cloud Run 5xx rate"
  combiner     = "OR"
  conditions {
    display_name = "5xx ratio high"
    condition_threshold {
      filter          = <<-EOT
        resource.type = "cloud_run_revision"
        AND metric.type = "run.googleapis.com/request_count"
        AND metric.labels.response_code_class = "5xx"
      EOT
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.01
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = [var.notification_channel_id]
}
```

> O filtro exato costuma combinar `response_code_class` com denominador de requests totais via **MQL** ou política de **ratio**; validar no console antes de fixar em IaC.

## Próximos passos

- Versionar estes recursos no mesmo repositório dos manifests ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)).
- Adicionar alerta de **quota** / **Pub/Sub backlog** quando filas assíncronas estiverem em produção.
