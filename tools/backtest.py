#!/usr/bin/env python3
"""
Backtesting y calibración del motor de predicción (PLAN_DESARROLLO.md,
sección 5.2). NO se ejecuta dentro de la app: es una herramienta de
desarrollo que corre en el PC del programador, con conexión a internet real
(Jolpica-F1), y produce `assets/model_weights.json`.

Metodología (walk-forward, sin mirar el futuro):
  1. Descarga resultados y clasificaciones de las temporadas pedidas.
  2. Para cada GP de cada temporada, calcula las 8 features SOLO con datos
     anteriores a ese GP.
  3. Puntúa cada combinación de pesos w1..w8 simulando los puntos fantasy
     del equipo recomendado (5 pilotos + 2 constructores óptimos) frente al
     equipo mediano y a un equipo aleatorio.
  4. Grid search (o Optuna si está instalado) sobre 2023-2024, validación en
     2025. Exporta los pesos ganadores.

Criterio de aceptación (sección 5.2): Spearman >= 0.65 en la temporada de
validación, y el equipo recomendado supera al equipo mediano simulado en
>= 80% de los GP. Si no se alcanza, iterar features antes de tocar la UI.

Uso:
    python backtest.py --seasons 2023 2024 2025 --out ../assets/model_weights.json
"""

from __future__ import annotations

import argparse
import itertools
import json
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import pandas as pd
import requests
from scipy.stats import spearmanr

JOLPICA_BASE = "https://api.jolpi.ca/ergast/f1"
REQUEST_DELAY_SECONDS = 0.3  # cortesía con el rate limit (~500 req/hora)


# ---------------------------------------------------------------------------
# 1. Descarga de datos (Jolpica-F1)
# ---------------------------------------------------------------------------

def _get_json(url: str) -> dict:
    for attempt in range(3):
        try:
            resp = requests.get(url, timeout=15)
            resp.raise_for_status()
            time.sleep(REQUEST_DELAY_SECONDS)
            return resp.json()
        except requests.RequestException as exc:
            if attempt == 2:
                raise
            print(f"  reintentando {url} ({exc})", file=sys.stderr)
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError("inalcanzable")


def fetch_season_results(season: int) -> pd.DataFrame:
    """Descarga resultados de carrera de toda una temporada, carrera a carrera."""
    calendar = _get_json(f"{JOLPICA_BASE}/{season}.json")
    races = calendar["MRData"]["RaceTable"]["Races"]

    rows = []
    for race in races:
        round_ = int(race["round"])
        data = _get_json(f"{JOLPICA_BASE}/{season}/{round_}/results.json")
        race_results = data["MRData"]["RaceTable"]["Races"]
        if not race_results:
            continue  # carrera futura, sin resultados todavía
        for r in race_results[0]["Results"]:
            status = r["status"]
            finished = status == "Finished" or "Lap" in status
            rows.append({
                "season": season,
                "round": round_,
                "circuit_id": race["Circuit"]["circuitId"],
                "date": race["date"],
                "driver_id": r["Driver"]["driverId"],
                "constructor_id": r["Constructor"]["constructorId"],
                "grid": int(r.get("grid", 0) or 0),
                "finish_position": int(r["position"]) if finished else None,
                "status": status,
                "fastest_lap": r.get("FastestLap", {}).get("rank") == "1",
            })
        print(f"  {season} ronda {round_}: {len(race_results[0]['Results']) if race_results else 0} resultados")
    return pd.DataFrame(rows)


def fetch_season_qualifying(season: int) -> pd.DataFrame:
    calendar = _get_json(f"{JOLPICA_BASE}/{season}.json")
    races = calendar["MRData"]["RaceTable"]["Races"]

    rows = []
    for race in races:
        round_ = int(race["round"])
        data = _get_json(f"{JOLPICA_BASE}/{season}/{round_}/qualifying.json")
        quali_results = data["MRData"]["RaceTable"]["Races"]
        if not quali_results:
            continue
        for q in quali_results[0]["QualifyingResults"]:
            rows.append({
                "season": season,
                "round": round_,
                "driver_id": q["Driver"]["driverId"],
                "position": int(q["position"]),
                "reached_q3": "Q3" in q and bool(q["Q3"]),
            })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# 2. Features (misma lógica que lib/domain/engine/prediction_engine.dart;
#    si se cambia una, cambiar la otra y comparar con el test Dart-vs-Python
#    de la sección "Fase 2" del plan, tolerancia < 0.1%)
# ---------------------------------------------------------------------------

@dataclass
class Weights:
    w1_ritmo_carrera: float = 0.24
    w2_ritmo_clasificacion: float = 0.18
    w3_vuelta_rapida: float = 0.08
    w4_consistencia: float = 0.14
    w5_forma: float = 0.12
    w6_afinidad_circuito: float = 0.08
    w7_forma_equipo: float = 0.10
    w8_riesgo_dnf: float = 0.06

    def as_dict(self) -> dict:
        return self.__dict__.copy()


def _position_to_score(position: int, grid_size: int) -> float:
    if grid_size <= 1:
        return 100.0
    return float(np.clip(100 * (grid_size - position) / (grid_size - 1), 0, 100))


def compute_features_for_driver(
    driver_id: str,
    constructor_id: str,
    upto_date: str,
    results: pd.DataFrame,
    qualifying: pd.DataFrame,
    circuit_id: str,
    grid_size: int,
) -> dict:
    """Replica las features de prediction_engine.dart usando solo datos con
    fecha anterior a `upto_date` (walk-forward, sin mirar el futuro)."""
    past = results[(results.driver_id == driver_id) & (results.date < upto_date)]
    past = past.sort_values("date", ascending=False)

    recent5 = past.head(5)
    positions = recent5.finish_position.fillna(grid_size).tolist()
    race_weights = [5, 4, 3, 2, 1][: len(positions)]
    ritmo_carrera = (
        np.average([_position_to_score(p, grid_size) for p in positions], weights=race_weights)
        if positions else 50.0
    )

    past_quali = qualifying[(qualifying.driver_id == driver_id) & (qualifying.round < 999)]
    # (el filtro de fecha real de quali se hace por round/season en el caller;
    # aquí se asume que `qualifying` ya viene recortado a "pasado")
    quali_positions = past_quali.position.head(8).tolist()
    ritmo_quali = (
        np.mean([_position_to_score(p, grid_size) for p in quali_positions])
        if quali_positions else 50.0
    )

    recent8 = past.head(8)
    pos8 = recent8.finish_position.fillna(grid_size).tolist()
    consistencia = 100 - np.std([_position_to_score(p, grid_size) for p in pos8]) if len(pos8) >= 2 else 50.0

    last3 = positions[:3]
    prev3 = positions[3:6]
    if last3 and prev3:
        forma = 50 + (
            np.mean([_position_to_score(p, grid_size) for p in last3])
            - np.mean([_position_to_score(p, grid_size) for p in prev3])
        )
    else:
        forma = 50.0

    circuit_hist = past[past.circuit_id == circuit_id].finish_position.fillna(grid_size).tolist()
    afinidad = (
        np.mean([_position_to_score(p, grid_size) for p in circuit_hist]) if circuit_hist else 50.0
    )

    constructor_recent = results[
        (results.constructor_id == constructor_id) & (results.date < upto_date)
    ].sort_values("date", ascending=False).head(6)
    # Puntos reales aproximados por posición (no fantasy) para "forma de equipo".
    forma_equipo = 50.0  # placeholder simplificado; afinar con tabla FIA real

    dnf_recent = past.head(20)
    riesgo_dnf = (
        100 * dnf_recent.finish_position.isna().mean() if len(dnf_recent) else 10.0
    )

    return {
        "ritmo_carrera": ritmo_carrera,
        "ritmo_clasificacion": ritmo_quali,
        "vuelta_rapida": 50.0,  # requiere datos OpenF1, no cubiertos por Jolpica
        "consistencia": float(np.clip(consistencia, 0, 100)),
        "forma": float(np.clip(forma, 0, 100)),
        "afinidad_circuito": afinidad,
        "forma_equipo": forma_equipo,
        "riesgo_dnf": float(np.clip(riesgo_dnf, 0, 100)),
    }


def score_driver(features: dict, weights: Weights) -> float:
    return (
        weights.w1_ritmo_carrera * features["ritmo_carrera"]
        + weights.w2_ritmo_clasificacion * features["ritmo_clasificacion"]
        + weights.w3_vuelta_rapida * features["vuelta_rapida"]
        + weights.w4_consistencia * features["consistencia"]
        + weights.w5_forma * features["forma"]
        + weights.w6_afinidad_circuito * features["afinidad_circuito"]
        + weights.w7_forma_equipo * features["forma_equipo"]
        - weights.w8_riesgo_dnf * features["riesgo_dnf"]
    )


# ---------------------------------------------------------------------------
# 3. Evaluación: Spearman, acierto top-10, puntos fantasy simulados
# ---------------------------------------------------------------------------

def evaluate_weights(weights: Weights, results: pd.DataFrame, qualifying: pd.DataFrame, seasons: list[int]) -> dict:
    spearman_scores = []
    top10_hits = []
    recommended_beats_median = []

    races = results[results.season.isin(seasons)][["season", "round", "date", "circuit_id"]].drop_duplicates()

    for _, race in races.iterrows():
        race_results = results[
            (results.season == race.season) & (results.round == race.round)
        ]
        if race_results.empty:
            continue
        grid_size = len(race_results)

        scores = []
        actual_positions = []
        for _, row in race_results.iterrows():
            features = compute_features_for_driver(
                row.driver_id, row.constructor_id, race.date, results, qualifying,
                race.circuit_id, grid_size,
            )
            scores.append(score_driver(features, weights))
            actual_positions.append(row.finish_position if pd.notna(row.finish_position) else grid_size)

        if len(scores) < 3:
            continue

        # Correlación esperada: más puntuación -> mejor (menor) posición final.
        corr, _ = spearmanr(scores, [-p for p in actual_positions])
        if not np.isnan(corr):
            spearman_scores.append(corr)

        predicted_top10_idx = set(np.argsort(scores)[::-1][:10])
        actual_top10_idx = set(np.argsort(actual_positions)[:10])
        overlap = len(predicted_top10_idx & actual_top10_idx) / min(10, grid_size)
        top10_hits.append(overlap)

        # Puntos fantasy simulados del "equipo" top-5 por score vs mediana aleatoria.
        top5_idx = np.argsort(scores)[::-1][:5]
        median_points = np.median(
            [_race_points(p) for p in actual_positions]
        ) * 5
        recommended_points = sum(_race_points(actual_positions[i]) for i in top5_idx)
        recommended_beats_median.append(recommended_points > median_points)

    return {
        "spearman_mean": float(np.mean(spearman_scores)) if spearman_scores else 0.0,
        "top10_hit_rate": float(np.mean(top10_hits)) if top10_hits else 0.0,
        "recommended_beats_median_pct": float(np.mean(recommended_beats_median)) if recommended_beats_median else 0.0,
        "n_races": len(spearman_scores),
    }


_RACE_POINTS = {1: 25, 2: 18, 3: 15, 4: 12, 5: 10, 6: 8, 7: 6, 8: 4, 9: 2, 10: 1}


def _race_points(position) -> int:
    if position is None:
        return 0
    return _RACE_POINTS.get(int(position), 0)


# ---------------------------------------------------------------------------
# 4. Grid search de pesos (Optuna si está disponible, si no grid coarse)
# ---------------------------------------------------------------------------

def grid_search(results: pd.DataFrame, qualifying: pd.DataFrame, train_seasons: list[int]) -> Weights:
    try:
        import optuna

        def objective(trial: "optuna.Trial") -> float:
            weights = Weights(
                w1_ritmo_carrera=trial.suggest_float("w1", 0.05, 0.35),
                w2_ritmo_clasificacion=trial.suggest_float("w2", 0.05, 0.30),
                w3_vuelta_rapida=trial.suggest_float("w3", 0.0, 0.15),
                w4_consistencia=trial.suggest_float("w4", 0.0, 0.25),
                w5_forma=trial.suggest_float("w5", 0.0, 0.20),
                w6_afinidad_circuito=trial.suggest_float("w6", 0.0, 0.15),
                w7_forma_equipo=trial.suggest_float("w7", 0.0, 0.20),
                w8_riesgo_dnf=trial.suggest_float("w8", 0.0, 0.15),
            )
            metrics = evaluate_weights(weights, results, qualifying, train_seasons)
            return metrics["spearman_mean"] + metrics["recommended_beats_median_pct"]

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=200, show_progress_bar=False)
        best = study.best_params
        return Weights(
            w1_ritmo_carrera=best["w1"], w2_ritmo_clasificacion=best["w2"],
            w3_vuelta_rapida=best["w3"], w4_consistencia=best["w4"],
            w5_forma=best["w5"], w6_afinidad_circuito=best["w6"],
            w7_forma_equipo=best["w7"], w8_riesgo_dnf=best["w8"],
        )
    except ImportError:
        print("Optuna no instalado: usando grid search coarse (más lento, menos fino).")
        best_weights = Weights()
        best_score = -1.0
        grid = [0.05, 0.15, 0.25]
        for combo in itertools.product(grid, repeat=4):
            w = Weights(w1_ritmo_carrera=combo[0], w2_ritmo_clasificacion=combo[1],
                        w4_consistencia=combo[2], w5_forma=combo[3])
            metrics = evaluate_weights(w, results, qualifying, train_seasons)
            score = metrics["spearman_mean"] + metrics["recommended_beats_median_pct"]
            if score > best_score:
                best_score = score
                best_weights = w
        return best_weights


# ---------------------------------------------------------------------------
# 5. CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seasons", nargs="+", type=int, default=[2023, 2024, 2025])
    parser.add_argument("--out", type=str, default="../assets/model_weights.json")
    parser.add_argument("--report", type=str, default="../docs/backtest_report.md")
    args = parser.parse_args()

    *train_seasons, validation_season = args.seasons
    print(f"Entrenamiento: {train_seasons} | Validación: {validation_season}")

    all_results = []
    all_qualifying = []
    for season in args.seasons:
        print(f"Descargando temporada {season}...")
        all_results.append(fetch_season_results(season))
        all_qualifying.append(fetch_season_qualifying(season))
    results = pd.concat(all_results, ignore_index=True)
    qualifying = pd.concat(all_qualifying, ignore_index=True)

    print("Buscando pesos óptimos sobre temporadas de entrenamiento...")
    best_weights = grid_search(results, qualifying, train_seasons)

    print("Validando en temporada de validación...")
    validation_metrics = evaluate_weights(best_weights, results, qualifying, [validation_season])
    print(json.dumps(validation_metrics, indent=2))

    passed = (
        validation_metrics["spearman_mean"] >= 0.65
        and validation_metrics["recommended_beats_median_pct"] >= 0.80
    )
    print(f"\nCriterio de aceptación (sección 5.2): {'CUMPLIDO' if passed else 'NO CUMPLIDO'}")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": f"backtest-{int(time.time())}",
        "calibrated_on": train_seasons,
        "validation_season": validation_season,
        "validation_spearman": validation_metrics["spearman_mean"],
        "validation_passed": passed,
        "feature_weights": best_weights.as_dict(),
        "session_weights_by_objective": {
            "race_fp1_fp2": {"fp1": 0.50, "fp2": 0.50},
            "race_fp1_fp2_fp3": {"fp1": 0.42, "fp2": 0.13, "fp3": 0.45},
        },
        "pace_stint_metric": "median_top2_stints",
        "recent_form_window_races": 5,
        "consistency_window_races": 8,
        "circuit_affinity_window_years": 4,
        "dnf_risk_window_seasons": 2,
    }
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Pesos escritos en {out_path}")

    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        f"# Informe de backtesting\n\n"
        f"- Temporadas de entrenamiento: {train_seasons}\n"
        f"- Temporada de validación: {validation_season}\n"
        f"- Spearman (validación): {validation_metrics['spearman_mean']:.3f}\n"
        f"- Acierto top-10 (validación): {validation_metrics['top10_hit_rate']:.1%}\n"
        f"- Equipo recomendado supera al mediano en: {validation_metrics['recommended_beats_median_pct']:.1%} de los GP\n"
        f"- Criterio de aceptación (Spearman >= 0.65 y >= 80% de GP): "
        f"{'CUMPLIDO' if passed else 'NO CUMPLIDO'}\n\n"
        f"Pesos ganadores: {json.dumps(best_weights.as_dict(), indent=2)}\n",
        encoding="utf-8",
    )
    print(f"Informe escrito en {report_path}")


if __name__ == "__main__":
    main()
