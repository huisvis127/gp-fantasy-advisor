# Plan de desarrollo — "GP Fantasy Advisor" (asesor para F1 Fantasy)

**Versión:** 1.0 · **Fecha:** 04/07/2026 · **Autor:** Luis (especificación preparada con Claude)
**Objetivo del documento:** que el programador pueda ejecutar sin tener que tomar decisiones de diseño. Todo lo que no esté aquí, se pregunta antes de improvisar.

---

## 1. Resumen ejecutivo

App **Android** (Flutter) que asesora al jugador del juego oficial **F1 Fantasy** (fantasy.formula1.com):

- Predice qué **pilotos** y **constructores** puntuarán más en el próximo Gran Premio (con probabilidades/puntuación esperada).
- Calcula el **mejor equipo posible** dentro del presupuesto (100 M$: 5 pilotos + 2 constructores).
- **Importa el equipo real del usuario** (login en su cuenta F1) para sugerir cambios concretos respetando los 2 cambios gratis por jornada.
- Muestra **ligas propias** y clasificaciones.
- Todo se ejecuta **en el móvil del usuario**, sin servidor propio (coste de infraestructura: 0 €).
- Se publicará en **Google Play**.

Principio rector: **primero útil, luego bonito, luego listo para Play**. Las fases están ordenadas para que cada una entregue algo usable.

### 1.1 App de referencia analizada ("Fantasy Advisor" MotoGP)

Se ha descompilado el APK de referencia. Datos relevantes para este proyecto:

- **Arquitectura de la referencia:** app Kotlin con la interfaz en **WebView** (HTML/CSS/JS locales) y el motor de cálculo en **Python embebido (Chaquopy)**, conectados por un puente JS↔Kotlin↔Python (`fetch-shim.js` → `AndroidBridge` → `bridge.py`). Sin servidor.
- **Pestañas:** Pulso (inicio), Pilotos, Equipos, Marcas/Constructores, Equipo ideal (presupuesto), Mi equipo, Circuito y Liga.
- **Funciones clave:** «Traer equipo del Fantasy» (login vía `sso.motogp.com` y lectura de `fantasy.motogp.com/json/fantasy/`), «Calcular equipo ideal» con presupuesto en millones y precios de mercado (`fantasy_values.json`), «Puntuación para este GP», puntos-por-valor (`scorePerValue`), y clasificación de la liga propia.
- **Motor de predicción:** puntuación por facetas — **oneLap** (vuelta rápida), **pace** (ritmo, con medianas de stint: mejor stint, media top-2, media top-K) y **consistency** (consistencia) — combinadas con **tablas de pesos por sesión (FP1/PR/FP2) ya optimizadas empíricamente** según el objetivo (sprint vs. carrera larga), con reparto proporcional del peso cuando falta una sesión. *Esto confirma lo que se probó: la mezcla ponderada de ritmo/vuelta rápida/consistencia con pesos calibrados.*
- **Diseño:** tema oscuro (fondo `#0c0c0f`), tarjetas *glassmorphism* (`rgba(255,255,255,.04)` + blur), acentos neón (cian `#00e5ff`, lima `#c8ff00`, magenta `#ff3cb8`, violeta `#9b5cff`, naranja `#ff7000`), verde ok `#00e096`, rojo error `#ff4466`, esquinas redondeadas 7–26 px.

**Decisión:** la nueva app de F1 replica este *enfoque* (facetas ponderadas por sesión + optimizador con presupuesto + import del equipo) y este *lenguaje visual*, pero se construye en Flutter (sección 4). Existe una alternativa si el programador lo prefiere y se quiere reciclar código: repetir la arquitectura Kotlin + WebView + Chaquopy reutilizando el HTML/JS y el Python de la referencia adaptados a F1; es válida, aunque Flutter da mejor rendimiento, mejor integración Android y menos piezas móviles.

---

## 2. Reglas del juego oficial (F1 Fantasy 2026) — base funcional

Estas reglas definen la lógica de la app. Verificarlas al inicio del proyecto en fantasy.formula1.com por si cambian.

| Regla | Valor 2026 |
|---|---|
| Presupuesto inicial | 100,0 M$ |
| Composición del equipo | 5 pilotos + 2 constructores |
| Cambios gratis por jornada | 2 |
| Penalización por cambio extra | −10 puntos |
| Boost semanal (DRS) | 1 piloto puntúa ×2 |
| Rango de precios | 3,0 – 34,0 M$ |
| Variación de precio por carrera | ±0,6 M$ (activos < 18,5 M$) · ±0,3 M$ (≥ 18,5 M$) |
| Base del cambio de precio | Media de puntos-por-millón (PPM) de las **últimas 3 carreras** |
| Chips (1 uso por temporada c/u) | Limitless, Wildcard, 3x Boost, No Negative, Final Fix, Autopilot |

Chips: **Limitless** (cambios ilimitados sin tope de presupuesto 1 jornada), **Wildcard** (cambios ilimitados dentro del presupuesto), **3x Boost** (un piloto ×3), **No Negative** (los puntos negativos se quedan en 0), **Final Fix** (sustituir 1 piloto tras el cierre de cambios), **Autopilot** (el boost se asigna automáticamente al mejor piloto del equipo).

Puntuación (resumen; la tabla completa se descarga de la web oficial y se guarda en `assets/scoring_2026.json`): posiciones de carrera 25-18-15-…-1 para el top 10, puntos por posiciones ganadas/perdidas, vuelta rápida, bonus de constructor (p. ej. +10 si ambos pilotos entran en Q3), penalizaciones por DNF/DSQ.

**Requisito de la app:** la tabla de puntuación y las reglas viven en un JSON versionado (no hardcodeadas), para actualizar sin tocar código.

---

## 3. Fuentes de datos (todas gratuitas, llamadas desde el móvil)

| Fuente | Uso en la app | Auth | Riesgo |
|---|---|---|---|
| **Jolpica-F1** `api.jolpi.ca/ergast/f1/` | Resultados históricos, clasificaciones, calendario, parrilla (1950–hoy). Sucesor oficial de Ergast | No | Bajo (open source, comunidad) |
| **OpenF1** `api.openf1.org` | Tiempos por vuelta, sesiones (FP1–FP3, quali), clima, datos casi en directo | No | Bajo |
| **F1 Fantasy API (no oficial)** `fantasy-api.formula1.com/partner_games/f1/` | **Precios** actuales de pilotos/constructores (endpoint público `/players`), y con login: equipo del usuario, ligas, boosters | Pública para precios; Bearer token para lo privado | **Alto**: no documentada, puede cambiar sin aviso |
| **FastF1** (Python, solo en desarrollo) | Backtesting y calibración del modelo en el PC del programador, NO va en la app | — | — |

Notas de implementación:

- Capa `DataRepository` única: cada fuente detrás de una interfaz, con **caché SQLite** (paquete `drift`) y política *stale-while-revalidate* (mostrar caché al instante, refrescar en segundo plano). La app debe funcionar 100 % en modo lectura sin conexión con los últimos datos cacheados.
- Respetar rate limits de Jolpica (actualmente ~500 req/hora sin key): agrupar peticiones y cachear agresivamente. Un usuario normal no debe generar más de ~20 peticiones por sesión.
- Todos los endpoints y URLs en un fichero de configuración remoto simple (JSON alojado en GitHub Pages del repo) para poder corregir URLs rotas **sin publicar nueva versión** en Play.

### 3.1 Login F1 Fantasy e importación del equipo propio (funcionalidad crítica)

El login oficial de formula1.com está protegido por sistemas anti-bot (Imperva/reese84). Estrategia en 3 niveles — el programador implementa A, y si falla en pruebas reales pasa a B; C es el respaldo garantizado:

- **Plan A — API directa:** flujo de login en 2 pasos contra `api.formula1.com` para obtener el `subscriptionToken`, que se usa como `Bearer` en `fantasy-api.formula1.com`. Referencias de implementación: [f1-fantasy-api (Node)](https://github.com/zeroclutch/f1-fantasy-api), [f1-fantasy-api-go](https://github.com/vbonduro/f1-fantasy-api-go), [documentación Postman](https://documenter.getpostman.com/view/11462073/TzY68Dsi), [cheat sheet de endpoints](https://cheatography.com/sertalpbilal/cheat-sheets/fantasy-f1-api-endpoints/).
- **Plan B — WebView:** abrir la página oficial de login en un `WebView` dentro de la app; el usuario se loguea normalmente (el anti-bot ve un navegador real) y la app captura la cookie/token de sesión para llamar después a la API. Es exactamente el patrón que usa la app de referencia con `sso.motogp.com` + cookies, y funciona en producción.
- **Plan C — Entrada manual:** pantalla donde el usuario replica su equipo tocando 5 pilotos + 2 constructores y su presupuesto restante. **Se implementa siempre** (también sirve para modo "¿y si...?" sin cuenta).

Endpoints privados clave (prefijo `fantasy-api.formula1.com/partner_games/f1/<temporada>/`):

- `picked_teams?my_current_picked_teams=true&my_next_picked_teams=true` → equipo actual y del próximo GP
- `league_entrants` → ligas del usuario
- `leaderboards/leagues?league_id=X` → clasificación de una liga
- `boosters` → estado de chips
- `players` y `teams` (públicos) → pilotos/constructores con **precio actual**

La credencial del usuario **nunca** sale del móvil: token guardado en `flutter_secure_storage`, sin analítica sobre datos personales.

---

## 4. Arquitectura técnica

- **Framework:** Flutter (Dart) — una base de código, compila a Android nativo; iOS queda gratis para el futuro.
- **Mínimo Android:** API 26 (Android 8.0). **Target:** el que exija Play en el momento de publicar.
- **Estado:** Riverpod. **HTTP:** dio. **BD local:** drift (SQLite). **Gráficas:** fl_chart. **Secretos:** flutter_secure_storage.
- **Sin backend.** Todo el cálculo (predicción y optimización) es Dart puro en el dispositivo, en un `Isolate` para no congelar la UI.
- **Estructura de carpetas:**

```
lib/
  core/            # tema, constantes, utilidades, config remota
  data/
    sources/       # jolpica_api.dart, openf1_api.dart, fantasy_api.dart
    db/            # tablas drift, DAOs
    repositories/  # DataRepository (única puerta para la UI)
  domain/
    models/        # Driver, Constructor, RaceResult, FantasyPrices, MyTeam...
    engine/        # prediction_engine.dart, team_optimizer.dart, scoring.dart
  ui/
    screens/       # una carpeta por pantalla (sección 6)
    widgets/       # componentes compartidos
assets/
  scoring_2026.json
  model_weights.json   # pesos calibrados por backtesting (sección 5)
tools/                 # scripts Python de backtesting (NO van en la app)
```

- **Modelo de datos (tablas drift):** `drivers`, `constructors`, `races` (calendario), `results` (por piloto y carrera: parrilla, posición final, vuelta rápida, estado DNF), `qualifying_results`, `session_laps` (agregados por sesión, no vuelta a vuelta), `fantasy_prices` (histórico precio por activo y jornada), `fantasy_points` (puntos fantasy reales por activo y jornada), `my_team`, `predictions` (caché de la última predicción).

---

## 5. Motor de predicción y validación (el corazón de la app)

### 5.1 Enfoque

Versión 1: **modelo de puntuación ponderada, transparente y calibrable** (no una red neuronal). Motivos: funciona sin servidor, es explicable al usuario ("por qué recomiendo a X"), los estudios muestran que la posición de salida y el ritmo reciente son los predictores dominantes (correlación > 0,7 entre clasificación y resultado), y **es el mismo enfoque ya validado en la app de referencia** (facetas oneLap/pace/consistency con pesos por sesión, sección 1.1).

Para cada piloto se calcula la **puntuación fantasy esperada** del próximo GP. Igual que en la referencia, cuando hay datos del fin de semana en curso (OpenF1) las tres primeras features se calculan **por sesión** (FP1/FP2/FP3/Quali) y se combinan con una tabla de pesos por sesión calibrada según el objetivo (sprint vs. carrera); las medianas de stint (mejor stint, media top-2 stints) miden el ritmo real filtrando vueltas sucias, y si una sesión no existe su peso se reparte proporcionalmente entre las demás:

```
E[puntos] = w1·RitmoCarrera + w2·RitmoClasificacion + w3·VueltaRapida + w4·Consistencia
          + w5·Forma + w6·AfinidadCircuito + w7·FormaEquipo − w8·RiesgoDNF
```

| Feature | Cálculo (todo con datos Jolpica/OpenF1) |
|---|---|
| RitmoCarrera (pace) | Media ponderada de posición final en las últimas 5 carreras (peso decreciente 5-4-3-2-1), normalizada 0–100; con fin de semana en curso: **medianas de stint largo** de FP (OpenF1), como en la referencia |
| RitmoClasificacion | Ídem con posición de clasificación; si hay FP2/FP3 del fin de semana actual, se mezclan según la tabla de pesos por sesión |
| VueltaRapida (oneLap) | Mejor vuelta relativa al líder por sesión (últimas carreras + FP del fin de semana); también alimenta la prob. de punto de vuelta rápida |
| Forma | Tendencia: diferencia entre media de las últimas 3 y las 3 anteriores |
| Consistencia | 100 − desviación típica de posiciones finales (últimas 8 carreras), normalizada |
| AfinidadCircuito | Media de resultados del piloto en ese circuito (últimos 4 años); si no hay datos, neutro (50) |
| FormaEquipo | Puntos del constructor en las últimas 3 carreras, normalizado |
| RiesgoDNF | % de abandonos del piloto + del equipo en las últimas 2 temporadas |

La puntuación esperada se convierte a **puntos fantasy esperados** aplicando la tabla de `scoring_2026.json` sobre la distribución de posiciones probable, y a **probabilidad de victoria / podio / top-10** mediante un softmax sobre las puntuaciones de los 20-22 pilotos. Constructores: suma de sus 2 pilotos + bonus esperados (prob. de ambos en Q3, etc.).

Además se muestra siempre el **valor** (puntos esperados / precio), porque con tope de 100 M$ el PPM manda.

### 5.2 Calibración y backtesting (obligatorio antes de dar consejos)

Esto responde a "habrá que hacer pruebas de cómo ser buenos en predecir". Script Python en `tools/` (usa FastF1/Jolpica):

1. Descargar temporadas **2023, 2024 y 2025** completas.
2. Para cada GP: calcular las features solo con datos **anteriores** a ese GP (sin mirar el futuro), predecir, y comparar con el resultado real.
3. Métricas: **correlación de Spearman** predicción vs. resultado; **acierto top-10**; **puntos fantasy simulados** del equipo recomendado vs. equipo aleatorio y vs. el equipo medio.
4. **Búsqueda de pesos w1..w8 y de la tabla de pesos por sesión** por grid search / Optuna maximizando los puntos fantasy simulados en 2023-2024, validando en 2025 (evitar sobreajuste).
5. Exportar los pesos ganadores a `assets/model_weights.json`. La app los lee de ahí (y de la config remota, para poder recalibrar sin actualizar la app).

**Criterio de aceptación del modelo:** Spearman ≥ 0,65 en la temporada de validación y el equipo recomendado supera al equipo mediano simulado en ≥ 80 % de los GP. Si no se alcanza, iterar features antes de seguir con UI.

Versión 2 (futura, opcional): entrenar un gradient boosting offline y exportarlo; la interfaz `PredictionEngine` debe permitir enchufar otro motor sin tocar la UI.

### 5.3 Optimizador de equipo

Problema: elegir 5 pilotos + 2 constructores con coste ≤ presupuesto maximizando puntos esperados (variante del problema de la mochila).

- **Equipo ideal desde cero:** enumeración exhaustiva con poda: C(22,5) × C(11,2) ≈ 1,45 M combinaciones → milisegundos en un móvil dentro de un Isolate. No hace falta solver externo.
- **Sugerencia de cambios:** partiendo del equipo importado, evaluar todos los equipos alcanzables con 0, 1 y 2 cambios (y opción "vale la pena un 3º cambio a −10 puntos?"). Mostrar los 3 mejores planes con su ganancia esperada neta.
- **Boost/chips:** recomendar el piloto óptimo para el ×2 (mayor E[puntos]); para chips, mostrar aviso de oportunidad (p. ej. "Wildcard recomendable: tu equipo está a >25 puntos esperados del óptimo").
- Dos modos de recomendación (petición explícita): **"Priorizar pilotos"** vs. **"Priorizar constructores"** — un simple sesgo del presupuesto asignado a cada grupo antes de optimizar, seleccionable con un toggle.

---

## 6. Pantallas y navegación

Diseño heredado de la app de referencia (sección 1.1): **tema oscuro glassmorphism con acentos neón**. Tokens exactos para el programador: fondo `#08080b`/`#0c0c0f`, tarjetas `rgba(255,255,255,.04)` con `saturate(160%) blur(14px)` (en Flutter: `BackdropFilter` + bordes `rgba(255,255,255,.07)`), acentos cian `#00e5ff`, lima `#c8ff00`, magenta `#ff3cb8`, violeta `#9b5cff`, naranja `#ff7000`, ok `#00e096`, error `#ff4466`, warning `#ffb833`, radios 7/10/14/20/26 px. Sin logos ni tipografías oficiales de F1.

Navegación: **bottom bar con 5 pestañas** (equivalencia con la referencia entre paréntesis). Idioma: **español** (strings en ARB para añadir inglés después).

1. **Inicio** *(«Pulso»)* — próximo GP con cuenta atrás y horarios de sesiones; top 3 pilotos y top 2 constructores recomendados (con probabilidad); estado del equipo propio (valor, presupuesto restante); acceso rápido a "optimizar mi equipo"; ficha del circuito con histórico (equivale a la pestaña «Circuito» de la referencia, integrada aquí).
2. **Predicciones** *(«Pilotos» + «Marcas»)* — ranking completo de pilotos y de constructores (sub-pestañas), con: puntos fantasy esperados, prob. victoria/podio/top-10, precio, **puntos-por-valor** (como `scorePerValue` de la referencia) y una barra de "por qué" (desglose de facetas al tocar). Filtros y ordenación por cada columna.
3. **Mi equipo** *(«Mi equipo» + «Equipo ideal»)* — equipo importado (botón **«Traer equipo del Fantasy»**) o manual: alineación visual tipo "carta", valor total, presupuesto, «Puntuación para este GP» estimada; botón **«Calcular equipo ideal»**; "Sugerir cambios" → los 3 mejores planes de transfers; editor "¿y si...?" («Mi futuro equipo» en la referencia) con **«Guardar mi equipo»**; recomendación de boost/chips.
4. **Liga** *(«Liga»)* — ligas del usuario, clasificación de cada una, y comparación de tu equipo con el del líder (qué activos os diferencian).
5. **Ajustes** — login/logout F1, modo de recomendación (pilotos/constructores/equilibrado), actualización de datos, aviso legal, política de privacidad.

Estados vacíos y de error definidos para cada pantalla (sin datos, sin conexión, login caducado, API caída → mensaje claro + reintentar).

---

## 7. Fases de trabajo para el programador

Cada fase termina con un entregable instalable (APK de debug) y sus criterios de aceptación. Estimaciones para un programador Flutter de nivel medio.

### Fase 0 — Preparación (2-3 días)
- Crear repo Git, proyecto Flutter, CI básico (GitHub Actions: analyze + tests + build APK).
- Cuenta Google Play Console (25 US$, se hace ya porque el testing cerrado para cuentas personales exige **12 testers durante 14 días** antes de producción — planificarlo con antelación).
- Verificar a mano (con curl/Postman) los endpoints de Jolpica, OpenF1 y el endpoint público `players` de fantasy-api. Documentar respuestas reales en `docs/api_samples/`.
- ✅ *Criterio:* CI en verde y los 3 endpoints devolviendo datos verificados.

### Fase 1 — Datos y caché (1-1,5 semanas)
- Implementar `sources`, tablas drift y `DataRepository` con caché.
- Sincronización inicial: calendario 2026, resultados de la temporada, últimas 2 temporadas históricas, precios fantasy actuales.
- ✅ *Criterio:* con el móvil en modo avión (tras una sync), la app muestra calendario, resultados y precios. Tests unitarios de parsers con las respuestas reales guardadas.

### Fase 2 — Motor de predicción + backtesting (1,5-2 semanas)
- Scripts `tools/backtest.py` (features, simulador de puntuación fantasy, grid search de pesos) según sección 5.2.
- Portar el cálculo de features y scoring a Dart (`domain/engine/`), con tests que comparan resultados Dart vs. Python sobre los mismos datos (tolerancia < 0,1 %).
- ✅ *Criterio:* métricas de la sección 5.2 alcanzadas y documentadas en `docs/backtest_report.md`; `model_weights.json` generado.

### Fase 3 — Optimizador + pantallas Inicio y Predicciones (1,5 semanas)
- `team_optimizer.dart` (enumeración con poda, en Isolate) + toggle pilotos/constructores.
- UI de Inicio y Predicciones completas con datos reales.
- ✅ *Criterio:* optimizar equipo ideal < 2 s en un móvil de gama media; ranking con desglose "por qué" visible.

### Fase 4 — Mi equipo, login y ligas (2 semanas, la más incierta)
- Entrada manual del equipo (Plan C) primero — desbloquea toda la UI.
- Login Plan A (API directa); si el anti-bot lo impide en dispositivo real, Plan B (WebView + captura de token). Timebox: 4 días; si A no funciona en 2, saltar a B.
- Importar equipo, presupuesto, chips y ligas; pantalla Ligas.
- Sugeridor de cambios (0/1/2 transfers + análisis del 3º) y recomendación de boost.
- ✅ *Criterio:* con la cuenta real del usuario (Luis), la app importa su equipo y su liga y sugiere cambios válidos (respetando presupuesto y reglas). Con login caducado, la app lo detecta y ofrece re-login sin crashear.

### Fase 5 — Pulido de diseño (1 semana)
- Ajustar el diseño a los tokens de la app de referencia (sección 6), animaciones, modo oscuro/claro, iconografía propia.
- Accesibilidad básica (tamaños de texto, contraste) y rendimiento (arranque < 3 s).
- ✅ *Criterio:* revisión visual aprobada por Luis pantalla a pantalla.

### Fase 6 — Publicación en Google Play (1 semana + 14 días de testing cerrado)
- Nombre **sin marcas registradas**: no usar "F1", "Formula 1", logos ni fotos oficiales. Propuesta: **"GP Fantasy Advisor"**. Incluir en la ficha y en la app: *"App no oficial. No afiliada a Formula One Licensing B.V."*
- Política de privacidad (página web simple, puede ser GitHub Pages): qué se guarda (nada sale del dispositivo salvo llamadas a las APIs públicas), credenciales solo en el móvil.
- Formulario de Data Safety de Play, icono/capturas/descripción, firma del app bundle, testing cerrado (12 testers × 14 días), luego producción.
- ✅ *Criterio:* app aprobada y pública en Play.

**Total estimado: 8-10 semanas** de trabajo efectivo (+ los 14 días de espera del testing cerrado, que se solapan con la Fase 5-6).

---

## 8. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| La API no oficial de F1 Fantasy cambia o bloquea | Media-alta | Alto (precios, equipo, ligas) | Config remota de endpoints; Plan B WebView; Plan C manual siempre disponible; precios editables a mano como último recurso |
| Anti-bot impide el login Plan A | Alta | Medio | Plan B (WebView) diseñado desde el día 1; timebox de 4 días |
| Rechazo en Play por marcas F1 | Media | Alto | Nombre neutro, sin logos/fotos oficiales, disclaimer visible, arte propio |
| El modelo predice mal | Media | Alto (es la promesa de la app) | Backtesting obligatorio con criterio de aceptación (5.2) antes de construir la UI encima; pesos actualizables por config remota |
| Rate limits de Jolpica | Baja | Medio | Caché agresiva, sync 1 vez al día + botón manual |
| Cambio de reglas del juego a mitad de temporada | Baja | Medio | Reglas y puntuación en JSON versionado + config remota |

---

## 9. Qué debe entregar el programador

1. Repositorio Git con historial limpio y `README` de arranque (cómo compilar, cómo regenerar `model_weights.json`).
2. APK firmado + app bundle publicado en Play.
3. `docs/backtest_report.md` con las métricas del modelo.
4. Tests: parsers de las 3 APIs, motor de predicción (Dart vs. Python), optimizador (casos con presupuesto justo, activos repetidos, etc.).
5. Config remota desplegada (JSON en GitHub Pages) y documentada.

## 10. Decisiones ya tomadas (no re-discutir con el programador)

- Flutter, sin backend, todo en el dispositivo.
- Juego objetivo: **solo el F1 Fantasy oficial** (no otros fantasy de F1) en v1.
- Español primero; estructura preparada para inglés.
- Modelo v1 ponderado y explicable; ML avanzado queda para v2.
- Entrada manual del equipo se implementa siempre, haya o no login.
- Publicación en Google Play con nombre sin marcas de F1.

---

*Referencias: [reglas y presupuesto 2026](https://intothechicane.com/2026/02/26/f1-fantasy-2026-the-complete-beginners-guide/) · [cambios de precio (ventana de 3 carreras)](https://intothechicane.com/2026/04/10/f1-fantasy-3-race-rolling-window-how-price-changes-work-in-2026/) · [chips 2026](https://intothechicane.com/2026/03/19/f1-fantasy-chips-2026-when-to-use-every-boost-and-why/) · [puntuación 2026](https://f1pitwall.dev/blog/f1-fantasy-scoring-2026) · [Jolpica-F1](https://github.com/jolpica/jolpica-f1) · [OpenF1](https://openf1.org/) · [FastF1](https://docs.fastf1.dev/) · [f1-fantasy-api](https://github.com/zeroclutch/f1-fantasy-api) · [endpoints Fantasy F1](https://cheatography.com/sertalpbilal/cheat-sheets/fantasy-f1-api-endpoints/) · [API Postman](https://documenter.getpostman.com/view/11462073/TzY68Dsi)*
