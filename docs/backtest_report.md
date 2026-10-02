# Backtest completo del modelo

Generado: 2026-08-06 08:00  
Entrenamiento: 2023, 2024 · Validación fuera de muestra: 2025

## Resultado

| Conjunto | GP | Spearman | Top-10 | Supera mediana | Mejora media |
|---|---:|---:|---:|---:|---:|
| Entrenamiento | 46 | 0.620 | 76.7% | 97.8% | +125.2 pts |
| Validación | 24 | 0.522 | 65.8% | 100.0% | +134.2 pts |

**Criterio acordado:** Spearman ≥ 0,65 y superar la mediana en ≥ 80 % de los GP.  
**Estado:** NO CUMPLIDO.

## Pesos elegidos

| Faceta | Peso |
|---|---:|
| ritmo_carrera | 0.1335 |
| ritmo_clasificacion | 0.3980 |
| vuelta_rapida | 0.2777 |
| consistencia | 0.0089 |
| forma | 0.0227 |
| afinidad_circuito | 0.0244 |
| forma_equipo | 0.0669 |
| riesgo_dnf | 0.0679 |

## Validación 2025 carrera a carrera

| Ronda | GP | Spearman | Top-10 | Mejora vs mediana |
|---:|---|---:|---:|---:|
| 1 | Australian Grand Prix | 0.362 | 50% | +178.0 |
| 2 | Chinese Grand Prix | 0.142 | 40% | +101.0 |
| 3 | Japanese Grand Prix | 0.806 | 80% | +158.0 |
| 4 | Bahrain Grand Prix | 0.656 | 70% | +152.0 |
| 5 | Saudi Arabian Grand Prix | 0.794 | 90% | +172.0 |
| 6 | Miami Grand Prix | 0.849 | 80% | +204.0 |
| 7 | Emilia Romagna Grand Prix | 0.704 | 80% | +103.5 |
| 8 | Monaco Grand Prix | 0.467 | 60% | +125.0 |
| 9 | Spanish Grand Prix | 0.513 | 60% | +182.0 |
| 10 | Canadian Grand Prix | 0.417 | 70% | +85.0 |
| 11 | Austrian Grand Prix | 0.306 | 60% | +181.0 |
| 12 | British Grand Prix | 0.388 | 50% | +156.0 |
| 13 | Belgian Grand Prix | 0.734 | 80% | +159.0 |
| 14 | Hungarian Grand Prix | 0.433 | 60% | +141.0 |
| 15 | Dutch Grand Prix | -0.033 | 50% | +9.0 |
| 16 | Italian Grand Prix | 0.734 | 70% | +176.0 |
| 17 | Azerbaijan Grand Prix | 0.342 | 60% | +7.0 |
| 18 | Singapore Grand Prix | 0.795 | 80% | +127.0 |
| 19 | United States Grand Prix | 0.673 | 60% | +123.0 |
| 20 | Mexico City Grand Prix | 0.537 | 70% | +170.0 |
| 21 | São Paulo Grand Prix | 0.439 | 60% | +156.0 |
| 22 | Las Vegas Grand Prix | 0.446 | 70% | +71.5 |
| 23 | Qatar Grand Prix | 0.585 | 70% | +178.0 |
| 24 | Abu Dhabi Grand Prix | 0.430 | 60% | +106.0 |

## Alcance y límites

- Walk-forward estricto: ninguna faceta usa carreras o clasificaciones posteriores al GP evaluado.
- La puntuación reconstruye clasificación, resultado, posiciones ganadas/perdidas, vuelta rápida y DNF.
- DOTD y Sprint se omiten porque Jolpica no ofrece un histórico Fantasy homogéneo.
- La comparación de equipo usa 5 pilotos y 2 constructores sin presupuesto histórico: los precios de 2023-2025 no están publicados por Jolpica. Por ello valida la calidad deportiva del ranking, no decisiones económicas retrospectivas.
- Los pesos de FP1/FP2/FP3 mantienen su backtest independiente con OpenF1.
