# Documentación

La descripción vigente de la aplicación y las instrucciones de compilación están en el [README principal](../README.md).

## Planes técnicos

- [Predicción por sesiones](plans/PLAN_PREDICCION_SESIONES.md): metodología y ventanas de entrenamiento del modelo.
- [Integraciones 2026](plans/PLAN_INTEGRACIONES_2026.md): evaluación de funciones y alternativas realizada en agosto de 2026. Es contexto de diseño; el estado actual se describe en el README principal.

## Informes de validación

- [Backtest completo](reports/backtest_report.md) y [datos JSON](reports/backtest_report.json): entrenamiento 2023–2024 y validación 2025. El informe indica que no se cumplió el criterio de aceptación; se conserva esa conclusión.
- [Calibración por sesiones](reports/session_weights_backtest.md) y [datos JSON](reports/session_weights_backtest.json): pesos de FP1+FP2 y FP1+FP2+FP3.
- [Prueba inicial de 2026](reports/backtest_mini_2026.md): informe histórico de una muestra pequeña.

Los informes conservan sus fechas y resultados originales. Moverlos de carpeta no equivale a volver a ejecutar ni validar el modelo.

## Archivo histórico

[Plan de desarrollo original](archive/PLAN_DESARROLLO.md): especificación de julio de 2026, mantenida porque algunos comentarios del código la referencian. Sus fases y alternativas son históricas y no sustituyen la documentación actual.

Las APK anteriores, capturas, prototipos, registros y cachés del ordenador están en `.local/archive/2026-10-02/`, fuera de Git. El resumen de recuperación local está en `.local/README.md`.
