# ADR 0001 — Mensageria assíncrona interna

- **Status:** proposta
- **Data:** 2026-03-29
- **Contexto:** O backend Node orquestra jobs de longa duração executados por serviços Rust. É necessário desacoplar requisições HTTP síncronas do trabalho pesado, com retries idempotentes e visibilidade operacional, alinhado ao stack GCP do [SOF-1](http://127.0.0.1:3100/issues/2cb9ddc2-c409-46e2-99e4-3b9a56b16e30).

## Decisão

1. **Canal primário:** **Google Cloud Pub/Sub** como barramento entre Node (publicador/consumidor leve) e workers Rust (consumidores com pull ou push via Cloud Run).
2. **Contrato de mensagem:** payload JSON com `jobId`, `correlationId`, `schemaVersion` do envelope e corpo tipado por tipo de job; nenhum binário grande no corpo — referências a **GCS** ou chaves em **Bigtable** quando necessário.
3. **Semântica:** pelo menos uma vez na entrega; workers **idempotentes** (chave natural ou dedupe por `jobId` + estágio).
4. **Dead letter:** subscription com **dead-letter topic** e política de retry com backoff; alertas via métricas nativas do Pub/Sub.

## Alternativas consideradas

- **Redis / Streams:** menor latência e bom para dev local com Tilt; porém mais operação manual em produção GCP e menos integração nativa com IAM e DLQ do que Pub/Sub.
- **Fila in-process:** rejeitada — não escala entre réplicas nem sobrevive a deploys.

## Consequências

- **Positivas:** escala horizontal clara, modelo de custo alinhado ao uso, DLQ e métricas prontas.
- **Negativas:** latência mínima maior que Redis; em dev, Tilt deve subir emulador Pub/Sub ou túnel compatível.
- **Handoff:** o **Distributed Systems Engineer** detalha quotas, naming de topics/subscriptions e política de ordenação por tenant (se aplicável). A task [SOF-7](http://127.0.0.1:3100/issues/efc69b2a-5c6c-482a-b8e1-c33529dc3485) (DevOps) incorpora wiring em ambientes.
