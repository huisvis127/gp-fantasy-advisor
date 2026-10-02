# Backtest de pesos FP1/FP2/FP3

Fecha: 18/07/2026.

## Objetivo

Calibrar dos modelos previos a clasificación: uno disponible tras FP2 y otro
tras FP3. Qualifying y Sprint Qualifying no forman parte de las entradas.

## Datos y separación

- Fuente: vueltas y resultados de sesiones de OpenF1.
- Muestra válida: 38 GP convencionales con al menos 15 pilotos comparables en
  FP1, FP2, FP3 y resultado final.
- Entrenamiento: 12 GP de 2023 y 14 GP de 2024.
- Validación no usada para buscar pesos: 12 GP de 2025.
- Rejilla de pesos: pasos del 1 %, siempre sumando 100 %.

El filtrado de pit-out, 107 %, mejor vuelta y ritmo top-2 replica el código de
la aplicación. La puntuación objetivo incluye posición de carrera,
clasificación, posiciones ganadas/perdidas y penalizaciones DNF observables.
Se omiten DOTD y vuelta rápida porque no están disponibles de forma homogénea
en el endpoint usado.

## Resultado elegido

| Modelo | Pesos | Spearman 2025 | Captura top-5 2025 |
|---|---:|---:|---:|
| FP1+FP2 | FP1 50 % / FP2 50 % | 0,585 | 77,6 % |
| FP1+FP2+FP3 | FP1 42 % / FP2 13 % / FP3 45 % | 0,652 | 79,7 % |

Para FP1+FP2, el pico de entrenamiento (61/39) bajó la captura del top-5 en
2025 a 71,8 %. Se conserva 50/50 por generalizar mejor.

Para tres sesiones, el pico bruto (43/1/56) era menos estable entre 2023 y
2024. Se eligió 42/13/45 por maximizar el peor rendimiento anual y mantener el
resultado en 2025. Mejora el Spearman del anterior 20/40/40, que obtuvo 0,627.

El resultado completo reproducible se guarda en
`docs/reports/session_weights_backtest.json` y se genera con
`python tools/session_weights_backtest.py --step 0.01`.
