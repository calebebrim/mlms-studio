# Runbook — incidente (MLMS Studio)

## Escopo

Indisponibilidade ou degradação dos serviços HTTP (BFF, `mlms-worker`) e, futuramente, filas assíncronas ([ADR 0001](../adr/0001-internal-async-messaging.md)).

## Severidade (sugestão)

| Nível | Critério | Exemplo |
|-------|----------|---------|
| SEV1 | Plataforma inacessível para usuários ou perda de dados | Todas as revisões Cloud Run falhando; erro massivo de persistência. |
| SEV2 | Degradação forte | p95 de jobs > SLO por > 30 min; taxa 5xx > 2%. |
| SEV3 | Impacto limitado ou workaround disponível | Falha em uma região com failover OK; bug em um `job_type` específico. |

## Resposta imediata (primeiros 15 minutos)

1. **Confirmar o sintoma:** reproduzir com `curl` no `/health` e `/ready` do worker; checar dashboard Cloud Run / GKE e Cloud Logging (filtro `resource.labels.service_name` ou equivalente).
2. **Identificar mudança recente:** último deploy, alteração de variável de ambiente, quota GCP.
3. **Mitigar:** rollback da revisão Cloud Run ou `kubectl rollout undo` no deployment do worker, se o risco for baixo e o deploy for suspeito.
4. **Comunicar:** canal interno acordado (Slack/on-call) com linha do tempo e dono.

## Diagnóstico — worker

- Logs JSON: filtrar por `level=ERROR` e por `job_id` se o cliente reportar ID.
- Restarts em loop: verificar OOM (memória), crash no startup (porta em uso, env faltando).
- 422 em massa: possível mudança de contrato Node ↔ worker — ver [NODE_CONTRACT.md](../../services/mlms-worker/docs/NODE_CONTRACT.md).

## Diagnóstico — BFF (quando existir)

- Verificar dependências a jusante (worker, Pub/Sub, secrets).
- Validar timeouts e retries idempotentes.

## Pós-incidente

- SEV1/SEV2: post-mortem breve (causa raiz, correção, itens de follow-up) dentro de 5 dias úteis.
- Atualizar alertas se o incidente expôs lacuna nos [alertas mínimos](alerts-minimal-gcp.md).

## Contactos

- **DevOps Lead:** dono de pipelines, manifests e canais de alerta ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)).
- **SRE:** revisão de SLO, error budget e evolução de observabilidade.
