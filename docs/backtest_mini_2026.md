# Mini-backtest de pesos — 05/07/2026

**Pregunta de Luis:** ¿se ha probado la eficacia de los pesos? ¿Con menos pesos mejora o empeora?

**Método:** con los resultados y clasificaciones reales de 2026 (OpenF1: rondas 2, 3, 4, 5, 7 y 8; Melbourne y Mónaco no están publicadas), se predijo cada una de las rondas 4, 5, 7 y 8 usando **solo datos anteriores a cada carrera**, con distintas configuraciones de pesos. Métrica: correlación de Spearman entre el orden predicho y el real, y % de acierto del top-10. Script: `tools/mini_backtest_2026.py`.

## Resultados (Spearman medio / acierto top-10)

| Configuración | Spearman | Top-10 |
|---|---|---|
| Solo clasificación reciente (baseline) | **+0.655** | 68% |
| clasif 50 / vuelta rápida 30 / ritmo 20 | +0.646 | **75%** |
| 3 pesos estilo referencia MotoGP (VR 75 / ritmo 15 / cons 10) | +0.631 | **75%** |
| 4 principales (defaults antiguos renormalizados) | +0.574 | 70% |
| 8 completos (defaults antiguos) | +0.580 | 70% |
| Solo ritmo reciente | +0.534 | 65% |

## Conclusiones

1. **Con menos pesos NO empeora — mejora.** Las configuraciones simples dominadas por la vuelta única (clasificación + gap de vuelta rápida) baten a la mezcla de 8 pesos con los valores antiguos.
2. **La clasificación es el rey.** Coincide con la literatura (correlación >0.7 parrilla→resultado) y con la app de referencia de MotoGP, cuyos pesos validados (75% vuelta rápida) funcionan bien también en F1.
3. **Los pesos antiguos infravaloraban la vuelta única** (clasif 18 + VR 8 = 26%). Los nuevos defaults son: **clasif 32 / VR 24 / ritmo 20 / cons 10 / forma 4 / afinidad 4 / equipo 4 / DNF 2** (los avanzados se mantienen con peso pequeño: en 4 carreras no aportan, pero en temporadas completas la fiabilidad y la forma del equipo sí suelen pesar).

## Limitaciones (importante)

- Muestra pequeña: 4 carreras objetivo, una sola temporada, sin datos de Melbourne/Mónaco.
- Sin afinidad al circuito (requiere histórico multianual) ni datos de sesiones del propio fin de semana (FP1-FP3).
- **La calibración definitiva sigue pendiente**: `tools/backtest.py` sobre 2023-2025 completas (requiere conexión sin restricciones; ejecutar en el PC de Luis según README).

## Siguiente paso propuesto

Predicción por etapas del fin de semana (como pide Luis): una predicción *pre-finde* (esta), otra *tras FP1*, y otra *tras FP1+FP2/quali*, incorporando los stints de OpenF1 con la tabla `session_weights_by_objective` que ya existe en `model_weights.json`.
