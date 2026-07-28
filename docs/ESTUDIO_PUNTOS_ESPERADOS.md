# Estudio de los puntos esperados

Fecha: 24 de julio de 2026.

## Pregunta

¿Conviene que Polewise estime todos los componentes de F1 Fantasy
(adelantamientos, posiciones ganadas, vuelta rápida, Driver of the Day y
penalizaciones), o es más robusto proyectar únicamente clasificación, carrera
y Sprint?

## Datos y método

- 268 actuaciones piloto-GP de 2025.
- 13 rondas con desglose Fantasy completo y homogéneo.
- Fuente: `JoshCBruce/fantasy-data`, cuyos datos fueron extraídos de las
  estadísticas del juego oficial.
- No se mezcló 2024 porque no se encontró el mismo desglose completo y mezclar
  tablas de puntuación distintas falsearía la comparación.
- Proyección walk-forward: para cada piloto se usaron únicamente sus tres
  rondas anteriores, ponderadas 1/2/3.
- Validación separada: rondas 11 a 15.

El script reproducible es `tools/backtest_fantasy_components_2025.py`.

## Resultados

| Medida | Resultado |
|---|---:|
| Correlación entre puntos básicos reales y total Fantasy real | 0,750 |
| Persistencia de los puntos extra entre dos carreras | 0,116 |
| Persistencia de los adelantamientos entre dos carreras | 0,020 |
| Proyección básica, Spearman global | 0,518 |
| Proyección ampliada, Spearman global | 0,439 |
| Proyección básica, validación R11-R15 | 0,431 |
| Proyección ampliada, validación R11-R15 | 0,363 |

Los puntos básicos explican buena parte del orden Fantasy final, mientras que
los extras tienen muy poca persistencia. Añadir al siguiente GP la media
reciente de esos extras empeoró la correlación tanto en el conjunto completo
como en la validación final.

## Decisión aplicada

La cifra de Análisis es:

`E[puntos] = E[clasificación] + E[carrera] + E[Sprint, si existe]`

- Clasificación y carrera se obtienen de distribuciones probabilísticas de
  posición, no de una única posición fija.
- Carrera incluye el riesgo esperado de DNF.
- Sprint aplica la penalización DNF reducida de 2026.
- No se suman adelantamientos, posiciones ganadas, vuelta rápida ni Driver of
  the Day.
- La media Fantasy histórica deja de mezclarse con el total previsto porque
  arrastraba esos extras poco predecibles.

Los extras siguen siendo reales y relevantes para la puntuación final, pero
Polewise no finge poder anticiparlos con una precisión que el backtest no
respalda.

## Qué es un adelantamiento

No es la diferencia entre parrilla y resultado:

- **Posiciones ganadas/perdidas**: comparación neta entre la posición de salida
  y la clasificación final.
- **Adelantamientos**: pases legales realizados en pista durante la sesión. No
  cuentan los cambios por entrada al pit lane, avería o un coche que circula
  anormalmente lento.

Por eso un piloto puede terminar en la misma posición en la que salió y, aun
así, sumar adelantamientos si perdió y recuperó posiciones durante la carrera.
