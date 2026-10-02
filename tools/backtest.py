#!/usr/bin/env python3
"""Backtest walk-forward reproducible del modelo de GP Fantasy Advisor.

Entrena en 2023-2024 y valida una sola vez en 2025. Todas las características
de una carrera se calculan exclusivamente con fechas anteriores. El script
guarda las respuestas de Jolpica en caché, exporta los pesos ganadores y crea
un informe JSON y Markdown con métricas por temporada y por carrera.

Uso:
    python tools/backtest.py --seasons 2023 2024 2025 --trials 300
"""

from __future__ import annotations

import argparse
import itertools
import json
import math
import random
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import optuna
import pandas as pd
import requests
from scipy.stats import spearmanr

JOLPICA_BASE = "https://api.jolpi.ca/ergast/f1"
FEATURE_NAMES = (
    "ritmo_carrera",
    "ritmo_clasificacion",
    "vuelta_rapida",
    "consistencia",
    "forma",
    "afinidad_circuito",
    "forma_equipo",
    "riesgo_dnf",
)
RACE_POINTS = {1: 25, 2: 18, 3: 15, 4: 12, 5: 10, 6: 8, 7: 6, 8: 4, 9: 2, 10: 1}
QUALI_POINTS = {position: 11 - position for position in range(1, 11)}
_MEDIAN_CACHE: dict[tuple[int, int], float] = {}


@dataclass(frozen=True)
class RaceSample:
    season: int
    round: int
    race_name: str
    driver_ids: tuple[str, ...]
    constructor_ids: tuple[str, ...]
    features: np.ndarray
    actual_driver_points: np.ndarray
    actual_finish: np.ndarray
    actual_constructor_points: dict[str, float]


def _get_json(url: str, cache_path: Path) -> dict:
    if cache_path.exists():
        return json.loads(cache_path.read_text(encoding="utf-8"))
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    last_error: Exception | None = None
    for attempt in range(8):
        try:
            response = requests.get(url, timeout=30)
            if response.status_code == 429:
                retry_after = float(response.headers.get("Retry-After", 0) or 0)
                time.sleep(max(retry_after, min(20.0, 2.5 * (attempt + 1))))
                continue
            response.raise_for_status()
            payload = response.json()
            cache_path.write_text(json.dumps(payload), encoding="utf-8")
            time.sleep(0.45)
            return payload
        except (requests.RequestException, ValueError) as error:
            last_error = error
            time.sleep(min(20.0, 2.0 * (attempt + 1)))
    raise RuntimeError(f"No se pudo descargar {url}: {last_error}")


def _races(payload: dict) -> list[dict]:
    return payload["MRData"]["RaceTable"].get("Races", [])


def _lap_seconds(value: str | None) -> float:
    if not value:
        return float("nan")
    try:
        minutes, seconds = value.split(":", 1)
        return int(minutes) * 60 + float(seconds)
    except (ValueError, TypeError):
        return float("nan")


def _download_paginated(season: int, kind: str, cache_dir: Path) -> dict:
    first = _get_json(
        f"{JOLPICA_BASE}/{season}/{kind}.json?limit=100&offset=0",
        cache_dir / f"{season}_{kind}.json",
    )
    total = int(first["MRData"].get("total", 0))
    page_size = int(first["MRData"].get("limit", 100)) or 100
    merged = list(_races(first))
    for offset in range(page_size, total, page_size):
        page = _get_json(
            f"{JOLPICA_BASE}/{season}/{kind}.json?limit={page_size}&offset={offset}",
            cache_dir / f"{season}_{kind}_{offset}.json",
        )
        merged.extend(_races(page))
    payload = json.loads(json.dumps(first))
    payload["MRData"]["RaceTable"]["Races"] = merged
    return payload


def download_history(seasons: Iterable[int], cache_dir: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    result_rows: list[dict] = []
    qualifying_rows: list[dict] = []
    for season in seasons:
        print(f"Descargando/cargando {season}…")
        results_payload = _download_paginated(season, "results", cache_dir)
        qualifying_payload = _download_paginated(season, "qualifying", cache_dir)
        race_dates: dict[int, tuple[str, str, str]] = {}
        for race in _races(results_payload):
            round_number = int(race["round"])
            race_dates[round_number] = (
                race["date"],
                race["Circuit"]["circuitId"],
                race["raceName"],
            )
            for result in race.get("Results", []):
                status = str(result.get("status", ""))
                finished = status == "Finished" or "Lap" in status
                finish = int(result["position"]) if finished else np.nan
                grid = int(result.get("grid", 0) or 0)
                result_rows.append(
                    {
                        "season": season,
                        "round": round_number,
                        "date": race["date"],
                        "race_name": race["raceName"],
                        "circuit_id": race["Circuit"]["circuitId"],
                        "driver_id": result["Driver"]["driverId"],
                        "constructor_id": result["Constructor"]["constructorId"],
                        "grid": grid,
                        "finish": finish,
                        "dnf": not finished,
                        "fastest_lap": result.get("FastestLap", {}).get("rank") == "1",
                        "fastest_lap_seconds": _lap_seconds(
                            result.get("FastestLap", {}).get("Time", {}).get("time")
                        ),
                        "status": status,
                    }
                )
        for race in _races(qualifying_payload):
            round_number = int(race["round"])
            date, circuit_id, race_name = race_dates.get(
                round_number,
                (race.get("date", f"{season}-12-31"), race["Circuit"]["circuitId"], race["raceName"]),
            )
            for result in race.get("QualifyingResults", []):
                qualifying_rows.append(
                    {
                        "season": season,
                        "round": round_number,
                        "date": date,
                        "race_name": race_name,
                        "circuit_id": circuit_id,
                        "driver_id": result["Driver"]["driverId"],
                        "constructor_id": result["Constructor"]["constructorId"],
                        "position": int(result["position"]),
                        "reached_q3": bool(result.get("Q3")),
                    }
                )
    results = pd.DataFrame(result_rows).sort_values(["date", "round"]).reset_index(drop=True)
    best_laps = results.groupby(["season", "round"])["fastest_lap_seconds"].transform("min")
    results["fastest_lap_gap_percent"] = np.where(
        best_laps > 0,
        100 * (results.fastest_lap_seconds - best_laps) / best_laps,
        np.nan,
    )
    qualifying = pd.DataFrame(qualifying_rows).sort_values(["date", "round"]).reset_index(drop=True)
    return results, qualifying


def position_score(position: float, grid_size: int) -> float:
    if not math.isfinite(position):
        position = float(grid_size)
    return float(np.clip(100 * (grid_size - position) / max(1, grid_size - 1), 0, 100))


def fantasy_points(row: pd.Series, qualifying_position: int | None) -> float:
    finish = None if pd.isna(row["finish"]) else int(row["finish"])
    points = float(QUALI_POINTS.get(qualifying_position or 99, 0))
    if qualifying_position is not None and qualifying_position <= 10:
        points += 1  # aparición en Q3
    if bool(row["dnf"]):
        points -= 20
    else:
        points += RACE_POINTS.get(finish or 99, 0)
        start = int(row["grid"] or 0) or qualifying_position or finish or 20
        points += start - (finish or start)
    if bool(row["fastest_lap"]):
        points += 5
    return points


def weighted_mean(values: list[float], weights: list[int]) -> float:
    return float(np.average(values, weights=weights[: len(values)])) if values else 50.0


def build_samples(
    results: pd.DataFrame,
    qualifying: pd.DataFrame,
    target_seasons: Iterable[int],
) -> list[RaceSample]:
    target = set(target_seasons)
    samples: list[RaceSample] = []
    races = results[results.season.isin(target)][
        ["season", "round", "date", "race_name", "circuit_id"]
    ].drop_duplicates()
    for race in races.itertuples(index=False):
        current = results[
            (results.season == race.season) & (results["round"] == race.round)
        ].copy()
        if len(current) < 15:
            continue
        current_quali = qualifying[
            (qualifying.season == race.season)
            & (qualifying["round"] == race.round)
        ]
        quali_by_driver = dict(zip(current_quali.driver_id, current_quali.position))
        grid_size = len(current)
        feature_rows: list[list[float]] = []
        actual_points: list[float] = []
        actual_finish: list[float] = []
        driver_ids: list[str] = []
        constructor_ids: list[str] = []

        for row in current.itertuples(index=False):
            past = results[(results.driver_id == row.driver_id) & (results.date < race.date)]
            past = past.sort_values(["date", "round"], ascending=False)
            past_quali = qualifying[
                (qualifying.driver_id == row.driver_id) & (qualifying.date < race.date)
            ].sort_values(["date", "round"], ascending=False)
            recent5 = past.head(5)
            race_scores = [position_score(value, grid_size) for value in recent5.finish]
            race_pace = weighted_mean(race_scores, [5, 4, 3, 2, 1])
            quali_scores = [position_score(value, grid_size) for value in past_quali.head(8).position]
            quali_pace = weighted_mean(quali_scores, [8, 7, 6, 5, 4, 3, 2, 1])
            recent8 = past.head(8)
            consistency_scores = [position_score(value, grid_size) for value in recent8.finish]
            consistency = 50.0 if len(consistency_scores) < 2 else 100 - float(np.std(consistency_scores))
            last3 = race_scores[:3]
            previous3 = race_scores[3:6]
            form = 50.0 if not last3 or not previous3 else 50 + float(np.mean(last3) - np.mean(previous3))
            circuit = past[past.circuit_id == race.circuit_id].head(4)
            affinity = (
                float(np.mean([position_score(value, grid_size) for value in circuit.finish]))
                if not circuit.empty
                else 50.0
            )
            recent_lap_gaps = past.head(8).fastest_lap_gap_percent.dropna()
            fastest_lap_form = (
                float(np.mean(np.clip(100 - recent_lap_gaps.to_numpy() / 3.0 * 100, 0, 100)))
                if not recent_lap_gaps.empty
                else 50.0
            )
            constructor_past = results[
                (results.constructor_id == row.constructor_id) & (results.date < race.date)
            ].sort_values(["date", "round"], ascending=False)
            recent_constructor_races = constructor_past[["season", "round"]].drop_duplicates().head(3)
            constructor_scores: list[float] = []
            for constructor_race in recent_constructor_races.itertuples(index=False):
                rows = constructor_past[
                    (constructor_past.season == constructor_race.season)
                    & (constructor_past["round"] == constructor_race.round)
                ]
                constructor_scores.extend(position_score(value, grid_size) for value in rows.finish)
            team_form = float(np.mean(constructor_scores)) if constructor_scores else 50.0
            two_year_cutoff = race.season - 2
            driver_reliability = past[past.season >= two_year_cutoff].head(44)
            constructor_reliability = constructor_past[constructor_past.season >= two_year_cutoff].head(88)
            driver_dnf = float(driver_reliability.dnf.mean()) if not driver_reliability.empty else 0.1
            constructor_dnf = float(constructor_reliability.dnf.mean()) if not constructor_reliability.empty else 0.1
            risk = 100 * (0.65 * driver_dnf + 0.35 * constructor_dnf)
            feature_rows.append(
                [
                    race_pace,
                    quali_pace,
                    fastest_lap_form,
                    float(np.clip(consistency, 0, 100)),
                    float(np.clip(form, 0, 100)),
                    affinity,
                    team_form,
                    float(np.clip(risk, 0, 100)),
                ]
            )
            current_row = current[current.driver_id == row.driver_id].iloc[0]
            q_position = quali_by_driver.get(row.driver_id)
            actual_points.append(fantasy_points(current_row, int(q_position) if q_position else None))
            actual_finish.append(float(row.finish) if math.isfinite(row.finish) else float(grid_size))
            driver_ids.append(row.driver_id)
            constructor_ids.append(row.constructor_id)

        actual_constructor_points: dict[str, float] = {}
        for constructor in sorted(set(constructor_ids)):
            indices = [index for index, value in enumerate(constructor_ids) if value == constructor]
            value = sum(actual_points[index] for index in indices)
            q3_count = sum((quali_by_driver.get(driver_ids[index], 99) <= 10) for index in indices)
            top10_count = sum(actual_finish[index] <= 10 for index in indices)
            if q3_count >= 2:
                value += 10
            if top10_count >= 2:
                value += 5
            actual_constructor_points[constructor] = value
        samples.append(
            RaceSample(
                season=int(race.season),
                round=int(race.round),
                race_name=str(race.race_name),
                driver_ids=tuple(driver_ids),
                constructor_ids=tuple(constructor_ids),
                features=np.asarray(feature_rows, dtype=float),
                actual_driver_points=np.asarray(actual_points, dtype=float),
                actual_finish=np.asarray(actual_finish, dtype=float),
                actual_constructor_points=actual_constructor_points,
            )
        )
    return samples


def normalized_weights(raw: np.ndarray) -> np.ndarray:
    raw = np.maximum(raw, 0.0001)
    return raw / raw.sum()


def score_features(features: np.ndarray, weights: np.ndarray) -> np.ndarray:
    signed = weights.copy()
    signed[-1] *= -1
    return features @ signed


def evaluate(weights: np.ndarray, samples: list[RaceSample], seed: int = 2026) -> dict:
    rng = random.Random(seed)
    race_rows: list[dict] = []
    for sample in samples:
        predicted = score_features(sample.features, weights)
        corr = spearmanr(predicted, sample.actual_driver_points).statistic
        corr = 0.0 if np.isnan(corr) else float(corr)
        predicted_top10 = set(np.argsort(predicted)[::-1][: min(10, len(predicted))])
        actual_top10 = set(np.argsort(sample.actual_driver_points)[::-1][: min(10, len(predicted))])
        top10 = len(predicted_top10 & actual_top10) / len(actual_top10)
        predicted_driver_indices = list(np.argsort(predicted)[::-1][:5])
        predicted_constructor_scores: dict[str, float] = {}
        for index, constructor in enumerate(sample.constructor_ids):
            predicted_constructor_scores[constructor] = predicted_constructor_scores.get(constructor, 0) + float(predicted[index])
        predicted_constructors = sorted(
            predicted_constructor_scores,
            key=predicted_constructor_scores.get,
            reverse=True,
        )[:2]
        recommended_points = sum(sample.actual_driver_points[index] for index in predicted_driver_indices)
        recommended_points += sum(sample.actual_constructor_points[name] for name in predicted_constructors)
        constructor_names = list(sample.actual_constructor_points)
        cache_key = (sample.season, sample.round)
        median_points = _MEDIAN_CACHE.get(cache_key)
        if median_points is None:
            random_totals: list[float] = []
            for _ in range(1500):
                picked_drivers = rng.sample(range(len(sample.driver_ids)), 5)
                picked_constructors = rng.sample(constructor_names, 2)
                random_totals.append(
                    sum(sample.actual_driver_points[index] for index in picked_drivers)
                    + sum(sample.actual_constructor_points[name] for name in picked_constructors)
                )
            median_points = float(np.median(random_totals))
            _MEDIAN_CACHE[cache_key] = median_points
        race_rows.append(
            {
                "season": sample.season,
                "round": sample.round,
                "race": sample.race_name,
                "spearman": corr,
                "top10_capture": top10,
                "recommended_points": float(recommended_points),
                "random_median_points": median_points,
                "uplift_vs_median": float(recommended_points - median_points),
                "beats_median": bool(recommended_points > median_points),
            }
        )
    frame = pd.DataFrame(race_rows)
    if frame.empty:
        return {"spearman_mean": 0.0, "top10_capture": 0.0, "beats_median_pct": 0.0, "uplift_mean": 0.0, "n_races": 0, "races": []}
    return {
        "spearman_mean": float(frame.spearman.mean()),
        "top10_capture": float(frame.top10_capture.mean()),
        "beats_median_pct": float(frame.beats_median.mean()),
        "uplift_mean": float(frame.uplift_vs_median.mean()),
        "n_races": int(len(frame)),
        "races": race_rows,
    }


def optimize(train_samples: list[RaceSample], trials: int) -> np.ndarray:
    optuna.logging.set_verbosity(optuna.logging.WARNING)

    def objective(trial: optuna.Trial) -> float:
        raw = np.asarray(
            [trial.suggest_float(name, 0.005, 1.0, log=True) for name in FEATURE_NAMES],
            dtype=float,
        )
        metrics = evaluate(normalized_weights(raw), train_samples)
        return 0.70 * metrics["spearman_mean"] + 0.20 * metrics["top10_capture"] + 0.10 * metrics["beats_median_pct"]

    study = optuna.create_study(direction="maximize", sampler=optuna.samplers.TPESampler(seed=2026))
    study.optimize(objective, n_trials=trials, show_progress_bar=True)
    return normalized_weights(np.asarray([study.best_params[name] for name in FEATURE_NAMES]))


def markdown_report(
    train_seasons: list[int],
    validation_season: int,
    weights: np.ndarray,
    train: dict,
    validation: dict,
    passed: bool,
) -> str:
    rows = "\n".join(
        f"| {row['round']} | {row['race']} | {row['spearman']:.3f} | {row['top10_capture']:.0%} | {row['uplift_vs_median']:+.1f} |"
        for row in validation["races"]
    )
    weight_rows = "\n".join(
        f"| {name} | {value:.4f} |" for name, value in zip(FEATURE_NAMES, weights)
    )
    return f"""# Backtest completo del modelo

Generado: {time.strftime('%Y-%m-%d %H:%M')}
Entrenamiento: {', '.join(map(str, train_seasons))} · Validación fuera de muestra: {validation_season}

## Resultado

| Conjunto | GP | Spearman | Top-10 | Supera mediana | Mejora media |
|---|---:|---:|---:|---:|---:|
| Entrenamiento | {train['n_races']} | {train['spearman_mean']:.3f} | {train['top10_capture']:.1%} | {train['beats_median_pct']:.1%} | {train['uplift_mean']:+.1f} pts |
| Validación | {validation['n_races']} | {validation['spearman_mean']:.3f} | {validation['top10_capture']:.1%} | {validation['beats_median_pct']:.1%} | {validation['uplift_mean']:+.1f} pts |

**Criterio acordado:** Spearman ≥ 0,65 y superar la mediana en ≥ 80 % de los GP.
**Estado:** {'CUMPLIDO' if passed else 'NO CUMPLIDO'}.

## Pesos elegidos

| Faceta | Peso |
|---|---:|
{weight_rows}

## Validación 2025 carrera a carrera

| Ronda | GP | Spearman | Top-10 | Mejora vs mediana |
|---:|---|---:|---:|---:|
{rows}

## Alcance y límites

- Walk-forward estricto: ninguna faceta usa carreras o clasificaciones posteriores al GP evaluado.
- La puntuación reconstruye clasificación, resultado, posiciones ganadas/perdidas, vuelta rápida y DNF.
- DOTD y Sprint se omiten porque Jolpica no ofrece un histórico Fantasy homogéneo.
- La comparación de equipo usa 5 pilotos y 2 constructores sin presupuesto histórico: los precios de 2023-2025 no están publicados por Jolpica. Por ello valida la calidad deportiva del ranking, no decisiones económicas retrospectivas.
- Los pesos de FP1/FP2/FP3 mantienen su backtest independiente con OpenF1.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seasons", nargs="+", type=int, default=[2023, 2024, 2025])
    parser.add_argument("--history-start", type=int, default=2021)
    parser.add_argument("--trials", type=int, default=300)
    parser.add_argument("--cache", type=Path, default=Path("tools/.cache/backtest"))
    parser.add_argument("--out", type=Path, default=Path("assets/model_weights.json"))
    parser.add_argument("--report", type=Path, default=Path("docs/backtest_report.md"))
    parser.add_argument("--details", type=Path, default=Path("docs/backtest_report.json"))
    args = parser.parse_args()
    if len(args.seasons) < 2:
        raise SystemExit("Se necesita al menos una temporada de entrenamiento y otra de validación.")
    train_seasons = args.seasons[:-1]
    validation_season = args.seasons[-1]
    history_seasons = range(args.history_start, validation_season + 1)
    results, qualifying = download_history(history_seasons, args.cache)
    print("Construyendo muestras walk-forward…")
    samples = build_samples(results, qualifying, args.seasons)
    train_samples = [sample for sample in samples if sample.season in train_seasons]
    validation_samples = [sample for sample in samples if sample.season == validation_season]
    print(f"Optimizando {args.trials} pruebas sobre {len(train_samples)} GP…")
    weights = optimize(train_samples, args.trials)
    train_metrics = evaluate(weights, train_samples)
    validation_metrics = evaluate(weights, validation_samples)
    passed = validation_metrics["spearman_mean"] >= 0.65 and validation_metrics["beats_median_pct"] >= 0.80

    details = {
        "method": "walk-forward-jolpica-v2",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "train_seasons": train_seasons,
        "validation_season": validation_season,
        "weights": dict(zip(FEATURE_NAMES, map(float, weights))),
        "train": train_metrics,
        "validation": validation_metrics,
        "acceptance_passed": passed,
    }
    args.details.parent.mkdir(parents=True, exist_ok=True)
    args.details.write_text(json.dumps(details, indent=2, ensure_ascii=False), encoding="utf-8")
    args.report.write_text(
        markdown_report(train_seasons, validation_season, weights, train_metrics, validation_metrics, passed),
        encoding="utf-8",
    )
    existing = json.loads(args.out.read_text(encoding="utf-8")) if args.out.exists() else {}
    existing.update(
        {
            "_comment": (
                "Pesos generales calibrados con walk-forward estricto: "
                f"entrenamiento {train_seasons} y validación fuera de muestra "
                f"{validation_season}. Los pesos de sesiones conservan su "
                "validación independiente con OpenF1."
            ),
            "version": f"walk-forward-{time.strftime('%Y%m%d')}",
            "calibrated_on": time.strftime("%Y-%m-%d"),
            "validation_spearman": validation_metrics["spearman_mean"],
            "validation_note": (
                f"{validation_metrics['race_count']} GP de {validation_season}: "
                f"Spearman {validation_metrics['spearman_mean']:.3f}, "
                f"top-10 {validation_metrics['top10_capture']:.1%} y supera "
                f"la mediana en {validation_metrics['beats_median_pct']:.1%}. "
                f"Criterio de aceptación {'cumplido' if passed else 'no cumplido'}."
            ),
            "validation_passed": passed,
            "feature_weights": {
                "w1_ritmo_carrera": float(weights[0]),
                "w2_ritmo_clasificacion": float(weights[1]),
                "w3_vuelta_rapida": float(weights[2]),
                "w4_consistencia": float(weights[3]),
                "w5_forma": float(weights[4]),
                "w6_afinidad_circuito": float(weights[5]),
                "w7_forma_equipo": float(weights[6]),
                "w8_riesgo_dnf": float(weights[7]),
            },
        }
    )
    args.out.write_text(json.dumps(existing, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"validation": validation_metrics, "passed": passed}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
