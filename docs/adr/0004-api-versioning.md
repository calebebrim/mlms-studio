# ADR 0004 — Versionamento de API HTTP

- **Status:** proposta
- **Data:** 2026-03-29
- **Contexto:** O frontend Vue consome APIs expostas pelo backend Node. É necessário evoluir contratos sem quebrar clientes e alinhar com OpenAPI ([SOF-4](http://127.0.0.1:3100/issues/3aa7acfa-0c5c-4193-baa8-561d595f4ac9)).

## Decisão

1. **Prefixo de versão no path:** `/api/v1/...` como padrão estável; recursos novos experimental podem usar `/api/v1beta1/...` apenas com flag de produto explícita.
2. **OpenAPI:** um artefato por major (`openapi-v1.yaml`); breaking changes exigem **v2** e janela de convivência documentada.
3. **Deprecação:** header `Deprecation` + `Sunset` (RFC 8594) e entrada no changelog; mínimo de **90 dias** de sobreposição para clientes externos (internamente, alinhar com releases do frontend).
4. **Autenticação:** Bearer (sessão/OAuth Google) documentado por versão; mudanças de escopo OAuth tratadas como breaking se removerem permissões sem migração.

## Alternativas consideradas

- **Versionamento só por header (`Accept-Version`):** rejeitado como padrão primário — mais difícil de inspecionar e cachear em CDN/proxy.
- **GraphQL sem versão:** fora do escopo MVP explícito do brief (Node REST); reavaliar em ADR futuro se o produto pivotar.

## Consequências

- **Positivas:** URLs autoexplicativas; caches e WAF podem rotear por path.
- **Negativas:** múltiplos conjuntos de rotas para manter durante transições.
- **Handoff:** **API Engineer** e Backend Lead ([SOF-4](http://127.0.0.1:3100/issues/3aa7acfa-0c5c-4193-baa8-561d595f4ac9)) detalham esquemas, erros padronizados (`problem+json` recomendado) e política de paginação.
