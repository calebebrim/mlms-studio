//! MLMS Studio worker — HTTP MVP: health check and job intake with stub MLMS processing.

use axum::{
    body::Body,
    extract::State,
    http::{header, Request, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::net::SocketAddr;
use subtle::ConstantTimeEq;
use thiserror::Error;
use tower_http::{
    limit::RequestBodyLimitLayer,
    set_header::SetResponseHeaderLayer,
    trace::TraceLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};
use uuid::Uuid;

/// Limite de corpo JSON em `POST /v1/jobs` (bytes).
const MAX_JOB_BODY_BYTES: usize = 256 * 1024;

/// Tamanho máximo de `job_type` após trim (evita payloads abusivos).
const MAX_JOB_TYPE_LEN: usize = 128;

/// Tamanho máximo de pontos espectrais (`mz` / `intensity`) por pedido (alinhado a limites de corpo JSON).
const MAX_SPECTRUM_POINTS: usize = 65_536;

/// Máximo de estágios num job `mlms.experiment_snapshot` (alinhar ao BFF).
const MAX_EXPERIMENT_STAGES: usize = 32;

const MAX_STAGE_KIND_LEN: usize = 64;

const MAX_EXPERIMENT_ID_LEN: usize = 256;

/// Nome de perfil GA (`ga_profile`); alinhado a SOF-53 / risco de espelhar `gaoptimset` completo.
const MAX_GA_PROFILE_LEN: usize = 64;

/// Limite de árvores no stub RF (`n_trees`); alinhado ao BFF / OpenAPI.
const MAX_RF_TREES: u32 = 512;

const MIN_RF_CLASSES: u32 = 2;

/// Limite de classes no stub RF (`n_classes`).
const MAX_RF_CLASSES: u32 = 64;

const DEFAULT_RF_TREES: u32 = 10;

const DEFAULT_RF_CLASSES: u32 = 2;

#[derive(Clone)]
struct AppState {
    /// Se definido (`MLMS_WORKER_INTERNAL_TOKEN`), `POST /v1/jobs` exige `Authorization: Bearer <token>`.
    internal_token: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case", deny_unknown_fields)]
struct JobRequest {
    /// Idempotency / correlation id from the caller (Node). Generated if omitted in response echo only when we synthesize — caller should send one.
    #[serde(default)]
    job_id: Option<Uuid>,
    /// Contract discriminator; only documented variants are accepted in MVP.
    job_type: String,
    /// Opaque JSON parameters for the pipeline (validated per `job_type`).
    #[serde(default)]
    payload: Value,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct JobResponse {
    job_id: Uuid,
    status: JobStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<JobErrorBody>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
enum JobStatus {
    Completed,
    Failed,
}

#[derive(Debug, Serialize)]
struct JobErrorBody {
    code: String,
    message: String,
}

#[derive(Debug, Error)]
enum JobError {
    #[error("unknown job_type: {0}")]
    UnknownJobType(String),
    #[error("invalid job_type: empty or too long (max {MAX_JOB_TYPE_LEN} chars)")]
    InvalidJobType,
    #[error("{0}")]
    InvalidGeneticAlgorithmPayload(String),
    #[error("{0}")]
    InvalidWatchpointsPayload(String),
    #[error("{0}")]
    InvalidExperimentSnapshot(String),
    #[error("{0}")]
    InvalidMlpPayload(String),
    #[error("{0}")]
    InvalidRfPayload(String),
}

impl JobError {
    fn code(&self) -> &'static str {
        match self {
            JobError::UnknownJobType(_) => "unknown_job_type",
            JobError::InvalidJobType => "invalid_job_type",
            JobError::InvalidGeneticAlgorithmPayload(_) => "invalid_genetic_algorithm_payload",
            JobError::InvalidWatchpointsPayload(_) => "invalid_watchpoints_payload",
            JobError::InvalidExperimentSnapshot(_) => "invalid_experiment_snapshot",
            JobError::InvalidMlpPayload(_) => "invalid_mlp_payload",
            JobError::InvalidRfPayload(_) => "invalid_rf_payload",
        }
    }
}

/// Parâmetros GA validados (MVP: stub; campos alinhados a pipelines MLMS futuros).
#[derive(Debug)]
struct GeneticAlgorithmParams {
    population_size: u32,
    generations: u32,
    crossover_rate: f64,
    mutation_rate: f64,
    /// Perfil nomeado (ex.: espelho de presets MATLAB); opcional.
    ga_profile: Option<String>,
    /// Iterações do loop externo (conceito próximo a `cicles` em `ga_fr.m`); opcional — sem execução real no MVP.
    outer_iterations: Option<u32>,
}

/// Espectro 1D alinhado a `def_data_structure` (`mz`, `intensity` / `selected_i`); eixo `mz` estritamente crescente após normalização.
#[derive(Debug)]
struct Spectrum1D {
    mz: Vec<f64>,
    intensity: Vec<f64>,
}

fn json_array_to_f64_vec(arr: &[Value], field: &str) -> Result<Vec<f64>, String> {
    if arr.is_empty() {
        return Err(format!("{field} must be a non-empty array"));
    }
    if arr.len() > MAX_SPECTRUM_POINTS {
        return Err(format!(
            "{field} exceeds max length ({MAX_SPECTRUM_POINTS} points)"
        ));
    }
    let mut out = Vec::with_capacity(arr.len());
    for (i, v) in arr.iter().enumerate() {
        let n = v.as_f64().ok_or_else(|| {
            format!("{field}[{i}] must be a finite number")
        })?;
        if !n.is_finite() {
            return Err(format!("{field}[{i}] must be finite"));
        }
        out.push(n);
    }
    Ok(out)
}

/// Lê `mz` e `intensity` do objeto, ordena pelo eixo m/z e exige monotonia estrita.
fn parse_spectrum_1d(obj: &serde_json::Map<String, Value>) -> Result<Spectrum1D, String> {
    let arr_mz = obj
        .get("mz")
        .and_then(|v| v.as_array())
        .ok_or_else(|| "mz is required and must be a JSON array".to_string())?;
    let arr_i = obj
        .get("intensity")
        .and_then(|v| v.as_array())
        .ok_or_else(|| "intensity is required and must be a JSON array".to_string())?;

    let mz_raw = json_array_to_f64_vec(arr_mz, "mz")?;
    let intensity_raw = json_array_to_f64_vec(arr_i, "intensity")?;
    if mz_raw.len() != intensity_raw.len() {
        return Err(format!(
            "mz and intensity must have the same length (got {} vs {})",
            mz_raw.len(),
            intensity_raw.len()
        ));
    }

    let mut pairs: Vec<(f64, f64)> = mz_raw.into_iter().zip(intensity_raw).collect();
    pairs.sort_by(|a, b| a.0.total_cmp(&b.0));

    for w in pairs.windows(2) {
        if w[0].0 >= w[1].0 {
            return Err("mz values must be strictly increasing after sorting (no duplicate m/z)".into());
        }
    }

    let mz: Vec<f64> = pairs.iter().map(|p| p.0).collect();
    let intensity: Vec<f64> = pairs.iter().map(|p| p.1).collect();
    Ok(Spectrum1D { mz, intensity })
}

/// Campos numéricos de `preprocess.pks_select_mm` (OpenAPI `PksSelectMmStageParams`).
fn validate_pks_select_mm_params(obj: &serde_json::Map<String, Value>) -> Result<(), String> {
    match obj.get("fuzzy_window") {
        Some(v) => {
            let n = v
                .as_u64()
                .or_else(|| v.as_i64().and_then(|x| u64::try_from(x).ok()))
                .ok_or_else(|| "fuzzy_window must be a non-negative integer".to_string())?;
            if n > 4096 {
                return Err("fuzzy_window exceeds max (4096)".into());
            }
        }
        None => return Err("fuzzy_window is required".into()),
    }

    obj.get("power")
        .and_then(|v| v.as_f64())
        .filter(|x| x.is_finite())
        .ok_or_else(|| "power must be a finite number".to_string())?;

    if let Some(v) = obj.get("baseline_correction_half_width") {
        let b = v
            .as_f64()
            .filter(|x| x.is_finite())
            .ok_or_else(|| {
                "baseline_correction_half_width must be a finite number".to_string()
            })?;
        if b < 0.0 {
            return Err("baseline_correction_half_width must be >= 0".into());
        }
    }

    if let Some(v) = obj.get("allocation") {
        v.as_f64()
            .filter(|x| x.is_finite())
            .ok_or_else(|| "allocation must be a finite number".to_string())?;
    }

    if let Some(arr) = obj.get("column_range").and_then(|v| v.as_array()) {
        if arr.len() != 2 {
            return Err("column_range must have exactly two integers".into());
        }
        for (i, x) in arr.iter().enumerate() {
            x.as_i64()
                .ok_or_else(|| format!("column_range[{i}] must be an integer"))?;
        }
    }

    if let Some(v) = obj.get("mmf_mode") {
        let m = v
            .as_u64()
            .or_else(|| v.as_i64().and_then(|x| u64::try_from(x).ok()))
            .ok_or_else(|| "mmf_mode must be an integer".to_string())?;
        if !(1..=5).contains(&m) {
            return Err("mmf_mode must be between 1 and 5".into());
        }
    }

    Ok(())
}

fn trapezoid_area(mz: &[f64], y: &[f64]) -> f64 {
    if mz.len() < 2 {
        return 0.0;
    }
    let mut s = 0.0;
    for i in 0..mz.len() - 1 {
        let dx = mz[i + 1] - mz[i];
        s += 0.5 * (y[i] + y[i + 1]) * dx;
    }
    s
}

fn spectrum_summary_json(spec: &Spectrum1D) -> Value {
    let n = spec.mz.len();
    let sum_i: f64 = spec.intensity.iter().copied().sum();
    let mean_i = if n > 0 { sum_i / n as f64 } else { 0.0 };
    let min_mz = spec.mz.first().copied().unwrap_or(0.0);
    let max_mz = spec.mz.last().copied().unwrap_or(0.0);
    let area = trapezoid_area(&spec.mz, &spec.intensity);
    serde_json::json!({
        "point_count": n,
        "mz_min": min_mz,
        "mz_max": max_mz,
        "intensity_sum": sum_i,
        "intensity_mean": mean_i,
        "trapezoid_area_mz_intensity": area,
    })
}

/// Interpolação linear entre pontos; fora do intervalo de `mz`, usa o valor do extremo (*flat extrapolation*).
fn linear_sample_spectrum(mz: &[f64], y: &[f64], q: f64) -> f64 {
    let n = mz.len();
    if n == 0 {
        return f64::NAN;
    }
    if n == 1 {
        return y[0];
    }
    if q <= mz[0] {
        return y[0];
    }
    if q >= mz[n - 1] {
        return y[n - 1];
    }
    let hi = mz.partition_point(|&x| x < q);
    let lo = hi - 1;
    let z0 = mz[lo];
    let z1 = mz[hi];
    let dz = z1 - z0;
    if dz.abs() < f64::EPSILON {
        return y[lo];
    }
    let t = (q - z0) / dz;
    y[lo] + t * (y[hi] - y[lo])
}

fn parse_optional_ga_profile(
    obj: &serde_json::Map<String, Value>,
) -> Result<Option<String>, JobError> {
    match obj.get("ga_profile") {
        None | Some(Value::Null) => Ok(None),
        Some(v) => {
            let s = v.as_str().map(str::trim).ok_or_else(|| {
                JobError::InvalidGeneticAlgorithmPayload("ga_profile must be a string".into())
            })?;
            if s.is_empty() {
                return Err(JobError::InvalidGeneticAlgorithmPayload(
                    "ga_profile, if present, must be non-empty after trim".into(),
                ));
            }
            if s.len() > MAX_GA_PROFILE_LEN {
                return Err(JobError::InvalidGeneticAlgorithmPayload(format!(
                    "ga_profile exceeds max length ({MAX_GA_PROFILE_LEN})"
                )));
            }
            Ok(Some(s.to_string()))
        }
    }
}

fn parse_optional_outer_iterations(
    obj: &serde_json::Map<String, Value>,
) -> Result<Option<u32>, JobError> {
    match obj.get("outer_iterations") {
        None | Some(Value::Null) => Ok(None),
        Some(v) => {
            let n = v
                .as_u64()
                .filter(|&n| n > 0 && n <= u32::MAX as u64)
                .map(|n| n as u32)
                .ok_or_else(|| {
                    JobError::InvalidGeneticAlgorithmPayload(
                        "outer_iterations must be a positive integer".into(),
                    )
                })?;
            Ok(Some(n))
        }
    }
}

fn parse_ga_payload(payload: &Value) -> Result<(GeneticAlgorithmParams, Spectrum1D), JobError> {
    let obj = payload
        .as_object()
        .ok_or_else(|| JobError::InvalidGeneticAlgorithmPayload("payload must be a JSON object".into()))?;

    let spectrum = parse_spectrum_1d(obj).map_err(JobError::InvalidGeneticAlgorithmPayload)?;
    let ga_profile = parse_optional_ga_profile(obj)?;
    let outer_iterations = parse_optional_outer_iterations(obj)?;

    let population_size = obj
        .get("population_size")
        .and_then(|v| v.as_u64())
        .filter(|&n| n > 0 && n <= u32::MAX as u64)
        .map(|n| n as u32)
        .ok_or_else(|| {
            JobError::InvalidGeneticAlgorithmPayload(
                "population_size is required and must be a positive integer".into(),
            )
        })?;

    let generations = obj
        .get("generations")
        .and_then(|v| v.as_u64())
        .filter(|&n| n > 0 && n <= u32::MAX as u64)
        .map(|n| n as u32)
        .ok_or_else(|| {
            JobError::InvalidGeneticAlgorithmPayload(
                "generations is required and must be a positive integer".into(),
            )
        })?;

    let crossover_rate = obj
        .get("crossover_rate")
        .map(|v| {
            v.as_f64()
                .filter(|&x| (0.0..=1.0).contains(&x))
                .ok_or_else(|| {
                    JobError::InvalidGeneticAlgorithmPayload(
                        "crossover_rate must be a number between 0 and 1".into(),
                    )
                })
        })
        .transpose()?
        .unwrap_or(0.8);

    let mutation_rate = obj
        .get("mutation_rate")
        .map(|v| {
            v.as_f64()
                .filter(|&x| (0.0..=1.0).contains(&x))
                .ok_or_else(|| {
                    JobError::InvalidGeneticAlgorithmPayload(
                        "mutation_rate must be a number between 0 and 1".into(),
                    )
                })
        })
        .transpose()?
        .unwrap_or(0.01);

    Ok((
        GeneticAlgorithmParams {
            population_size,
            generations,
            crossover_rate,
            mutation_rate,
            ga_profile,
            outer_iterations,
        },
        spectrum,
    ))
}

/// Referência de espectro + posições de *watchpoints* para extração de características.
#[derive(Debug)]
struct WatchpointsParams {
    spectrum_ref: String,
    watchpoint_positions: Vec<f64>,
    spectrum: Spectrum1D,
}

fn parse_watchpoints_payload(payload: &Value) -> Result<WatchpointsParams, JobError> {
    let obj = payload
        .as_object()
        .ok_or_else(|| JobError::InvalidWatchpointsPayload("payload must be a JSON object".into()))?;

    let spectrum = parse_spectrum_1d(obj).map_err(JobError::InvalidWatchpointsPayload)?;

    let spectrum_ref = obj
        .get("spectrum_ref")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(String::from)
        .ok_or_else(|| {
            JobError::InvalidWatchpointsPayload(
                "spectrum_ref is required and must be a non-empty string".into(),
            )
        })?;

    let arr = obj
        .get("watchpoint_positions")
        .and_then(|v| v.as_array())
        .ok_or_else(|| {
            JobError::InvalidWatchpointsPayload(
                "watchpoint_positions is required and must be a non-empty array of numbers".into(),
            )
        })?;

    if arr.is_empty() {
        return Err(JobError::InvalidWatchpointsPayload(
            "watchpoint_positions must contain at least one number".into(),
        ));
    }

    let mut watchpoint_positions = Vec::with_capacity(arr.len());
    for (i, v) in arr.iter().enumerate() {
        let n = v.as_f64().ok_or_else(|| {
            JobError::InvalidWatchpointsPayload(format!(
                "watchpoint_positions[{i}] must be a number"
            ))
        })?;
        if !n.is_finite() {
            return Err(JobError::InvalidWatchpointsPayload(format!(
                "watchpoint_positions[{i}] must be finite"
            )));
        }
        watchpoint_positions.push(n);
    }

    Ok(WatchpointsParams {
        spectrum_ref,
        watchpoint_positions,
        spectrum,
    })
}

fn default_snapshot_version() -> u32 {
    1
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
struct ExperimentSnapshotIn {
    #[serde(default = "default_snapshot_version")]
    snapshot_version: u32,
    #[serde(default)]
    experiment_id: Option<String>,
    stages: Vec<ExperimentStageIn>,
}

#[derive(Debug, Deserialize)]
struct ExperimentStageIn {
    #[serde(default)]
    id: Option<String>,
    kind: String,
    #[serde(default = "empty_json_object")]
    params: Value,
}

fn empty_json_object() -> Value {
    Value::Object(serde_json::Map::new())
}

struct ExperimentState {
    spectrum: Option<Spectrum1D>,
    last_vector: Option<Vec<f64>>,
}

fn merge_spectrum_into_params(
    stage_index: usize,
    base: &Value,
    spec: &Spectrum1D,
) -> Result<Value, JobError> {
    let mut obj = base
        .as_object()
        .cloned()
        .ok_or_else(|| {
            JobError::InvalidExperimentSnapshot(format!(
                "stage[{stage_index}]: params must be a JSON object"
            ))
        })?;
    obj.insert("mz".into(), serde_json::json!(spec.mz.clone()));
    obj.insert("intensity".into(), serde_json::json!(spec.intensity.clone()));
    Ok(Value::Object(obj))
}

fn json_array_to_finite_f64_vec(arr: &[Value], field: &str, max_len: usize) -> Result<Vec<f64>, String> {
    if arr.is_empty() {
        return Err(format!("{field} must be a non-empty array"));
    }
    if arr.len() > max_len {
        return Err(format!("{field} exceeds max length ({max_len})"));
    }
    let mut out = Vec::with_capacity(arr.len());
    for (i, v) in arr.iter().enumerate() {
        let n = v
            .as_f64()
            .ok_or_else(|| format!("{field}[{i}] must be a finite number"))?;
        if !n.is_finite() {
            return Err(format!("{field}[{i}] must be finite"));
        }
        out.push(n);
    }
    Ok(out)
}

fn json_array_to_f64_vec_mlp(arr: &[Value], field: &str) -> Result<Vec<f64>, JobError> {
    json_array_to_finite_f64_vec(arr, field, 8192).map_err(JobError::InvalidExperimentSnapshot)
}

/// Pesos determinísticos para `model.mlp_stub` (sem RNG do sistema).
fn deterministic_weight_matrix(rows: usize, cols: usize, seed: u64) -> Vec<f64> {
    let mut s = seed;
    let mut v = Vec::with_capacity(rows.saturating_mul(cols));
    for _ in 0..rows * cols {
        s = s
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        let x = ((s >> 11) & 0xfffff) as f64 / 1048576.0;
        v.push((x - 0.5) * 0.5);
    }
    v
}

fn mlp_tanh_layer(input: &[f64], out_dim: usize, weights: &[f64]) -> Vec<f64> {
    let in_dim = input.len();
    let mut out = vec![0.0; out_dim];
    for (j, slot) in out.iter_mut().enumerate() {
        let off = j * in_dim;
        let mut acc = 0.0;
        for k in 0..in_dim {
            acc += weights[off + k] * input[k];
        }
        *slot = acc.tanh();
    }
    out
}

/// Job de topo `mlms.mlp`: mesmo núcleo que o estágio `model.mlp_stub`; **obriga** `input` no payload e rejeita chaves desconhecidas.
fn parse_mlp_standalone_payload(payload: &Value) -> Result<(Vec<f64>, usize, u64), JobError> {
    let obj = payload.as_object().ok_or_else(|| {
        JobError::InvalidMlpPayload("payload must be a JSON object".into())
    })?;
    const ALLOWED: &[&str] = &["input", "out_dim", "seed"];
    for k in obj.keys() {
        if !ALLOWED.contains(&k.as_str()) {
            return Err(JobError::InvalidMlpPayload(format!(
                "unknown field in mlp payload: {k}"
            )));
        }
    }
    let arr = obj
        .get("input")
        .and_then(|v| v.as_array())
        .ok_or_else(|| {
            JobError::InvalidMlpPayload("input is required and must be a JSON array".into())
        })?;
    let input = json_array_to_finite_f64_vec(arr, "input", 8192).map_err(JobError::InvalidMlpPayload)?;

    let out_dim = match obj.get("out_dim") {
        None | Some(Value::Null) => 4usize,
        Some(v) => v
            .as_u64()
            .filter(|&n| n > 0 && n <= 256)
            .map(|n| n as usize)
            .ok_or_else(|| {
                JobError::InvalidMlpPayload(
                    "out_dim must be an integer from 1 to 256 (JSON)".into(),
                )
            })?,
    };

    let seed = match obj.get("seed") {
        None | Some(Value::Null) => 42u64,
        Some(v) => v.as_u64().ok_or_else(|| {
            JobError::InvalidMlpPayload("seed must be a non-negative integer (JSON)".into())
        })?,
    };

    Ok((input, out_dim, seed))
}

fn run_standalone_mlp(payload: &Value) -> Result<Value, JobError> {
    let (input, out_dim, seed) = parse_mlp_standalone_payload(payload)?;
    let w = deterministic_weight_matrix(out_dim, input.len(), seed);
    let output = mlp_tanh_layer(&input, out_dim, &w);
    Ok(serde_json::json!({
        "processed": true,
        "algorithm": "mlp",
        "out_dim": out_dim,
        "input_dim": input.len(),
        "output": output,
        "worker_version": env!("CARGO_PKG_VERSION"),
        "notes": "MVP — single dense layer with tanh; deterministic weights from seed; same numerics as experiment_snapshot stage model.mlp_stub."
    }))
}

#[derive(Debug)]
struct RfCoreResult {
    n_trees: u32,
    n_classes: u32,
    predicted_class: u32,
    class_vote_counts: Vec<u32>,
    predict_proba: Vec<f64>,
    train_error_stub: f64,
}

fn rf_input_fingerprint(input: &[f64]) -> u64 {
    let mut h = 0xcbf29ce484222325_u64;
    for &x in input {
        h ^= x.to_bits();
        h = h.wrapping_mul(0x100000001b3);
    }
    h
}

fn mix_rf_seed_tree(seed: u64, tree: u32) -> u64 {
    seed ^ (tree as u64).wrapping_mul(0x9e37_79b9_7f4a_7c15)
}

/// Voto de classe por "árvore" sintética — determinístico a partir de `seed` e `input`.
fn rf_tree_class_vote(input: &[f64], tree: u32, seed: u64, n_classes: u32) -> u32 {
    let mut s = mix_rf_seed_tree(seed, tree);
    let mut acc = 0.0_f64;
    for (k, &x) in input.iter().enumerate() {
        s = s
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407 ^ (k as u64));
        let w = (((s >> 11) & 0xfffff) as f64) / 1_048_576.0 - 0.5;
        acc += w * x;
    }
    let h = acc.to_bits() ^ s;
    (h % n_classes as u64) as u32
}

fn run_rf_core(input: &[f64], n_trees: u32, n_classes: u32, seed: u64) -> RfCoreResult {
    let mut counts = vec![0u32; n_classes as usize];
    for t in 0..n_trees {
        let c = rf_tree_class_vote(input, t, seed, n_classes);
        counts[c as usize] += 1;
    }
    let mut predicted_class = 0u32;
    let mut max_votes = 0u32;
    for (i, &c) in counts.iter().enumerate() {
        if c > max_votes {
            max_votes = c;
            predicted_class = i as u32;
        }
    }
    let nt = n_trees as f64;
    let predict_proba: Vec<f64> = counts.iter().map(|&c| c as f64 / nt).collect();
    let inh = rf_input_fingerprint(input);
    let err_seed = seed
        .wrapping_mul(0x5851f42d4c957f2d)
        .wrapping_add(inh);
    let train_error_stub = (err_seed % 10_000) as f64 / 20_000.0;
    RfCoreResult {
        n_trees,
        n_classes,
        predicted_class,
        class_vote_counts: counts,
        predict_proba,
        train_error_stub,
    }
}

/// Job de topo `mlms.random_forest`: mesmo núcleo que `model.rf_stub`; chaves estritas.
fn parse_rf_standalone_payload(payload: &Value) -> Result<(Vec<f64>, u32, u32, u64), JobError> {
    let obj = payload.as_object().ok_or_else(|| {
        JobError::InvalidRfPayload("payload must be a JSON object".into())
    })?;
    const ALLOWED: &[&str] = &["input", "n_trees", "n_classes", "seed"];
    for k in obj.keys() {
        if !ALLOWED.contains(&k.as_str()) {
            return Err(JobError::InvalidRfPayload(format!(
                "unknown field in random_forest payload: {k}"
            )));
        }
    }
    let arr = obj
        .get("input")
        .and_then(|v| v.as_array())
        .ok_or_else(|| {
            JobError::InvalidRfPayload("input is required and must be a JSON array".into())
        })?;
    let input = json_array_to_finite_f64_vec(arr, "input", 8192).map_err(JobError::InvalidRfPayload)?;

    let n_trees = match obj.get("n_trees") {
        None | Some(Value::Null) => DEFAULT_RF_TREES,
        Some(v) => v
            .as_u64()
            .filter(|&n| n > 0 && n <= MAX_RF_TREES as u64)
            .map(|n| n as u32)
            .ok_or_else(|| {
                JobError::InvalidRfPayload(format!(
                    "n_trees must be an integer from 1 to {MAX_RF_TREES} (JSON)"
                ))
            })?,
    };

    let n_classes = match obj.get("n_classes") {
        None | Some(Value::Null) => DEFAULT_RF_CLASSES,
        Some(v) => v
            .as_u64()
            .filter(|&n| n >= MIN_RF_CLASSES as u64 && n <= MAX_RF_CLASSES as u64)
            .map(|n| n as u32)
            .ok_or_else(|| {
                JobError::InvalidRfPayload(format!(
                    "n_classes must be an integer from {MIN_RF_CLASSES} to {MAX_RF_CLASSES} (JSON)"
                ))
            })?,
    };

    let seed = match obj.get("seed") {
        None | Some(Value::Null) => 42u64,
        Some(v) => v.as_u64().ok_or_else(|| {
            JobError::InvalidRfPayload("seed must be a non-negative integer (JSON)".into())
        })?,
    };

    Ok((input, n_trees, n_classes, seed))
}

fn run_standalone_rf(payload: &Value) -> Result<Value, JobError> {
    let (input, n_trees, n_classes, seed) = parse_rf_standalone_payload(payload)?;
    let r = run_rf_core(&input, n_trees, n_classes, seed);
    Ok(serde_json::json!({
        "processed": true,
        "algorithm": "random_forest",
        "n_trees": r.n_trees,
        "n_classes": r.n_classes,
        "input_dim": input.len(),
        "predicted_class": r.predicted_class,
        "class_vote_counts": r.class_vote_counts,
        "predict_proba": r.predict_proba,
        "train_error_stub": r.train_error_stub,
        "worker_version": env!("CARGO_PKG_VERSION"),
        "notes": "MVP — votos de classe determinísticos por árvore sintética (sem floresta real); mesma semântica numérica que experiment_snapshot stage model.rf_stub. train_error_stub é escalar derivado de seed+input (não métrica de treino real)."
    }))
}

/// Lê `n_trees`, `n_classes`, `seed` de `params` (estágio); omissões = defaults do job standalone.
fn parse_rf_stage_numeric_params(
    obj: &serde_json::Map<String, Value>,
) -> Result<(u32, u32, u64), JobError> {
    let n_trees = match obj.get("n_trees") {
        None | Some(Value::Null) => DEFAULT_RF_TREES,
        Some(v) => v
            .as_u64()
            .filter(|&n| n > 0 && n <= MAX_RF_TREES as u64)
            .map(|n| n as u32)
            .ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "n_trees must be an integer from 1 to {MAX_RF_TREES} (JSON)"
                ))
            })?,
    };
    let n_classes = match obj.get("n_classes") {
        None | Some(Value::Null) => DEFAULT_RF_CLASSES,
        Some(v) => v
            .as_u64()
            .filter(|&n| n >= MIN_RF_CLASSES as u64 && n <= MAX_RF_CLASSES as u64)
            .map(|n| n as u32)
            .ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "n_classes must be an integer from {MIN_RF_CLASSES} to {MAX_RF_CLASSES} (JSON)"
                ))
            })?,
    };
    let seed = match obj.get("seed") {
        None | Some(Value::Null) => 42u64,
        Some(v) => v.as_u64().ok_or_else(|| {
            JobError::InvalidExperimentSnapshot(
                "seed must be a non-negative integer (JSON)".into(),
            )
        })?,
    };
    Ok((n_trees, n_classes, seed))
}

fn execute_experiment_stage(
    index: usize,
    kind: &str,
    params: &Value,
    stage_id: &Option<String>,
    state: &mut ExperimentState,
) -> Result<Value, JobError> {
    match kind {
        "preprocess.canonical_spectrum" => {
            let obj = params.as_object().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] preprocess.canonical_spectrum: params must be a JSON object"
                ))
            })?;
            let spec = parse_spectrum_1d(obj).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] preprocess.canonical_spectrum: {e}"
                ))
            })?;
            let summary = spectrum_summary_json(&spec);
            state.spectrum = Some(spec);
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "spectrum_summary": summary,
            }))
        }
        "preprocess.pks_select_mm" => {
            let obj = params.as_object().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] preprocess.pks_select_mm: params must be a JSON object"
                ))
            })?;
            validate_pks_select_mm_params(obj).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] preprocess.pks_select_mm: {e}"
                ))
            })?;
            let spec = parse_spectrum_1d(obj).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] preprocess.pks_select_mm: {e}"
                ))
            })?;
            let summary = spectrum_summary_json(&spec);
            state.spectrum = Some(spec);
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "spectrum_summary": summary,
                "legacy_matlab": "fn_pks_select_mm.m",
                "mmf_reference": "fn_mmv_fuzzy.m",
                "mvp_note": "params validated; MMF/peak math not executed in worker MVP",
            }))
        }
        "features.watchpoints" => {
            let spec = state.spectrum.as_ref().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] features.watchpoints: no spectrum in pipeline (expected preprocess.canonical_spectrum or preprocess.pks_select_mm first)"
                ))
            })?;
            let merged = merge_spectrum_into_params(index, params, spec)?;
            let p = parse_watchpoints_payload(&merged).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] features.watchpoints: {e}"
                ))
            })?;
            let watchpoint_intensities: Vec<f64> = p
                .watchpoint_positions
                .iter()
                .map(|&q| linear_sample_spectrum(&p.spectrum.mz, &p.spectrum.intensity, q))
                .collect();
            state.last_vector = Some(watchpoint_intensities.clone());
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "spectrum_ref": p.spectrum_ref,
                "watchpoint_positions": p.watchpoint_positions,
                "watchpoint_intensities": watchpoint_intensities,
                "feature_count": p.watchpoint_positions.len(),
                "spectrum_summary": spectrum_summary_json(&p.spectrum),
            }))
        }
        "model.genetic_algorithm_summary" => {
            let spec = state.spectrum.as_ref().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] model.genetic_algorithm_summary: no spectrum in pipeline (expected preprocess.canonical_spectrum or preprocess.pks_select_mm first)"
                ))
            })?;
            let merged = merge_spectrum_into_params(index, params, spec)?;
            let (ga, sp) = parse_ga_payload(&merged).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] model.genetic_algorithm_summary: {e}"
                ))
            })?;
            let n = sp.mz.len();
            let sum_i: f64 = sp.intensity.iter().copied().sum();
            let mean_i = if n > 0 { sum_i / n as f64 } else { 0.0 };
            let area = trapezoid_area(&sp.mz, &sp.intensity);
            state.last_vector = Some(vec![mean_i, area, n as f64, sum_i]);
            let summary = spectrum_summary_json(&sp);
            let mut out = serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "population_size": ga.population_size,
                "generations": ga.generations,
                "crossover_rate": ga.crossover_rate,
                "mutation_rate": ga.mutation_rate,
                "spectrum_summary": summary,
            });
            if let Some(obj) = out.as_object_mut() {
                if let Some(ref p) = ga.ga_profile {
                    obj.insert("ga_profile".into(), serde_json::json!(p));
                }
                if let Some(oi) = ga.outer_iterations {
                    obj.insert("outer_iterations".into(), serde_json::json!(oi));
                }
            }
            Ok(out)
        }
        "model.mlp_stub" => {
            let obj = params.as_object().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] model.mlp_stub: params must be a JSON object"
                ))
            })?;
            let out_dim = obj
                .get("out_dim")
                .and_then(|v| v.as_u64())
                .filter(|&n| n > 0 && n <= 256)
                .map(|n| n as usize)
                .unwrap_or(4);
            let seed = obj.get("seed").and_then(|v| v.as_u64()).unwrap_or(42);
            let input: Vec<f64> =
                if let Some(arr) = obj.get("input").and_then(|v| v.as_array()) {
                    json_array_to_f64_vec_mlp(arr, "input")?
                } else if let Some(lv) = state.last_vector.as_ref() {
                    lv.clone()
                } else {
                    return Err(JobError::InvalidExperimentSnapshot(format!(
                        "stage[{index}] model.mlp_stub: provide params.input or a prior feature vector"
                    )));
                };
            let w = deterministic_weight_matrix(out_dim, input.len(), seed);
            let output = mlp_tanh_layer(&input, out_dim, &w);
            state.last_vector = Some(output.clone());
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "out_dim": out_dim,
                "input_dim": input.len(),
                "output": output,
            }))
        }
        "model.rf_stub" => {
            let obj = params.as_object().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] model.rf_stub: params must be a JSON object"
                ))
            })?;
            let (n_trees, n_classes, seed) = parse_rf_stage_numeric_params(obj).map_err(|e| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] model.rf_stub: {e}"
                ))
            })?;
            let input: Vec<f64> =
                if let Some(arr) = obj.get("input").and_then(|v| v.as_array()) {
                    json_array_to_f64_vec_mlp(arr, "input")?
                } else if let Some(lv) = state.last_vector.as_ref() {
                    lv.clone()
                } else {
                    return Err(JobError::InvalidExperimentSnapshot(format!(
                        "stage[{index}] model.rf_stub: provide params.input or a prior feature vector"
                    )));
                };
            let r = run_rf_core(&input, n_trees, n_classes, seed);
            state.last_vector = Some(r.predict_proba.clone());
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "n_trees": r.n_trees,
                "n_classes": r.n_classes,
                "input_dim": input.len(),
                "predicted_class": r.predicted_class,
                "class_vote_counts": r.class_vote_counts,
                "predict_proba": r.predict_proba,
                "train_error_stub": r.train_error_stub,
            }))
        }
        "eval.vector_stats" => {
            let v = state.last_vector.as_ref().ok_or_else(|| {
                JobError::InvalidExperimentSnapshot(format!(
                    "stage[{index}] eval.vector_stats: no feature vector (run a feature or model stage first)"
                ))
            })?;
            let sum: f64 = v.iter().sum();
            let mean = sum / v.len() as f64;
            let min = v.iter().copied().fold(f64::INFINITY, f64::min);
            let max = v.iter().copied().fold(f64::NEG_INFINITY, f64::max);
            let l2 = v.iter().map(|x| x * x).sum::<f64>().sqrt();
            Ok(serde_json::json!({
                "kind": kind,
                "id": stage_id,
                "len": v.len(),
                "mean": mean,
                "min": min,
                "max": max,
                "l2_norm": l2,
            }))
        }
        other => Err(JobError::InvalidExperimentSnapshot(format!(
            "stage[{index}]: unknown kind {other:?} (MVP: preprocess.canonical_spectrum, preprocess.pks_select_mm, features.watchpoints, model.genetic_algorithm_summary, model.mlp_stub, model.rf_stub, eval.vector_stats)"
        ))),
    }
}

/// Aceita o envelope do BFF `{ schema_version, payload: { stages, ... } }` ou o formato plano legado.
fn normalize_experiment_snapshot_payload(payload: &Value) -> Result<Value, JobError> {
    let obj = payload.as_object().ok_or_else(|| {
        JobError::InvalidExperimentSnapshot(
            "experiment snapshot payload must be a JSON object".into(),
        )
    })?;
    let inner_is_obj = obj
        .get("payload")
        .map(|p| p.is_object())
        .unwrap_or(false);
    if obj.get("schema_version").is_some() || inner_is_obj {
        if !(obj.get("schema_version").is_some() && inner_is_obj) {
            return Err(JobError::InvalidExperimentSnapshot(
                "BFF envelope requires schema_version and a JSON object payload".into(),
            ));
        }
        let sv = obj
            .get("schema_version")
            .and_then(|v| v.as_u64())
            .ok_or_else(|| {
                JobError::InvalidExperimentSnapshot("schema_version must be an unsigned integer".into())
            })?;
        if sv != 1 {
            return Err(JobError::InvalidExperimentSnapshot(format!(
                "unsupported schema_version {sv} (only 1 supported)"
            )));
        }
        return Ok(obj.get("payload").cloned().unwrap());
    }
    Ok(payload.clone())
}

fn run_experiment_snapshot(payload: &Value) -> Result<Value, JobError> {
    let normalized = normalize_experiment_snapshot_payload(payload)?;
    let snap: ExperimentSnapshotIn = serde_json::from_value(normalized).map_err(|e| {
        JobError::InvalidExperimentSnapshot(format!("invalid experiment snapshot JSON: {e}"))
    })?;
    if snap.snapshot_version != 1 {
        return Err(JobError::InvalidExperimentSnapshot(format!(
            "unsupported snapshot_version {} (only 1 supported)",
            snap.snapshot_version
        )));
    }
    if let Some(ref id) = snap.experiment_id {
        if id.len() > MAX_EXPERIMENT_ID_LEN {
            return Err(JobError::InvalidExperimentSnapshot(format!(
                "experiment_id exceeds max length ({MAX_EXPERIMENT_ID_LEN})"
            )));
        }
    }
    if snap.stages.is_empty() || snap.stages.len() > MAX_EXPERIMENT_STAGES {
        return Err(JobError::InvalidExperimentSnapshot(format!(
            "stages must be non-empty and at most {MAX_EXPERIMENT_STAGES} entries"
        )));
    }

    let mut state = ExperimentState {
        spectrum: None,
        last_vector: None,
    };
    let mut stage_results: Vec<Value> = Vec::with_capacity(snap.stages.len());

    for (i, st) in snap.stages.iter().enumerate() {
        let kind = st.kind.trim();
        if kind.is_empty() || kind.len() > MAX_STAGE_KIND_LEN {
            return Err(JobError::InvalidExperimentSnapshot(format!(
                "stage[{i}]: kind must be non-empty and at most {MAX_STAGE_KIND_LEN} chars after trim"
            )));
        }
        let out = execute_experiment_stage(i, kind, &st.params, &st.id, &mut state)?;
        stage_results.push(out);
    }

    let final_feature_vector = state
        .last_vector
        .as_ref()
        .map(|v| serde_json::json!(v));

    Ok(serde_json::json!({
        "processed": true,
        "snapshot_version": snap.snapshot_version,
        "experiment_id": snap.experiment_id,
        "stages_executed": stage_results.len(),
        "stage_results": stage_results,
        "final_feature_vector": final_feature_vector,
        "worker_version": env!("CARGO_PKG_VERSION"),
        "notes": "MVP — encadeamento MS-ML leve: espectro canónico → features (watchpoints ou resumo GA) → camada tanh ou RF stub determinísticos → estatísticas do vector; sem GA/MATLAB reais. Parâmetros opcionais ga_profile / outer_iterations em estágios GA são validados e ecoados (SOF-53), sem loops externos reais."
    }))
}

#[derive(Debug, Serialize)]
struct HealthBody {
    status: &'static str,
    service: &'static str,
    version: &'static str,
}

async fn health() -> Json<HealthBody> {
    Json(HealthBody {
        status: "ok",
        service: "mlms-worker",
        version: env!("CARGO_PKG_VERSION"),
    })
}

/// Readiness probe — same contract as liveness until optional deps (queue, FS) exist.
async fn ready() -> Json<HealthBody> {
    health().await
}

fn process_job(req: JobRequest) -> Result<Value, JobError> {
    let jt = req.job_type.trim();
    if jt.is_empty() || jt.len() > MAX_JOB_TYPE_LEN {
        return Err(JobError::InvalidJobType);
    }
    match jt {
        "mlms.echo" => Ok(serde_json::json!({
            "echo": req.payload,
            "worker_version": env!("CARGO_PKG_VERSION"),
        })),
        "mlms.pipeline_stub" => {
            // MVP: no real spectra/GA — placeholder until MLMS binaries or MATLAB bridge exist.
            let stage = req
                .payload
                .get("stage")
                .and_then(|v| v.as_str())
                .unwrap_or("default");
            Ok(serde_json::json!({
                "processed": true,
                "stage": stage,
                "worker_version": env!("CARGO_PKG_VERSION"),
                "notes": "MVP stub — replace with real MLMS pipeline when available.",
            }))
        }
        "mlms.genetic_algorithm" => {
            let (p, spec) = parse_ga_payload(&req.payload)?;
            let spectrum_summary = spectrum_summary_json(&spec);
            let mut result = serde_json::json!({
                "processed": true,
                "algorithm": "genetic_algorithm",
                "population_size": p.population_size,
                "generations": p.generations,
                "crossover_rate": p.crossover_rate,
                "mutation_rate": p.mutation_rate,
                "spectrum_summary": spectrum_summary,
                "worker_version": env!("CARGO_PKG_VERSION"),
                "notes": "MVP — spectral axis read and summarized (trapezoid area, means); no GA/search execution (see MATLAB ga_fr.m for full pipeline). ga_profile / outer_iterations are accepted for contract alignment (SOF-53); not executed.",
            });
            if let Some(obj) = result.as_object_mut() {
                if let Some(ref gp) = p.ga_profile {
                    obj.insert("ga_profile".into(), serde_json::json!(gp));
                }
                if let Some(oi) = p.outer_iterations {
                    obj.insert("outer_iterations".into(), serde_json::json!(oi));
                }
            }
            Ok(result)
        }
        "mlms.watchpoints" => {
            let p = parse_watchpoints_payload(&req.payload)?;
            let watchpoint_intensities: Vec<f64> = p
                .watchpoint_positions
                .iter()
                .map(|&q| linear_sample_spectrum(&p.spectrum.mz, &p.spectrum.intensity, q))
                .collect();
            Ok(serde_json::json!({
                "processed": true,
                "spectrum_ref": p.spectrum_ref,
                "watchpoint_positions": p.watchpoint_positions,
                "watchpoint_intensities": watchpoint_intensities,
                "feature_count": p.watchpoint_positions.len(),
                "spectrum_summary": spectrum_summary_json(&p.spectrum),
                "worker_version": env!("CARGO_PKG_VERSION"),
                "notes": "MVP — linear interpolation of intensity along mz at watchpoint m/z; flat extrapolation outside [mz_min, mz_max]. See ga_watch_points.m for full GA.",
            }))
        }
        "mlms.experiment_snapshot" => run_experiment_snapshot(&req.payload),
        "mlms.mlp" => run_standalone_mlp(&req.payload),
        "mlms.random_forest" => run_standalone_rf(&req.payload),
        other => Err(JobError::UnknownJobType(other.to_owned())),
    }
}

fn bearer_tokens_equal(provided: &str, expected: &str) -> bool {
    if provided.len() != expected.len() {
        return false;
    }
    provided.as_bytes().ct_eq(expected.as_bytes()).into()
}

async fn internal_bearer_middleware(
    State(state): State<AppState>,
    request: Request<Body>,
    next: Next,
) -> Response {
    if let Some(ref expected) = state.internal_token {
        let ok = request
            .headers()
            .get(header::AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .and_then(|h| h.strip_prefix("Bearer "))
            .map(|token| bearer_tokens_equal(token, expected))
            .unwrap_or(false);
        if !ok {
            return StatusCode::UNAUTHORIZED.into_response();
        }
    }
    next.run(request).await
}

async fn submit_job(
    State(_state): State<AppState>,
    Json(body): Json<JobRequest>,
) -> (StatusCode, Json<JobResponse>) {
    let job_id = body.job_id.unwrap_or_else(Uuid::new_v4);

    match process_job(body) {
        Ok(value) => (
            StatusCode::OK,
            Json(JobResponse {
                job_id,
                status: JobStatus::Completed,
                result: Some(value),
                error: None,
            }),
        ),
        Err(e) => (
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(JobResponse {
                job_id,
                status: JobStatus::Failed,
                result: None,
                error: Some(JobErrorBody {
                    code: e.code().to_string(),
                    message: e.to_string(),
                }),
            }),
        ),
    }
}

fn app_with_state(state: AppState) -> Router {
    let public = Router::new()
        .route("/health", get(health))
        .route("/ready", get(ready));

    let jobs = Router::new()
        .route("/v1/jobs", post(submit_job))
        .layer(middleware::from_fn_with_state(
            state.clone(),
            internal_bearer_middleware,
        ))
        .layer(RequestBodyLimitLayer::new(MAX_JOB_BODY_BYTES));

    Router::new()
        .merge(public)
        .merge(jobs)
        .layer(TraceLayer::new_for_http())
        .layer(SetResponseHeaderLayer::if_not_present(
            header::X_CONTENT_TYPE_OPTIONS,
            axum::http::HeaderValue::from_static("nosniff"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            header::X_FRAME_OPTIONS,
            axum::http::HeaderValue::from_static("DENY"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            header::REFERRER_POLICY,
            axum::http::HeaderValue::from_static("no-referrer"),
        ))
        .with_state(state)
}

#[cfg(test)]
fn app() -> Router {
    app_with_state(AppState {
        internal_token: None,
    })
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let env_filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    let json_logs = std::env::var("MLMS_LOG_FORMAT")
        .map(|v| v.eq_ignore_ascii_case("json"))
        .unwrap_or(false);

    if json_logs {
        tracing_subscriber::registry()
            .with(env_filter.clone())
            .with(tracing_subscriber::fmt::layer().json())
            .init();
    } else {
        tracing_subscriber::registry()
            .with(env_filter)
            .with(tracing_subscriber::fmt::layer())
            .init();
    }

    // Cloud Run sets `PORT`; local/Tilt may use `MLMS_WORKER_PORT`.
    let port: u16 = std::env::var("MLMS_WORKER_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .or_else(|| std::env::var("PORT").ok().and_then(|s| s.parse().ok()))
        .unwrap_or(8080);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let internal_token = std::env::var("MLMS_WORKER_INTERNAL_TOKEN")
        .ok()
        .filter(|s| !s.trim().is_empty());
    if internal_token.is_some() {
        tracing::info!("MLMS_WORKER_INTERNAL_TOKEN is set; POST /v1/jobs requires Bearer auth");
    }
    let state = AppState { internal_token };
    tracing::info!(%addr, "mlms-worker listening");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app_with_state(state))
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        () = ctrl_c => {},
        () = terminate => {},
    }
    tracing::info!("shutdown signal received, finishing");
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use tower::ServiceExt;

    #[tokio::test]
    async fn health_ok() {
        let app = app();
        let res = app
            .oneshot(
                Request::builder()
                    .uri("/health")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        assert_eq!(
            res.headers()
                .get(header::X_CONTENT_TYPE_OPTIONS)
                .and_then(|v| v.to_str().ok()),
            Some("nosniff")
        );
    }

    #[tokio::test]
    async fn ready_ok() {
        let app = app();
        let res = app
            .oneshot(
                Request::builder()
                    .uri("/ready")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn job_echo() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.echo",
            "payload": { "x": 1 }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn jobs_unauthorized_when_token_configured() {
        let app = app_with_state(AppState {
            internal_token: Some("expected-secret".into()),
        });
        let body = serde_json::json!({ "job_type": "mlms.echo", "payload": {} });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNAUTHORIZED);
    }

    #[tokio::test]
    async fn jobs_ok_with_bearer_when_token_configured() {
        let app = app_with_state(AppState {
            internal_token: Some("expected-secret".into()),
        });
        let body = serde_json::json!({ "job_type": "mlms.echo", "payload": {} });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .header("authorization", "Bearer expected-secret")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn job_invalid_job_type_empty_returns_422() {
        let app = app();
        let body = serde_json::json!({ "job_type": "   ", "payload": {} });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    #[tokio::test]
    async fn job_body_over_limit_returns_413() {
        let app = app();
        let pad = "a".repeat(MAX_JOB_BODY_BYTES + 64);
        let body = format!(
            r#"{{"job_type":"mlms.echo","payload":{{"pad":"{}"}}}}"#,
            pad
        );
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::PAYLOAD_TOO_LARGE);
    }

    #[tokio::test]
    async fn job_genetic_algorithm_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 50,
                "generations": 100,
                "mz": [100.0, 200.0, 300.0],
                "intensity": [1.0, 4.0, 1.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["population_size"], 50);
        assert_eq!(v["result"]["generations"], 100);
        assert_eq!(v["result"]["spectrum_summary"]["point_count"], 3);
        assert_eq!(v["result"]["spectrum_summary"]["intensity_mean"], 2.0);
    }

    #[tokio::test]
    async fn job_genetic_algorithm_ga_profile_and_outer_iterations_echoed() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 50,
                "generations": 100,
                "ga_profile": "matlab_def_gaopt_like",
                "outer_iterations": 5,
                "mz": [100.0, 200.0, 300.0],
                "intensity": [1.0, 4.0, 1.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["ga_profile"], "matlab_def_gaopt_like");
        assert_eq!(v["result"]["outer_iterations"], 5);
    }

    #[tokio::test]
    async fn job_genetic_algorithm_empty_ga_profile_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 10,
                "generations": 10,
                "ga_profile": "   ",
                "mz": [1.0],
                "intensity": [1.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    #[tokio::test]
    async fn job_genetic_algorithm_outer_iterations_zero_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 10,
                "generations": 10,
                "outer_iterations": 0,
                "mz": [1.0],
                "intensity": [1.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    #[tokio::test]
    async fn job_genetic_algorithm_missing_spectrum_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 10,
                "generations": 10
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_genetic_algorithm_payload");
    }

    #[tokio::test]
    async fn job_genetic_algorithm_invalid_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.genetic_algorithm",
            "payload": {
                "population_size": 0,
                "generations": 10,
                "mz": [1.0],
                "intensity": [1.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_genetic_algorithm_payload");
    }

    #[tokio::test]
    async fn job_watchpoints_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.watchpoints",
            "payload": {
                "spectrum_ref": "study-1/run-a",
                "mz": [100.0, 200.0, 300.0],
                "intensity": [1.0, 2.0, 3.0],
                "watchpoint_positions": [200.0, 150.0]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["watchpoint_intensities"][0], 2.0);
        // 150 is midpoint between (100,1) and (200,2) → 1.5
        assert_eq!(v["result"]["watchpoint_intensities"][1], 1.5);
    }

    #[tokio::test]
    async fn job_mlp_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.mlp",
            "payload": {
                "input": [1.0, -0.5, 2.0],
                "out_dim": 2,
                "seed": 7
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["algorithm"], "mlp");
        assert_eq!(v["result"]["out_dim"], 2);
        assert_eq!(v["result"]["input_dim"], 3);
        assert!(v["result"]["output"].as_array().unwrap().len() == 2);
    }

    #[tokio::test]
    async fn job_random_forest_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.random_forest",
            "payload": {
                "input": [1.0, -0.5, 2.0],
                "n_trees": 8,
                "n_classes": 3,
                "seed": 7
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["algorithm"], "random_forest");
        assert_eq!(v["result"]["n_trees"], 8);
        assert_eq!(v["result"]["n_classes"], 3);
        assert_eq!(v["result"]["input_dim"], 3);
        assert!(v["result"]["predicted_class"].is_number());
        assert_eq!(v["result"]["class_vote_counts"].as_array().unwrap().len(), 3);
        assert_eq!(v["result"]["predict_proba"].as_array().unwrap().len(), 3);
        assert!(v["result"]["train_error_stub"].is_number());
    }

    #[tokio::test]
    async fn job_random_forest_unknown_field_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.random_forest",
            "payload": {
                "input": [1.0],
                "extra": 1
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_rf_payload");
    }

    #[tokio::test]
    async fn job_random_forest_missing_input_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.random_forest",
            "payload": { "n_trees": 4 }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_rf_payload");
    }

    #[tokio::test]
    async fn job_mlp_unknown_field_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.mlp",
            "payload": {
                "input": [1.0],
                "extra": 1
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_mlp_payload");
    }

    #[tokio::test]
    async fn job_mlp_missing_input_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.mlp",
            "payload": { "out_dim": 4 }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_mlp_payload");
    }

    #[tokio::test]
    async fn job_watchpoints_empty_array_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.watchpoints",
            "payload": {
                "spectrum_ref": "x",
                "mz": [1.0, 2.0],
                "intensity": [1.0, 2.0],
                "watchpoint_positions": []
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_watchpoints_payload");
    }

    #[tokio::test]
    async fn job_experiment_snapshot_pipeline_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.experiment_snapshot",
            "payload": {
                "snapshot_version": 1,
                "experiment_id": "exp-demo-1",
                "stages": [
                    {
                        "id": "s1",
                        "kind": "preprocess.canonical_spectrum",
                        "params": {
                            "mz": [100.0, 200.0, 300.0],
                            "intensity": [1.0, 2.0, 3.0]
                        }
                    },
                    {
                        "kind": "features.watchpoints",
                        "params": {
                            "spectrum_ref": "run-a",
                            "watchpoint_positions": [150.0]
                        }
                    },
                    {
                        "kind": "model.mlp_stub",
                        "params": { "out_dim": 3, "seed": 7 }
                    },
                    {
                        "kind": "eval.vector_stats",
                        "params": {}
                    }
                ]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["stages_executed"], 4);
        assert_eq!(v["result"]["experiment_id"], "exp-demo-1");
        assert!(v["result"]["stage_results"][3]["mean"].is_number());
    }

    #[tokio::test]
    async fn job_experiment_snapshot_bff_envelope_ok() {
        let app = app();
        let inner = serde_json::json!({
            "snapshot_version": 1,
            "experiment_id": "exp-env-1",
            "stages": [
                {
                    "id": "s1",
                    "kind": "preprocess.canonical_spectrum",
                    "params": {
                        "mz": [100.0, 200.0, 300.0],
                        "intensity": [1.0, 2.0, 3.0]
                    }
                },
                {
                    "kind": "features.watchpoints",
                    "params": {
                        "spectrum_ref": "run-a",
                        "watchpoint_positions": [150.0]
                    }
                }
            ]
        });
        let body = serde_json::json!({
            "job_type": "mlms.experiment_snapshot",
            "payload": {
                "schema_version": 1,
                "payload": inner
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["stages_executed"], 2);
        assert_eq!(v["result"]["experiment_id"], "exp-env-1");
    }

    #[tokio::test]
    async fn job_experiment_snapshot_unknown_kind_returns_422() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.experiment_snapshot",
            "payload": {
                "stages": [{ "kind": "unknown.stage", "params": {} }]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["error"]["code"], "invalid_experiment_snapshot");
    }

    #[tokio::test]
    async fn job_experiment_snapshot_rf_pipeline_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.experiment_snapshot",
            "payload": {
                "snapshot_version": 1,
                "experiment_id": "exp-rf-1",
                "stages": [
                    {
                        "id": "s1",
                        "kind": "preprocess.canonical_spectrum",
                        "params": {
                            "mz": [100.0, 200.0, 300.0],
                            "intensity": [1.0, 2.0, 3.0]
                        }
                    },
                    {
                        "kind": "features.watchpoints",
                        "params": {
                            "spectrum_ref": "run-a",
                            "watchpoint_positions": [150.0]
                        }
                    },
                    {
                        "kind": "model.rf_stub",
                        "params": { "n_trees": 5, "n_classes": 2, "seed": 9 }
                    },
                    {
                        "kind": "eval.vector_stats",
                        "params": {}
                    }
                ]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["stages_executed"], 4);
        assert_eq!(v["result"]["experiment_id"], "exp-rf-1");
        assert_eq!(v["result"]["stage_results"][2]["n_trees"], 5);
        assert!(v["result"]["stage_results"][2]["train_error_stub"].is_number());
        assert!(v["result"]["stage_results"][3]["mean"].is_number());
    }

    #[tokio::test]
    async fn job_experiment_snapshot_pks_select_mm_ok() {
        let app = app();
        let body = serde_json::json!({
            "job_type": "mlms.experiment_snapshot",
            "payload": {
                "snapshot_version": 1,
                "stages": [
                    {
                        "kind": "preprocess.pks_select_mm",
                        "params": {
                            "mz": [100.0, 200.0, 300.0],
                            "intensity": [1.0, 2.0, 3.0],
                            "fuzzy_window": 2,
                            "power": 0.5,
                            "baseline_correction_half_width": 0,
                            "allocation": 0,
                            "mmf_mode": 5
                        }
                    }
                ]
            }
        });
        let res = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/v1/jobs")
                    .header("content-type", "application/json")
                    .body(Body::from(body.to_string()))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(res.into_body(), usize::MAX)
            .await
            .unwrap();
        let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(v["result"]["stages_executed"], 1);
        assert_eq!(
            v["result"]["stage_results"][0]["legacy_matlab"],
            "fn_pks_select_mm.m"
        );
    }
}

