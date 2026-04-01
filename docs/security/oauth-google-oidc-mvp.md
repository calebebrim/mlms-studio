# OAuth Google / OIDC — especificação MVP (MLMS-Studio Web)

**Referências:** plano de segurança MVP na task **SOF-10** (Paperclip); brief **SOF-1** — critério de aceite: apenas usuários autorizados acessam dados do projeto. **Segredos, Secret Manager, Tilt e CI:** [secrets-gcp-tilt-ci.md](./secrets-gcp-tilt-ci.md) (**SOF-15**).  
**Âmbito:** primeiro ciclo em que existir **API Node** + **front Vue**; o worker Rust não participa do login do usuário final (apenas identidade serviço-a-serviço, fora deste documento).

---

## 1. Objetivo

Implementar **login com Google** via **OpenID Connect**, com fluxo **Authorization Code + PKCE**, troca de código **somente no backend** (client secret nunca no bundle do front), validação estrita de tokens e sessão com **cookies seguros** (preferido) ou **Bearer de curta duração** com refresh controlado no servidor.

---

## 2. Fluxo recomendado (Authorization Code + PKCE)

```mermaid
sequenceDiagram
  participant U as Usuário
  participant B as Browser
  participant F as Front (Vue)
  participant A as API Node
  participant G as Google OAuth/OIDC

  U->>F: Clicar em Entrar com Google
  F->>F: Gerar code_verifier, code_challenge (S256), state, nonce
  F->>B: Redirecionar para Google (response_type=code, code_challenge, state, nonce)
  B->>G: Autorização
  G->>B: Redirect com ?code=&state=
  B->>A: GET /auth/callback?code=&state= (via mesmo site ou BFF)
  A->>A: Validar state (cookie ou servidor); trocar code por tokens (com client_secret)
  A->>A: Validar ID Token (assinatura, iss, aud, exp, nonce)
  A->>B: Set-Cookie sessão (ou emitir par access/refresh opaco)
  B->>F: Redirecionar para app autenticada
```

**Regras:**

- **PKCE:** `code_challenge_method=S256`; `code_verifier` gerado pelo front, enviado apenas na troca de token feita pelo **backend** (o front pode enviar o verifier num body POST ao callback do backend sobre HTTPS, nunca na query string em logs).
- **Client secret:** apenas em variável de ambiente / Secret Manager na API Node (ver task **SOF-15** — segredos).
- **Redirect URIs:** lista fechada em consola Google Cloud; alinhada a `https://{api-host}/auth/google/callback` (ou rota BFF equivalente). Proibir wildcards inseguros.

---

## 3. Validação de tokens (ID Token obrigatória no MVP)

Após `token_endpoint`, validar o **ID Token** JWT:

| Verificação | Detalhe |
|-------------|---------|
| Assinatura | JWKS do issuer (`https://www.googleapis.com/oauth2/v3/certs`), cache com `kid`; rejeitar algoritmos não permitidos. |
| `iss` | `https://accounts.google.com` ou `accounts.google.com` conforme documentação atual do Google. |
| `aud` | Deve incluir o **OAuth Client ID** da aplicação web (o mesmo usado no fluxo). |
| `exp` / `iat` | Relógio com folga mínima (ex.: skew de 60s). |
| `nonce` | Igual ao enviado no passo de autorização (ligação à sessão do browser). |
| Email verificado | Se `email`/`email_verified` forem usados para provisionamento, exigir `email_verified=true` quando a política de acesso depender do email. |

**Access Token** do Google só é necessário se a API chamar APIs Google em nome do usuário; para “login na app”, o **subject** estável é `sub` do ID Token.

---

## 4. Sessão da aplicação: duas opções aceites

### Opção A — Cookies (preferida para browser)

- Cookie de sessão **HttpOnly**, **Secure**, **SameSite=Lax** (ou `Strict` se o fluxo permitir).
- Nome não óbvio; **rotation** de ID de sessão após login bem-sucedido.
- Backend armazena estado de sessão (store server-side ou JWT assinado **httpOnly** não aplicável a JWT no cookie se for acessível — preferir **sessão opaca** no servidor + cookie só com ID).
- **CSRF:** para mutações com cookie, usar **double submit token**, **SameSite** adequado, ou padrão BFF onde o front só chama mesma origem.

### Opção B — Bearer de curta duração

- Access JWT **curto** (ex.: 5–15 min) emitido pela API após validação do ID Token; **refresh** apenas via endpoint que use cookie HttpOnly ou mecanismo equivalente — **não** guardar refresh em `localStorage` em produção.
- CORS estrito (abaixo).

**Proibido no MVP:** armazenar ID Token ou refresh tokens de longa duração em `localStorage`/`sessionStorage` sem mitigação aprovada pelo Security Lead.

---

## 5. CSRF, `state` e `nonce`

- **`state`:** valor aleatório criptograficamente seguro; persistido no servidor (sessão) ou cookie assinado **antes** do redirect; comparar byte a byte no callback.
- **`nonce`:** incluir no pedido de autorização e exigir match no ID Token.
- Endpoints de callback **GET** não devem ter efeitos colaterais além da criação de sessão após validação completa.

---

## 6. CORS e superfície HTTP (API Node)

- `Access-Control-Allow-Origin` apenas para origens conhecidas (dev: `http://localhost:5173` etc.; prod: domínio do front).
- Credenciais: se cookies cross-site forem inevitáveis, alinhar SameSite e domínios com Infra; preferir **mesmo site** (reverse proxy) para simplificar.
- Headers de segurança (Helmet ou equivalente): **HSTS** em prod, **X-Content-Type-Options**, frame ancestors restritos.
- **CSP** progressiva no front quando o build estabilizar (começar restritiva em staging).

---

## 7. Autorização por projeto (alinhamento ao brief)

- O **subject** Google (`sub`) mapeia para um **usuário interno**; a **membership em projeto/tenant** é sempre decidida **no servidor** em cada request que acesse dados sensíveis.
- Nunca confiar em `projectId` ou papéis enviados só pelo cliente sem verificação na API e na camada de dados.
- Auditoria mínima: `sub` (ou ID interno), `projectId`, ação, timestamp (ver threat model no plano **SOF-10**).

---

## 8. Contratos sugeridos (para Backend / Front)

| Artefacto | Responsável | Notas |
|-----------|-------------|-------|
| `GET /auth/google/start` ou redirect iniciado no front | Front + API | Devolve URL de autorização ou front monta URL com parâmetros acordados. |
| `GET` ou `POST /auth/google/callback` | API Node | Troca code, valida tokens, cria sessão, redireciona. |
| `POST /auth/logout` | API Node | Invalidar sessão server-side; limpar cookie. |
| `GET /auth/me` | API Node | Estado do usuário + projetos permitidos (sem dados sensíveis extra). |

Nomes de rotas são exemplos; o Architecture/Backend Lead fixa o contrato OpenAPI.

---

## 9. Checklist de aceite (testável)

- [ ] Fluxo completo em **HTTPS** (ou localhost) com **PKCE S256** e **state**/`nonce` validados; falha controlada se qualquer verificação falhar.
- [ ] **Client secret** ausente do repositório e do bundle front; apenas injetado na API em runtime.
- [ ] ID Token validado com **JWKS**, **aud**, **iss**, **exp**, **nonce**.
- [ ] Sessão via **cookie HttpOnly + Secure + SameSite** adequado **ou** Bearer curto + refresh protegido, sem tokens sensíveis em `localStorage`.
- [ ] **Redirect URI** coincide exatamente com a configuração Google; tentativa com URI não registada falha.
- [ ] Usuário **sem** membership no projeto recebe **403** nas rotas de dados desse projeto (prova do critério do brief).
- [ ] CORS não permite origem arbitrária em produção.
- [ ] Logs não contêm **code**, **access_token**, **id_token** nem cookies completos.

---

## 10. Coordenação

- **Backend Lead / Node:** implementação do callback, store de sessão, enforcement de projeto.
- **Security Lead:** revisão final antes de produção e exceções a esta especificação.
- **Infra / DevOps:** URLs públicas, TLS, segredos (**SOF-15**).

**Revisão:** atualizar este documento no primeiro PR que introduzir autenticação real ou alterar domínios/Client IDs.
