# Lacunas GUI MATLAB → shell Vue (MLMS Studio)

Documento de apoio à task **SOF-36** (backlog GUI): cruza callbacks e fluxos em `matlab-code/GUI/main_gui.m` com o estado actual do SPA (`services/mlms-spa`). A matriz legacy detalhada deve permanecer canónica em **SOF-29**; arqueologia de código em **SOF-33**.

## Estado actual do shell Vue (março 2026)

- **Vista:** `AnalyticsShellView.vue` — shell analítico mínimo.
- **Dados:** `useWDataStore` — lista de amostras (`w_data` alinhado ao legacy: ficheiro, `mz`, intensidades), selecção única, demo, submissão de job de ingestão quando o tipo existir no BFF.
- **Visualização:** `D3SpectrumPreview` — pré-visualização 1D da amostra seleccionada.
- **Pipeline:** `runPipelineStub`, timeline de jobs, canal WebSocket — orquestração genérica, sem espelhar fluxos interactivos do GUIDE.

## Operações legacy com impacto directo em UX (grupos, resample, MMF/fuzzy)

| Área | Callbacks / funções em `main_gui.m` | Comportamento legacy | Equivalente Vue |
|------|--------------------------------------|----------------------|-----------------|
| Selecção múltipla / “grupos” | `get_val_wdata_list`, `list_w_data_Callback`, vários botões usam `val` ou `1:length(...)` | Operações sobre subconjunto da lista ou sobre **todas** as amostras (ex.: alinhamento quando só uma entrada seleccionada expande para todas). | Só selecção **única** (`wSelectedIndex`). Sem multi-select nem barra de acções por conjunto. |
| Resample (pré-visualizar) | `btn_resample_Callback` | `fn_reshape` + gráfico de exploração; não persiste até aplicar. | **Ausente.** |
| Resample (aplicar) | `btn_apply_resample_Callback` | Actualiza `handles.w_data.all` e `.mz` para índices seleccionados. | **Ausente** (nenhum job/UI). |
| Alinhamento icoshift | `btn_apply_align_Callback`, `btn_allign_spctr_Callback` | Modo alinhamento + intervalo; depende de dados coerentes (mensagens a pedir resample). | **Ausente.** |
| Picos + MMF / fuzzy | `update_pks_select_params`, `btn_apply_pks_slct_Callback`, `btn_preview_pks_slct_Callback` | `fn_pks_select_mm` (`fn_mmv_fuzzy`, `params.fuzzyWindow`, baseline, etc.); preview e SVD associados. | **Ausente** (sem painel de picos nem parâmetros). |
| Normalização | `btn_norm_Callback` | Normaliza espectros seleccionados (`fn_norm_max_min`). | **Ausente.** |
| Ordenação / resample por classe | `btn_sort_Callback` | `fn_resample_data` após ordenar por classe. | **Ausente.** |

## Outras lacunas relevantes para roadmap (fora do foco imediato SOF-36, mas mapeadas)

- Importar / guardar / remover `w_data` (`btn_import_*`, `btn_save_*`, `btn_load_*`, `btn_remove_w_data_*`).
- Rede neuronal: treino, teste, persistência (`btn_train_*`, `btn_test_*`, `btn_save_nn_*`, …).
- Feature extraction completa (`btn_run_feature_extraction_Callback`, listas de features, ECOSPEC, validação cruzada).
- Export Weka, configurar picos (save/load config).

## Priorização sugerida para o frontend (Vue)

1. **P1 — Selecção múltipla e modelo mental de “conjunto activo”**  
   Base para qualquer batch (resample, alinhamento, picos). Incluir indicação visual de quais amostras entram na próxima operação.

2. **P1 — Resample**  
   UI: taxa + aplicar; chamada a worker/BFF que encapsule `fn_reshape` (ou equivalente no worker Rust/Python). Pré-visualização opcional no segundo incremento.

3. **P2 — Painel de selecção de picos (MMF/fuzzy)**  
   Espelhar `def_mm_selection_params` / campos do GUIDE (`fuzzyWindow`, baseline, intervalos, allocation). Depende de API de processamento e de preview (D3 ou WebGL leve).

4. **P2 — Alinhamento**  
   Após resample estável; expor modos alinhados aos `pop_align_*` do MATLAB.

5. **P3 — Normalização e ordenação por classe**  
   Operações rápidas após P1/P2 estarem estáveis.

## Integração técnica

- O shell já prevê jobs (`postJob`, `mlms.ingest_w_data`). Novas operações devem seguir o mesmo padrão: UI colecta parâmetros → BFF/worker executa → resultado reidratado em `w_data` ou versão versionada.
- Manter paridade de nomes de campos com `def_data_structure` / `w_data` no MATLAB para reduzir surpresas na serialização.

## Referências de código

- GUI: `matlab-code/GUI/main_gui.m`
- MMF/fuzzy picos: `matlab-code/fn_pks_select_mm.m`, `matlab-code/fn_mmv_fuzzy.m`, `matlab-code/def_mm_selection_params.m`
- Vue: `services/mlms-spa/src/views/AnalyticsShellView.vue`, `services/mlms-spa/src/stores/wData.ts`
