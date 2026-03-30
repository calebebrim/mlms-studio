# MLMS Studio — stack local (Tilt + Docker Compose).
# Pré-requisitos: Docker, Docker Compose v2, Tilt (https://docs.tilt.dev/install.html)
#
#   tilt up
#
# Segredos: não versionar `.env`. Copiar `.env.example` → `.env` na raiz se precisar de
# overrides (ex.: MLMS_WORKER_PROXY_TARGET). Ver docs/security/secrets-gcp-tilt-ci.md.
#
# URLs: Tilt UI ~ :10350 | SPA (Vite) http://localhost:5173 | BFF http://localhost:3000/api/v1/health | worker http://localhost:8080/health
#
# Dados locais (BFF): definir MLMS_HOST_DATA_DIR no `.env` da raiz para mapear uma pasta do host
# → /var/mlms/data em mlms-api (ver compose.yaml e .env.example). O Tilt usa o mesmo docker-compose.
#
# --- Scoping de dependências (board / brief) ---
# Com só `docker_compose()`, o Tilt pode tratar o contexto `.` partilhado e disparar rebuilds
# cruzados. Declaramos `image:` no compose.yaml e um `docker_build` por serviço com `ignore=`
# explícito — cada imagem só reage às árvores que a afectam.
#
# Excepções documentadas:
# - Alterar `compose.yaml`, `Tiltfile` ou `.dockerignore` pode recarregar/rebuildar vários serviços
#   (metadados partilhados).
# - Ficheiros na raiz fora destas árvores (ex.: README) não estão ignorados; acrescentar a
#   ambas as listas se começarem a causar ruído.
# - Pacotes partilhados futuros entre API e worker devem retirar-se dos `ignore` ou usar deps
#   explícitas.

docker_compose('./compose.yaml')

docker_build(
    'mlms-studio-worker:dev',
    '.',
    dockerfile='services/mlms-worker/Dockerfile',
    ignore=[
        'services/mlms-api',
        'services/mlms-spa',
        'latex',
        'docs',
        '.cursor',
        # Builds locais `cargo build` escrevem em target/; não devem rebuildear a imagem Tilt.
        'target',
    ],
)

docker_build(
    'mlms-studio-api:dev',
    '.',
    dockerfile='services/mlms-api/Dockerfile',
    ignore=[
        'services/mlms-worker',
        'services/mlms-spa',
        'latex',
        'docs',
        '.cursor',
        'Cargo.toml',
        'Cargo.lock',
        'target',
    ],
)

docker_build(
    'mlms-studio-web:dev',
    './services/mlms-spa',
    dockerfile='services/mlms-spa/Dockerfile.dev',
    ignore=['node_modules', 'dist'],
)
