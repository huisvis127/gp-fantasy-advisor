#!/usr/bin/env python3
"""Calibra por separado los pesos FP1+FP2 y FP1+FP2+FP3.

Los datos proceden de OpenF1. El agregado de vueltas replica
``OpenF1Api.aggregateStints`` y la mezcla replica ``PredictionEngine``.
2023-2024 se usan para elegir pesos; 2025 queda reservado para validacion.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from dataclasses import dataclass
from itertools import product
from pathlib import Path

import numpy as np
import requests

OPENF1_BASE = "https://api.openf1.org/v1"
RACE_POINTS = {1: 25, 2: 18, 3: 15, 4: 12, 5: 10,
               6: 8, 7: 6, 8: 4, 9: 2, 10: 1}
QUALI_POINTS = {position: 11 - position for position in range(1, 11)}


@dataclass(frozen=True)
class MeetingSample:
    year: int
    meeting_key: int
    label: str
    sessions: dict[str, dict[int, tuple[float, float]]]
    targets: dict[int, float]


class OpenF1Cache:
    def __init__(self, cache_dir: Path) -> None:
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.http = requests.Session()

    def get(self, endpoint: str, **params) -> list[dict]:
        cache_key = endpoint.replace("/", "_") + "__" + "__".join(
            f"{key}-{params[key]}" for key in sorted(params)
        )
        path = self.cache_dir / f"{cache_key}.json"
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
        last_error: Exception | None = None
        for attempt in range(10):
            try:
                response = self.http.get(
                    f"{OPENF1_BASE}/{endpoint}", params=params, timeout=60
                )
                if response.status_code == 404:
                    path.write_text("[]", encoding="utf-8")
                    return []
                if response.status_code == 429:
                    last_error = RuntimeError("OpenF1 rate limit (HTTP 429)")
                    retry_after = float(response.headers.get("Retry-After", 0) or 0)
                    time.sleep(max(retry_after, min(60, 5 * (attempt + 1))))
                    continue
                response.raise_for_status()
                payload = response.json()
                path.write_text(json.dumps(payload), encoding="utf-8")
                time.sleep(0.45)
                return payload
            except (requests.RequestException, ValueError) as exc:
                last_error = exc
                time.sleep(min(10, 1.5 * (attempt + 1)))
        raise RuntimeError(f"OpenF1 fallo en {endpoint} {params}: {last_error}")


def aggregate_session(laps: list[dict]) -> dict[int, tuple[float, float]]:
    """Devuelve dorsal -> (gap mejor vuelta %, gap ritmo top-2 %)."""
    by_driver: dict[int, list[float]] = {}
    for lap in laps:
        duration = lap.get("lap_duration")
        number = lap.get("driver_number")
        if duration is None or number is None or lap.get("is_pit_out_lap") is True:
            continue
        duration = float(duration)
        if not math.isfinite(duration) or duration <= 0:
            continue
        by_driver.setdefault(int(number), []).append(duration)

    raw: dict[int, tuple[float, float]] = {}
    for number, durations in by_driver.items():
        ordered = sorted(durations)
        best = ordered[0]
        clean = [duration for duration in ordered if duration <= best * 1.07]
        if not clean:
            continue
        top2 = clean[:2]
        raw[number] = (best, sum(top2) / len(top2))
    if not raw:
        return {}
    best_lap = min(value[0] for value in raw.values())
    best_pace = min(value[1] for value in raw.values())
    return {
        number: (
            (value[0] - best_lap) / best_lap * 100,
            (value[1] - best_pace) / best_pace * 100,
        )
        for number, value in raw.items()
    }


def fantasy_proxy(qualifying: list[dict], race: list[dict]) -> dict[int, float]:
    """Puntos observables del reglamento de la app, sin DOTD ni vuelta rapida."""
    quali_by_driver = {
        int(row["driver_number"]): int(row["position"])
        for row in qualifying
        if row.get("driver_number") is not None and row.get("position") is not None
    }
    targets: dict[int, float] = {}
    for row in race:
        if row.get("driver_number") is None or row.get("position") is None:
            continue
        number = int(row["driver_number"])
        finish = int(row["position"])
        quali = quali_by_driver.get(number)
        points = float(RACE_POINTS.get(finish, 0))
        if quali is not None:
            points += QUALI_POINTS.get(quali, 0)
            points += 1 if quali <= 10 else (-1 if quali >= 16 else 0)
            points += quali - finish
        if row.get("dnf") or row.get("dns") or row.get("dsq"):
            points -= 20
        targets[number] = points
    return targets


def load_samples(api: OpenF1Cache, years: list[int]) -> list[MeetingSample]:
    samples: list[MeetingSample] = []
    for year in years:
        all_sessions = api.get("sessions", year=year)
        meetings: dict[int, dict[str, dict]] = {}
        for session in all_sessions:
            name = str(session.get("session_name", ""))
            if name not in {"Practice 1", "Practice 2", "Practice 3", "Qualifying", "Race"}:
                continue
            meetings.setdefault(int(session["meeting_key"]), {})[name] = session

        complete = [value for value in meetings.values()
                    if all(name in value for name in
                           ("Practice 1", "Practice 2", "Practice 3", "Qualifying", "Race"))]
        print(f"{year}: {len(complete)} fines de semana convencionales completos")
        for index, meeting in enumerate(complete, 1):
            label = str(meeting["Race"].get("location") or meeting["Race"].get("country_name"))
            session_data: dict[str, dict[int, tuple[float, float]]] = {}
            for logical, official in (("fp1", "Practice 1"),
                                      ("fp2", "Practice 2"),
                                      ("fp3", "Practice 3")):
                key = int(meeting[official]["session_key"])
                session_data[logical] = aggregate_session(api.get("laps", session_key=key))
            qualifying = api.get(
                "session_result", session_key=int(meeting["Qualifying"]["session_key"])
            )
            race = api.get(
                "session_result", session_key=int(meeting["Race"]["session_key"])
            )
            targets = fantasy_proxy(qualifying, race)
            common = set(targets)
            for values in session_data.values():
                common &= set(values)
            if len(common) >= 15:
                samples.append(MeetingSample(
                    year=year,
                    meeting_key=int(meeting["Race"]["meeting_key"]),
                    label=label,
                    sessions=session_data,
                    targets={number: targets[number] for number in common},
                ))
            print(f"  {index:02d}/{len(complete)} {label}: {len(common)} pilotos comparables")
    return samples


def weighted_signal(sample: MeetingSample, weights: dict[str, float]) -> dict[int, float]:
    output: dict[int, float] = {}
    for number in sample.targets:
        one_lap_gap = sum(sample.sessions[key][number][0] * weight
                          for key, weight in weights.items())
        pace_gap = sum(sample.sessions[key][number][1] * weight
                       for key, weight in weights.items())
        one_lap_score = float(np.clip(100 - one_lap_gap / 3 * 100, 0, 100))
        pace_score = float(np.clip(100 - pace_gap / 2 * 100, 0, 100))
        # Mismo impacto relativo que el motor: w3=.24 para vuelta unica y
        # w1=.20 * mezcla 50/50 para ritmo del fin de semana.
        output[number] = 0.24 * one_lap_score + 0.10 * pace_score
    return output


def rank_values(values: np.ndarray) -> np.ndarray:
    """Rangos medios para empates, equivalentes a scipy.stats.rankdata."""
    order = np.argsort(values, kind="mergesort")
    ranks = np.empty(len(values), dtype=float)
    start = 0
    while start < len(values):
        end = start + 1
        while end < len(values) and values[order[end]] == values[order[start]]:
            end += 1
        ranks[order[start:end]] = (start + end - 1) / 2 + 1
        start = end
    return ranks


def spearman(predicted: np.ndarray, actual: np.ndarray) -> float:
    predicted_ranks = rank_values(predicted)
    actual_ranks = rank_values(actual)
    if np.std(predicted_ranks) == 0 or np.std(actual_ranks) == 0:
        return float("nan")
    return float(np.corrcoef(predicted_ranks, actual_ranks)[0, 1])


def metrics(samples: list[MeetingSample], weights: dict[str, float]) -> dict[str, float]:
    correlations: list[float] = []
    top5_captures: list[float] = []
    regrets: list[float] = []
    for sample in samples:
        predictions = weighted_signal(sample, weights)
        drivers = list(predictions)
        predicted = np.array([predictions[number] for number in drivers])
        actual = np.array([sample.targets[number] for number in drivers])
        correlation = spearman(predicted, actual)
        if math.isfinite(correlation):
            correlations.append(float(correlation))
        predicted_top5 = sorted(drivers, key=predictions.get, reverse=True)[:5]
        actual_top5 = sorted(drivers, key=sample.targets.get, reverse=True)[:5]
        predicted_points = sum(sample.targets[number] for number in predicted_top5)
        oracle_points = sum(sample.targets[number] for number in actual_top5)
        denominator = sum(max(0.0, sample.targets[number]) for number in actual_top5)
        top5_captures.append(predicted_points / denominator if denominator else 0.0)
        regrets.append(oracle_points - predicted_points)
    return {
        "spearman": float(np.mean(correlations)),
        "top5_capture": float(np.mean(top5_captures)),
        "fantasy_regret": float(np.mean(regrets)),
        "races": len(correlations),
    }


def objective(result: dict[str, float]) -> float:
    # Prioriza orden global, con los puntos del top-5 como desempate practico.
    return result["spearman"] + 0.35 * result["top5_capture"]


def candidates(keys: tuple[str, ...], step: float) -> list[dict[str, float]]:
    units = round(1 / step)
    output: list[dict[str, float]] = []
    for values in product(range(units + 1), repeat=len(keys)):
        if sum(values) != units:
            continue
        output.append({key: value / units for key, value in zip(keys, values)})
    return output


def calibrate(samples: list[MeetingSample], keys: tuple[str, ...], step: float) -> tuple[dict, dict]:
    train = [sample for sample in samples if sample.year in (2023, 2024)]
    validation = [sample for sample in samples if sample.year == 2025]
    ranked = []
    for weights in candidates(keys, step):
        result = metrics(train, weights)
        ranked.append((objective(result), weights, result))
    ranked.sort(key=lambda row: row[0], reverse=True)
    best = ranked[0]
    validation_result = metrics(validation, best[1])
    return {
        "weights": best[1],
        "train": best[2],
        "validation": validation_result,
    }, {
        "top_train_candidates": [
            {"weights": weights, "metrics": result}
            for _, weights, result in ranked[:10]
        ]
    }


def main() -> None:
    project_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cache", type=Path, default=project_root / ".cache/openf1_sessions"
    )
    parser.add_argument(
        "--out", type=Path, default=project_root / "docs/session_weights_backtest.json"
    )
    parser.add_argument("--step", type=float, default=0.025)
    args = parser.parse_args()
    api = OpenF1Cache(args.cache)
    samples = load_samples(api, [2023, 2024, 2025])
    two, two_details = calibrate(samples, ("fp1", "fp2"), args.step)
    three, three_details = calibrate(samples, ("fp1", "fp2", "fp3"), args.step)
    train_samples = [sample for sample in samples if sample.year in (2023, 2024)]
    validation_samples = [sample for sample in samples if sample.year == 2025]
    baselines = {}
    for name, weights in {
        "provisional_fp1_fp2": {"fp1": 0.50, "fp2": 0.50},
        "provisional_fp1_fp2_fp3": {"fp1": 0.20, "fp2": 0.40, "fp3": 0.40},
        "equal_fp1_fp2_fp3": {"fp1": 1 / 3, "fp2": 1 / 3, "fp3": 1 / 3},
    }.items():
        baselines[name] = {
            "weights": weights,
            "train": metrics(train_samples, weights),
            "validation": metrics(validation_samples, weights),
        }
    payload = {
        "method": "OpenF1 practices; train 2023-2024; validation 2025",
        "step": args.step,
        "sample_count": len(samples),
        "samples_by_year": {
            str(year): sum(sample.year == year for sample in samples)
            for year in (2023, 2024, 2025)
        },
        "fp1_fp2": two,
        "fp1_fp2_fp3": three,
        "baselines": baselines,
        "details": {"fp1_fp2": two_details, "fp1_fp2_fp3": three_details},
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
