# Build a partir da raiz do repositório:
#   docker build -f services/mlms-api/Dockerfile .
# Contexto alinhado ao mlms-worker (`.dockerignore` na raiz).
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY services/mlms-api/package.json services/mlms-api/package-lock.json ./
RUN npm ci
COPY services/mlms-api/ ./
RUN npm run build

FROM node:22-bookworm-slim AS prod
WORKDIR /app
ENV NODE_ENV=production
COPY services/mlms-api/package.json services/mlms-api/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
CMD ["node", "dist/main.js"]
