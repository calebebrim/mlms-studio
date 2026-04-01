# Contrato HTTP — Node ↔ `mlms-worker` (MVP)

**API pública (Vue → Node):** ver [`docs/api/openapi-v0.yaml`](../../../docs/api/openapi-v0.yaml) (BFF `/api/v1/`, jobs + SSE).

Serviço Rust binário `mlms-worker`: escuta TCP, JSON. **`POST /v1/jobs`** pode exigir autenticação serviço-a-serviço quando `MLMS_WORKER_INTERNAL_TOKEN` está definido (ver abaixo). `/health` e `/ready` permanecem públicos para probes. Em produção, manter o worker atrás de rede privada ou gateway mesmo com token.

## Base URL

- Desenvolvimento: `http://127.0.0.1:8080` (porta configurável, ver abaixo).

## Porta e ambiente

| Variável           | Padrão | Descrição        |
|--------------------|--------|------------------|
| `MLMS_WORKER_PORT` | —      | Porta HTTP (prioritária em dev/Tilt). |
| `PORT`             | —      | Usada se `MLMS_WORKER_PORT` estiver vazio (padrão Cloud Run). |
| `MLMS_LOG_FORMAT`  | texto  | Definir `json` para logs estruturados em stdout (GCP Logging). |
| `MLMS_WORKER_INTERNAL_TOKEN` | — | Opcional. Se não vazio, `POST /v1/jobs` exige header `Authorization: Bearer <mesmo valor>`. **Não** expor este valor ao browser; apenas BFF Node, proxy interno ou Vite (dev) devem injetar o header. |

Se nenhuma variável de porta for definida, o bind usa **8080**.

### Limites e cabeçalhos de resposta

- Corpo máximo em `POST /v1/jobs`: **256 KiB** (rejeição com **413** se exceder).
- `job_type`: não vazio após trim, no máximo **128** caracteres; inválido → **422** (`invalid_job_type`).
- Respostas incluem `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`.

## `GET /health`

Verificação de disponibilidade para orquestração (Kubernetes, load balancer, script Node).

**Resposta 200** (`application/json`):

```json
{
  "status": "ok",
  "service": "mlms-worker",
  "version": "0.1.0"
}
```

O campo `version` segue a versão do crate publicada em `Cargo.toml`.

## `GET /ready`

Readiness para orquestração (Kubernetes `readinessProbe`, Cloud Run quando aplicável). No MVP o corpo é o mesmo de `/health`; no futuro pode incorporar checagens de dependências.

## `POST /v1/jobs`

Submissão síncrona de um job: o worker responde com o resultado (ou erro) no mesmo request. Para filas assíncronas, o Node pode encapsular esta chamada ou evoluir o contrato numa task futura.

**Headers**

- `Content-Type: application/json`
- Se `MLMS_WORKER_INTERNAL_TOKEN` estiver definido no worker: `Authorization: Bearer <token>` (obrigatório; caso contrário **401**).

**Corpo (campos conhecidos)**

| Campo      | Tipo   | Obrigatório | Descrição |
|------------|--------|-------------|-----------|
| `job_id`   | UUID string | Não    | Correlação / idempotência; se omitido, o worker gera um UUID na resposta. |
| `job_type` | string | Sim         | Discriminador do pipeline; apenas valores documentados são suportados (ver secções abaixo). |
| `payload`  | object | Não         | JSON arbitrário; semântica depende de `job_type`. |

Campos desconhecidos no objeto raiz são rejeitados pelo worker (`400` do serde se o body for inválido; configure o cliente para não enviar chaves extra até o contrato evoluir).

### `job_type`: `mlms.echo`

Ecoa `payload` com metadados do worker — útil para smoke test e integração Node.

**Resposta 200**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "echo": { "qualquer": "coisa" },
    "worker_version": "0.1.0"
  }
}
```

### `job_type`: `mlms.pipeline_stub`

Placeholder até pipeline MLMS real (espectros, GA, etc.). Não executa MATLAB nem binários científicos.

**`payload` opcional**

- `stage` (string): valor ecoado no resultado; padrão `"default"`.

**Resposta 200**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "processed": true,
    "stage": "default",
    "worker_version": "0.1.0",
    "notes": "MVP stub — replace with real MLMS pipeline when available."
  }
}
```

### `job_type`: `mlms.genetic_algorithm`

Parâmetros de GA + **um espectro 1D** no mesmo objeto (alinhado a `def_data_structure.mz` / intensidade por ponto; o MATLAB `ga_fr.m` consome matrizes de treino — aqui apenas leitura e resumo numérico, sem execução do `ga` nem *fitness*).

**`payload` (objeto obrigatório)**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `population_size` | inteiro JSON | Sim | &gt; 0 |
| `generations` | inteiro JSON | Sim | &gt; 0 |
| `crossover_rate` | número | Não | Entre 0 e 1; padrão `0.8` |
| `mutation_rate` | número | Não | Entre 0 e 1; padrão `0.01` |
| `ga_profile` | string | Não | Perfil nomeado (SOF-53); não vazio após trim, máximo **64** caracteres. Validado e ecoado em `result`; não altera o processamento stub no MVP. |
| `outer_iterations` | inteiro JSON | Não | &gt; 0 quando presente. Conceito alinhado a loop externo (`cicles` em `ga_fr.m`). Ecoado em `result`; sem execução de ciclos no MVP. |
| `mz` | array de números | Sim | Não vazio; cada elemento finito; até **65536** pontos. Ordenação: o worker ordena pelo eixo m/z e exige valores **estritamente crescentes** (sem m/z duplicado após ordenar). |
| `intensity` | array de números | Sim | Mesmo comprimento que `mz`; cada elemento finito. |

Falha de validação → **422** com `code`: `invalid_genetic_algorithm_payload`.

**Resposta 200** — inclui `spectrum_summary` derivado do I/O espectral:

| Campo em `result.spectrum_summary` | Descrição |
|-------------------------------------|-----------|
| `point_count` | Número de pontos após ordenação |
| `mz_min`, `mz_max` | Extremos do eixo m/z |
| `intensity_sum`, `intensity_mean` | Soma e média das intensidades |
| `trapezoid_area_mz_intensity` | Área trapezoidal \(\int I(mz)\,dmz\) em ordem crescente de `mz` (0 se só um ponto) |

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "processed": true,
    "algorithm": "genetic_algorithm",
    "population_size": 50,
    "generations": 100,
    "crossover_rate": 0.8,
    "mutation_rate": 0.01,
    "ga_profile": "default_stub",
    "outer_iterations": 3,
    "spectrum_summary": {
      "point_count": 3,
      "mz_min": 100.0,
      "mz_max": 300.0,
      "intensity_sum": 6.0,
      "intensity_mean": 2.0,
      "trapezoid_area_mz_intensity": 400.0
    },
    "worker_version": "0.1.0",
    "notes": "MVP — spectral axis read and summarized (trapezoid area, means); no GA/search execution (see MATLAB ga_fr.m for full pipeline)."
  }
}
```

### `job_type`: `mlms.watchpoints`

Amostragem de intensidade nos m/z dos *watchpoints* sobre um espectro 1D enviado no `payload` (o MATLAB `ga_watch_points.m` integra GA e universo difuso; aqui apenas **interpolação linear** ao longo de `mz` + referência opaca).

**`payload` (objeto obrigatório)**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `spectrum_ref` | string | Sim | Referência opaca ao espectro (ex.: chave de estudo); não vazia após trim |
| `watchpoint_positions` | array de números | Sim | Pelo menos um elemento; cada valor finito (interpretado como m/z alvo) |
| `mz` | array de números | Sim | Mesmas regras que em `mlms.genetic_algorithm` (não vazio, finitos, ordenação + monotonia estrita após ordenar pelo worker). |
| `intensity` | array de números | Sim | Mesmo comprimento que `mz`. |

**Interpolação:** para cada valor \(q\) em `watchpoint_positions`, o worker devolve a intensidade interpolada linearmente entre os dois pontos de `mz` que enquadram \(q\). Fora de \([mz\_min, mz\_max]\) usa-se o valor do extremo (*flat extrapolation*).

Falha de validação → **422** com `code`: `invalid_watchpoints_payload`.

**Resposta 200** — inclui `watchpoint_intensities` (mesma ordem que `watchpoint_positions`) e `spectrum_summary` (mesmo formato que em `mlms.genetic_algorithm`).

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "processed": true,
    "spectrum_ref": "study-1/run-a",
    "watchpoint_positions": [200.0, 150.0],
    "watchpoint_intensities": [2.0, 1.5],
    "feature_count": 2,
    "spectrum_summary": {
      "point_count": 3,
      "mz_min": 100.0,
      "mz_max": 300.0,
      "intensity_sum": 6.0,
      "intensity_mean": 2.0,
      "trapezoid_area_mz_intensity": 400.0
    },
    "worker_version": "0.1.0",
    "notes": "MVP — linear interpolation of intensity along mz at watchpoint m/z; flat extrapolation outside [mz_min, mz_max]. See ga_watch_points.m for full GA."
  }
}
```

### `job_type`: `mlms.mlp`

Classificação / transformação **stub** com **uma** camada densa + `tanh`, alinhada ao estágio `model.mlp_stub` dentro de `mlms.experiment_snapshot` (mesmos pesos determinísticos a partir de `seed`). Útil para chamadas diretas ao worker sem montar um snapshot completo.

**`payload` (objeto obrigatório)**

Apenas as chaves abaixo são aceites; qualquer outra chave → **422** (`invalid_mlp_payload`).

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `input` | array de números | Sim | Não vazio; cada elemento finito; até **8192** elementos. |
| `out_dim` | inteiro JSON | Não | Dimensão de saída; entre **1** e **256**; padrão **4**. Se presente, deve ser inteiro JSON válido nesse intervalo. |
| `seed` | inteiro JSON | Não | Semente para a geração determinística de pesos; padrão **42**. Se presente, inteiro não negativo (como `u64` em JSON). |

Falha de validação → **422** com `code`: `invalid_mlp_payload`.

**Resposta 200**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "processed": true,
    "algorithm": "mlp",
    "out_dim": 4,
    "input_dim": 3,
    "output": [0.12, -0.05, 0.33, 0.08],
    "worker_version": "0.1.0",
    "notes": "MVP — single dense layer with tanh; deterministic weights from seed; same numerics as experiment_snapshot stage model.mlp_stub."
  }
}
```

### `job_type`: `mlms.random_forest`

Classificação **stub** com votação determinística por “árvores” sintéticas (sem `fit` real de floresta), alinhada ao estágio `model.rf_stub` dentro de `mlms.experiment_snapshot` (mesma função núcleo no worker). Útil para chamadas diretas ao worker sem montar um snapshot completo.

**`payload` (objeto obrigatório)**

Apenas as chaves abaixo são aceites; qualquer outra chave → **422** (`invalid_rf_payload`).

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `input` | array de números | Sim | Não vazio; cada elemento finito; até **8192** elementos (vector de features de uma amostra). |
| `n_trees` | inteiro JSON | Não | Número de votos sintéticos; entre **1** e **512**; padrão **10**. |
| `n_classes` | inteiro JSON | Não | Entre **2** e **64**; padrão **2**. |
| `seed` | inteiro JSON | Não | Semente para mistura determinística por árvore; padrão **42**. Inteiro não negativo (como `u64` em JSON). |

**Semântica de `seed`:** com `input` fixo, `predicted_class` / `predict_proba` / `train_error_stub` são determinísticos no stub; **não** reproduzem o RNG do MATLAB `TreeBagger`. Para relatórios reprodutíveis, fixar `seed` explicitamente.

**Modo A / Modo B (entrada tabular):** planeamento de paridade com `make_wtrts` / `nn_train_RF.m` em **[SOF-75](/SOF/issues/SOF-75#document-plan)** (*Modo A:* `train_*` / `test_*` separados; *Modo B:* matriz `features` com rótulo na última coluna e *split* opcional). **Não** faz parte do wire format deste binário; até o worker evoluir, usar `input` (uma amostra) ou encadear estágios que alimentem o **último vector** antes de `model.rf_stub`.

**Resposta 200** (campos principais): `processed`, `algorithm` (`random_forest`), `n_trees`, `n_classes`, `input_dim`, `predicted_class`, `class_vote_counts`, `predict_proba`, `train_error_stub` (escalar derivado de `seed`+`input`, não métrica de treino real), `worker_version`, `notes`.

Falha de validação → **422** com `code`: `invalid_rf_payload`.

### `job_type`: `mlms.experiment_snapshot`

Materializa um **snapshot** do pipeline de experimento (ordem e parâmetros acordados com o BFF). O Node valida a **forma** do documento (`snapshot_version`, tamanho de `stages`, `kind` por estágio); o worker executa estágios em sequência, mantém estado (espectro canónico + último vector de features) e aplica validação **numérica** em cada passo (sem duplicar regras de negócio do domínio no BFF).

**Envelope opcional (BFF):** o Node pode enviar `payload` como `{ "schema_version": 1, "payload": { … } }`, onde o objeto interior segue a tabela abaixo (`snapshot_version`, `stages`, …). O worker valida `schema_version === 1`, extrai o interior e processa como snapshot plano. Formato plano legado (sem `schema_version` / `payload` no topo) continua aceite.

**`payload` (objeto obrigatório no pedido HTTP)** — plano **ou** interior do envelope acima:

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `snapshot_version` | inteiro | Não | Apenas **1** suportado; omissão tratada como `1`. |
| `experiment_id` | string | Não | Correlaciona com recurso persistido no BFF; máximo **256** caracteres. |
| `stages` | array | Sim | Entre **1** e **32** objetos, cada um com `kind` (string não vazia, ≤ **64** caracteres após trim no worker, alinhado ao BFF) e `params` (objeto JSON; omissão → `{}`). Campo opcional `id` (string) é ecoado em `stage_results`. |

**`kind` de estágio (MVP)**

| `kind` | Estado requerido | Descrição |
|--------|------------------|-----------|
| `preprocess.canonical_spectrum` | — | `params` com `mz` / `intensity` (mesmas regras que `mlms.genetic_algorithm`). Guarda o espectro no estado do pipeline. |
| `preprocess.pks_select_mm` | — | Parâmetros alinhados a `fn_pks_select_mm.m` / `fn_mmv_fuzzy.m` (OpenAPI `PksSelectMmStageParams`): `mz`, `intensity`, `fuzzy_window`, `power` e opcionais (`column_range`, `use_min_as_baseline`, `baseline_correction_half_width`, `use_absolute_value`, `allocation`, `mmf_mode`, `show_preview`). **MVP:** validação numérica + espectro canónico no estado; sem cálculo real de picos/MM fuzzy. |
| `features.watchpoints` | espectro | `params` com `spectrum_ref` e `watchpoint_positions` (como `mlms.watchpoints`); `mz`/`intensity` vêm do estado. Produz `watchpoint_intensities` e define o **último vector** para estágios seguintes. |
| `model.genetic_algorithm_summary` | espectro | Parâmetros de GA em `params` + espectro do estado; mesmo resultado resumido que `mlms.genetic_algorithm` (inclui `ga_profile` / `outer_iterations` opcionais, validados e ecoados em `stage_results` quando enviados). O **último vector** vira quatro escalares derivados do resumo espectral (`mean_i`, área trapezoidal, `point_count`, soma de intensidades). |
| `model.mlp_stub` | — | Camada densa **uma vez** com `tanh`; pesos determinísticos a partir de `seed` (padrão `42`). `out_dim` opcional (padrão **4**, máx. **256`). Entrada: `params.input` (array de números, até **8192** elementos) **ou**, se omitido, o **último vector** do estágio anterior. |
| `model.rf_stub` | — | *Stub* RF: mesmos defaults e limites que `mlms.random_forest` (`n_trees` 1–512, `n_classes` 2–64, `seed`). Entrada: `params.input` **ou** o **último vector** anterior. Saída inclui `predicted_class`, `class_vote_counts`, `predict_proba`, `train_error_stub`. O **último vector** passa a ser `predict_proba` (comprimento `n_classes`) para estágios seguintes. |
| `eval.vector_stats` | último vector | Devolve `mean`, `min`, `max`, `l2_norm` e `len` sobre o último vector (não o altera). |

**Resposta 200** — inclui `stage_results` (um objeto JSON por estágio, com `kind` e métricas específicas), `stages_executed`, `final_feature_vector` (último vector após o último estágio que o definiu, ou `null`) e `notes`.

Falha de validação ou `kind` desconhecido → **422** com `code`: `invalid_experiment_snapshot`.

### Erros de negócio (`job_type` desconhecido, validação de `payload`, etc.)

**422 Unprocessable Entity**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "failed",
  "error": {
    "code": "unknown_job_type",
    "message": "unknown job_type: mlms.desconhecido"
  }
}
```

| `error.code` | Quando |
|--------------|--------|
| `invalid_job_type` | `job_type` vazio ou com mais de 128 caracteres após trim |
| `unknown_job_type` | `job_type` não documentado |
| `invalid_genetic_algorithm_payload` | `mlms.genetic_algorithm` com `payload` inválido (tipos, intervalos, objeto ausente) |
| `invalid_watchpoints_payload` | `mlms.watchpoints` com `payload` inválido |
| `invalid_experiment_snapshot` | `mlms.experiment_snapshot` com snapshot inválido, estágio incoerente ou `kind` desconhecido |
| `invalid_mlp_payload` | `mlms.mlp` com `payload` inválido (tipos, intervalos, chave desconhecida ou `input` ausente) |
| `invalid_rf_payload` | `mlms.random_forest` com `payload` inválido (tipos, intervalos, chave desconhecida ou `input` ausente) |

## Exemplo mínimo (Node / `fetch`)

```javascript
const base = process.env.MLMS_WORKER_URL ?? "http://127.0.0.1:8080";

const token = process.env.MLMS_WORKER_INTERNAL_TOKEN;
const headers = {
  "Content-Type": "application/json",
  ...(token ? { Authorization: `Bearer ${token}` } : {}),
};

const r = await fetch(`${base}/v1/jobs`, {
  method: "POST",
  headers,
  body: JSON.stringify({
    job_type: "mlms.pipeline_stub",
    payload: { stage: "integration-test" },
  }),
});
const data = await r.json();
```

## Evolução

Novos `job_type`, jobs assíncronos (202 + polling/webhook) e políticas adicionais (CORS na borda, WAF) seguem em tasks filhas com acordo explícito entre Node e Rust. Autenticação Bearer interna e limite de corpo já estão implementados no worker quando configurados.
