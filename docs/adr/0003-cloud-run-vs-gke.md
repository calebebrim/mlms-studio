# ADR 0003 — Separação Cloud Run e GKE

- **Status:** proposta
- **Data:** 2026-03-29
- **Contexto:** Produção prevê **Kubernetes** e **Cloud Run**, com **Tilt** no desenvolvimento e **GitHub Actions** para CI/CD ([SOF-1](http://127.0.0.1:3100/issues/2cb9ddc2-c409-46e2-99e4-3b9a56b16e30)).

## Decisão

1. **Cloud Run:** workloads **stateless** de escala elástica e cold start aceitável:
   - API Node (BFF/REST);
   - endpoints de webhook leves;
   - consumidores Pub/Sub **push** para tarefas de duração limitada (timeout Cloud Run).
2. **GKE (Autopilot recomendado para simplificar ops):** workloads que precisam de **GPU**, **jobs longos**, **volume local efêmero grande** ou **binários específicos** difíceis de ajustar ao modelo de revisão do Cloud Run:
   - pipelines Rust pesados;
   - treinamento / batch associado a Codex (fora do request path síncrono);
   - componentes que exijam DaemonSets ou políticas de nó específicas no futuro.
3. **Desenvolvimento:** Tilt orquestra o mesmo contrato de imagens e env vars; emuladores GCP (Pub/Sub, etc.) quando necessário.
4. **Tráfego:** ingress único documentado (API Gateway ou Load Balancer + regras de roteamento) para o browser falar apenas com domínios controlados.

## Alternativas consideradas

- **Somente GKE:** mais controle, porém mais custo fixo e complexidade para API Node com tráfego esporádico.
- **Somente Cloud Run:** limita jobs longos e GPU sem workarounds frágeis.

## Consequências

- **Positivas:** custo proporcional ao uso na borda HTTP; flexibilidade no núcleo de compute científico.
- **Negativas:** dois runtimes para observabilidade e políticas de deploy — padronizar métricas, tracing e secrets ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)).
- **Handoff:** DevOps Lead ([SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485)) materializa manifests e pipelines; **Distributed Systems Engineer** valida limites de timeout e escala Pub/Sub ↔ Run/GKE.
