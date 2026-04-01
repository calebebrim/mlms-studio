# syntax=docker/dockerfile:1
# Build from repository root: docker build -f services/mlms-worker/Dockerfile .
# O contexto é a raiz do repo; `.dockerignore` restringe arquivos (ex.: latex/, services/mlms-spa/)
# para não rebuildear a imagem quando essas áreas mudam.
FROM rust:1.85-bookworm AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY services/mlms-worker ./services/mlms-worker
RUN cargo build --release -p mlms-worker

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/mlms-worker /usr/local/bin/mlms-worker
ENV MLMS_WORKER_PORT=8080
EXPOSE 8080
USER nobody:nogroup
ENTRYPOINT ["/usr/local/bin/mlms-worker"]
