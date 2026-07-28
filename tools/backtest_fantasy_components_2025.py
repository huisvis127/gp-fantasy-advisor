#!/usr/bin/env python3
"""Compara una proyección básica con una que arrastra extras Fantasy.

Fuente: desglose 2025 por piloto y ronda de JoshCBruce/fantasy-data, extraído
de la web oficial de F1 Fantasy. La temporada 2025 se usa aislada para no
mezclar reglas diferentes.

Modelos walk-forward (sin mirar la ronda objetivo):
  básico   = media ponderada de clasificación + carrera + Sprint en las tres
             rondas anteriores;
  ampliado = básico + media ponderada de los demás puntos Fantasy en esas
             tres rondas.

La ponderación de las tres rondas, de más antigua a más reciente, es 1/2/3.
"""

from __future__ import annotations

import math
import statistics
from collections import defaultdict

import requests

BASE_URL = (
    "https://raw.githubusercontent.com/"
    "JoshCBruce/fantasy-data/refs/heads/main/latest"
)
WEIGHTS = (1.0, 2.0, 3.0)


def _ranks(values: list[float]) -> list[float]:
    order = sorted(range(len(values)), key=values.__getitem__)
    output = [0.0] * len(values)
    index = 0
    while index < len(order):
        end = index + 1
        while end < len(order) and values[order[end]] == values[order[index]]:
            end += 1
        average_rank = (index + end - 1) / 2 + 1
        for offset in range(index, end):
            output[order[offset]] = average_rank
        index = end
    return output


def _pearson(left: list[float], right: list[float]) -> float:
    left_mean = statistics.mean(left)
    right_mean = statistics.mean(right)
    numerator = sum(
        (x - left_mean) * (y - right_mean) for x, y in zip(left, right)
    )
    left_sum = sum((x - left_mean) ** 2 for x in left)
    right_sum = sum((y - right_mean) ** 2 for y in right)
    denominator = math.sqrt(left_sum * right_sum)
    return numerator / denominator if denominator else float("nan")


def _spearman(left: list[float], right: list[float]) -> float:
    return _pearson(_ranks(left), _ranks(right))


def _weighted_recent(values: list[float]) -> float:
    return sum(value * weight for value, weight in zip(values, WEIGHTS)) / sum(
        WEIGHTS
    )


def _section_sum(section: dict, keys: tuple[str, ...]) -> float:
    return sum(float(section.get(key, 0) or 0) for key in keys)


def load_rows() -> list[dict]:
    summary = requests.get(
        f"{BASE_URL}/summary_data/weekend_summary.json", timeout=20
    )
    summary.raise_for_status()
    summary_data = summary.json()
    rounds = sorted(map(int, summary_data))
    abbreviations = sorted(
        {
            abbreviation
            for weekend in summary_data.values()
            for abbreviation in weekend["drivers"]
        }
    )

    rows: list[dict] = []
    for abbreviation in abbreviations:
        response = requests.get(
            f"{BASE_URL}/driver_data/{abbreviation}.json", timeout=20
        )
        response.raise_for_status()
        by_round = {int(row["round"]): row for row in response.json()["races"]}
        for round_number in rounds:
            official = summary_data[str(round_number)]["drivers"]
            if abbreviation not in official or round_number not in by_round:
                continue
            row = by_round[round_number]
            race = row.get("race") or {}
            qualifying = row.get("qualifying") or {}
            sprint = row.get("sprint") or {}
            core = (
                _section_sum(
                    qualifying,
                    ("position", "disqualificationPenalty"),
                )
                + _section_sum(race, ("position", "qualifyingPosition"))
                + _section_sum(sprint, ("position", "qualifyingPosition"))
            )
            total = float(row["totalPoints"])
            rows.append(
                {
                    "driver": abbreviation,
                    "round": round_number,
                    "core": core,
                    "extras": total - core,
                    "total": total,
                    "overtakes": _section_sum(race, ("overtakeBonus",))
                    + _section_sum(sprint, ("overtakeBonus",)),
                }
            )
    return rows


def main() -> None:
    rows = load_rows()
    actual_core = [row["core"] for row in rows]
    actual_total = [row["total"] for row in rows]

    by_driver: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_driver[row["driver"]].append(row)

    forecasts: list[dict] = []
    for driver_rows in by_driver.values():
        driver_rows.sort(key=lambda row: row["round"])
        for index, target in enumerate(driver_rows):
            if index < 3:
                continue
            previous = driver_rows[index - 3 : index]
            forecasts.append(
                {
                    **target,
                    "basic": _weighted_recent(
                        [row["core"] for row in previous]
                    ),
                    "extras": _weighted_recent(
                        [row["extras"] for row in previous]
                    ),
                }
            )

    print(f"Actuaciones: {len(rows)}")
    print(
        "Spearman componentes básicos reales -> total Fantasy real: "
        f"{_spearman(actual_core, actual_total):.3f}"
    )

    for label, minimum_round, maximum_round in (
        ("completo", 0, 99),
        ("entrenamiento", 0, 10),
        ("validación", 11, 99),
    ):
        subset = [
            row
            for row in forecasts
            if minimum_round <= row["round"] <= maximum_round
        ]
        target = [row["total"] for row in subset]
        basic = [row["basic"] for row in subset]
        expanded = [row["basic"] + row["extras"] for row in subset]
        print(f"\n{label}: {len(subset)} actuaciones")
        print(f"  básico   Spearman={_spearman(basic, target):.3f}")
        print(f"  ampliado Spearman={_spearman(expanded, target):.3f}")

    lag_overtakes_left: list[float] = []
    lag_overtakes_right: list[float] = []
    lag_extras_left: list[float] = []
    lag_extras_right: list[float] = []
    for driver_rows in by_driver.values():
        for previous, following in zip(driver_rows, driver_rows[1:]):
            lag_overtakes_left.append(previous["overtakes"])
            lag_overtakes_right.append(following["overtakes"])
            lag_extras_left.append(previous["extras"])
            lag_extras_right.append(following["extras"])
    print(
        "\nPersistencia carrera-a-carrera:"
        f"\n  adelantamientos Spearman="
        f"{_spearman(lag_overtakes_left, lag_overtakes_right):.3f}"
        f"\n  todos los extras Spearman="
        f"{_spearman(lag_extras_left, lag_extras_right):.3f}"
    )


if __name__ == "__main__":
    main()
