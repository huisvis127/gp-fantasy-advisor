# Herramientas de validación

Ejecuta los scripts desde la raíz del repositorio. Son herramientas de desarrollo; no se incluyen en la aplicación Android.

```bash
python -m venv tools/.venv
```

Activa el entorno creado: en Windows, `tools/.venv/Scripts/Activate.ps1`; en Linux/macOS, `source tools/.venv/bin/activate`. Después instala los paquetes:

```bash
python -m pip install -r tools/requirements.txt
```

| Script | Uso | Salida |
|---|---|---|
| `backtest.py` | Backtest general walk-forward: entrena en 2023–2024 y valida en 2025 | `docs/reports/backtest_report.md`, JSON de detalle y actualización de `assets/model_weights.json` |
| `session_weights_backtest.py` | Calibración independiente de las ventanas de prácticas con OpenF1 | `docs/reports/session_weights_backtest.json`; consulta sus opciones para exportar pesos |
| `mini_backtest_2026.py` | Experimento histórico pequeño de 2026 | Resultados por consola; conserva su informe histórico en `docs/reports/` |

```bash
python tools/backtest.py --help
python tools/session_weights_backtest.py --help
```

Las calibraciones descargan datos y pueden tardar. El backtest general modifica los pesos del modelo; revisa los informes y el diff antes de incorporar un nuevo resultado. Las cachés locales están excluidas de Git.
