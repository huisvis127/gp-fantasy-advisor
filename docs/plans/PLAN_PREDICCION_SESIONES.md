# Plan — Predicción por etapas del fin de semana

**Fecha:** 05/07/2026 · **Objetivo:** que la predicción mejore a medida que avanza el fin de semana, como pidió Luis: una predicción *pre-finde*, otra *con FP1+FP2* y otra *con FP1+FP2+FP3*, siempre antes de clasificación. Equivale al comportamiento de la app de referencia de MotoGP (dos modelos distintos según haya dos o tres prácticas).

---

## 0. Por qué NO se cogen los datos "directamente de F1 oficial"

Pregunta recurrente de Luis, respuesta corta: **porque no existe una API oficial pública de F1.**

- Formula1.com **no ofrece API pública**. Sus datos en vivo (timing, telemetría) van cifrados a sus propias apps (F1 TV / F1 App) bajo licencia; el acceso programático está protegido por anti-bot (Imperva/reese84) y prohibido por sus términos de uso. No hay forma legítima y estable de "conectarse a la F1 oficial".
- Lo que usamos es **el mismo dato oficial, pero re-publicado por servicios comunitarios legales y gratuitos**:
  - **Jolpica-F1** (sucesor de Ergast): resultados, clasificaciones y calendarios históricos — los datos oficiales consolidados tras cada sesión.
  - **OpenF1**: tiempos por vuelta, stints y sesiones casi en directo — decodifica el timing público del directo.
- La **única** parte que sí va contra servidores de Formula1 es la del juego Fantasy (precios, tu equipo, ligas), vía su **API no oficial y sin documentar** (`fantasy-api.formula1.com`). Por eso es la parte frágil de la app: puede cambiar sin aviso y por eso el login a veces requiere el navegador integrado.

En resumen: no es una elección rara, es lo que hacen todas las apps de este tipo (incluida la de referencia de MotoGP, que lee `fantasy.motogp.com` con la sesión del usuario y calcula con datos de timing).

---

## 1. Concepto: etapas de predicción

| Etapa | Datos usados | Cuándo |
|---|---|---|
| **Pre-finde** | Solo histórico (lo actual) | Hasta que termina FP1 |
| **Con FP1** | Histórico + vueltas/stints de FP1 | Viernes |
| **Con FP1+FP2** | + FP2 | Viernes/Sábado |
| **Con FP1-FP3** | + FP3 | Sábado |

La etapa activa se detecta sola y se muestra en la UI. La clasificación y la sprint quali se excluyen. Hay dos tablas calibradas con F1 real en `model_weights.json`: FP1+FP2 (50/50) y FP1+FP2+FP3 (42/13/45). Metodología y validación: `docs/reports/session_weights_backtest.md`.

## 2. Datos (OpenF1, sin coste)

1. `GET /v1/sessions?year=YYYY&country_name=X` → sesiones del meeting. Filtrar por fecha ±5 días de la carrera seleccionada (¡España tiene 2 GPs en 2026!). Mapa de nombres Jolpica→OpenF1: UK→United Kingdom, USA→United States, UAE→United Arab Emirates.
2. Por cada sesión terminada (`date_end < ahora`) de tipo Practice 1/2/3, Sprint Qualifying o Qualifying: `GET /v1/laps?session_key=K` → vueltas.
3. Agregado por piloto (ya implementado en `OpenF1Api.aggregateStints`): mejor vuelta y media top-2 de vueltas limpias (filtro 107% y pit-out) → **gap % contra el mejor de la sesión** en dos series: `onelap` (vuelta única) y `pace` (ritmo tandas).
4. `GET /v1/drivers?session_key=K` una vez por finde → mapear `driver_number` → nuestro `driverId` por apellido (mismo matching tolerante que la importación del equipo).

Volumen: ~1500 vueltas × 5 sesiones ≈ 300 KB por finde, solo del GP seleccionado, cacheado en memoria. Nada de esto toca la base de datos (sin migraciones drift).

## 3. Motor (cómo cambian las features)

Con agregados del finde presentes en `DriverContext.sessionAggregates` (claves `onelap:fp1`, `pace:fp2`… con el gap %):

- **vuelta_rapida** = 100 − (gap medio ponderado por sesión / 3%) × 100 → sustituye a la aproximación histórica (el dato del finde manda: es el mismo coche en la misma pista).
- **ritmo_carrera** = 50% histórico + 50% ritmo de tandas del finde (100 − gap/2% × 100). Mezcla, no sustitución: las tandas de FP pueden engañar (motor bajado, gasolina).
- Resto de features: sin cambios. Piloto sin datos del finde (p. ej. rookie en FP1 con otro coche): conserva sus features históricas.

## 4. UI

- Chip de etapa visible en **Pulso** (junto al GP) y en **Ranking** (cabecera): `PRE-FINDE` / `CON FP1` / `CON FP1+FP2` / … en cian, con la ponderación aplicada al tocarlo (hint).
- El pull-to-refresh de Pulso también refresca los datos del finde.
- Si OpenF1 falla: banner con el error y se sigue con la predicción pre-finde (nunca en silencio).

## 5. Archivos

| Archivo | Cambio |
|---|---|
| `lib/core/weekend_provider.dart` | NUEVO: descarga, agrega, mapea pilotos, detecta etapa |
| `lib/data/sources/openf1_api.dart` | añadir `getSessionDrivers()` |
| `lib/domain/engine/prediction_engine.dart` | blending por sesión en `_extractFeatures` |
| `lib/core/app_providers.dart` | inyectar agregados del finde en los `DriverContext` |
| `lib/ui/.../home_screen.dart`, `predictions_screen.dart` | chip de etapa + refresh |

## 6. Criterios de aceptación

1. Ranking cambia de forma visible entre pre-finde y post-FP (chip de etapa correcto).
2. Sin red u OpenF1 caído → predicción pre-finde + aviso, sin crash.
3. GP pasado seleccionado → usa las sesiones de aquel finde (sirve para validar a posteriori).
4. Fin de semana sprint usa la tabla sprint (fp1+sq).

## 7. Validación futura (fase 2)

Repetir anualmente `tools/session_weights_backtest.py` incorporando la temporada terminada. Mantener siempre una temporada completa fuera de la búsqueda para evitar sobreajuste.
