# Architecture Decision Records — MLMS Studio

Registro de decisões de arquitetura alvo (Vue / Node / Rust / GCP). Cada ADR é imutável após aceite; mudanças futuras criam novo número.

| ADR | Título |
|-----|--------|
| [0001](0001-internal-async-messaging.md) | Mensageria assíncrona interna |
| [0002](0002-metadata-and-bigtable-boundaries.md) | Metadados operacionais vs dados importados (Bigtable) |
| [0003](0003-cloud-run-vs-gke.md) | Separação Cloud Run e GKE |
| [0004](0004-api-versioning.md) | Versionamento de API HTTP |
| [0005](0005-node-bff-rust-worker-boundary.md) | Fronteira BFF Node e worker Rust |

Diagramas C4: [../architecture/c4-mlms-studio.md](../architecture/c4-mlms-studio.md).
