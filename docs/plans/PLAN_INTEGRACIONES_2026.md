# Laboratorio de integraciones 2026

Fecha de evaluación: 4 de agosto de 2026.

## Principio

No depender de otras aplicaciones como proveedoras de datos salvo que publiquen una API estable. La integración recomendada consiste en adoptar las funciones útiles con datos de Jolpica, OpenF1 y la cuenta oficial de F1 Fantasy, manteniendo el cálculo y la información privada en el dispositivo.

## Punto de partida

La aplicación ya incluye predicciones, valor en puntos por millón, optimizador de 5 pilotos y 2 constructores, importación de equipo, acceso a ligas, historial de posiciones y medallero. También tiene modelos locales para precios, puntos fantasy, chips usados y pesos por sesión.

## Candidatas

| Prioridad | Función | Valor para el usuario | Viabilidad | Datos y riesgo | Prueba mínima |
|---|---|---|---|---|---|
| 1 | Predictor de cambio de precio | Muestra subida/bajada esperada y puntos necesarios para cada tramo | Alta | Precios oficiales, puntos recientes y predicción propia. Hay que validar las reglas 2026 tras cada GP | Recalcular 3 GP pasados y comparar tramo previsto con cambio real |
| 2 | Planificador de 2-3 GP | Optimiza puntos, cambios y crecimiento de presupuesto a medio plazo | Media-alta | Reutiliza predicciones y optimizador; aumenta la incertidumbre en carreras futuras | Comparar plan de una carrera con plan de tres en backtesting |
| 3 | Asesor de chips | Recomienda guardar o usar Wildcard, Limitless, No Negative, Autopilot y multiplicadores | Media-alta | El endpoint de boosters ya está contemplado; requiere proyecciones de varios GP | Reproducir decisiones históricas y medir ganancia frente a no usar chip |
| 4 | Alertas de cierre y datos nuevos | Evita olvidar cambios y avisa tras FP/Quali cuando cambia la recomendación | Alta | Notificaciones locales y calendario; no necesita servidor | Alarma local y aviso solo si la recomendación cambia de forma material |
| 5 | Análisis de rivales y diferenciales | Indica activos comunes, diferenciales y combinaciones para atacar o defender posición | Media | La liga ya se importa; la alineación rival puede no estar disponible antes del cierre | Probar con liga real antes y después del cierre de una jornada |
| 6 | Puntuación provisional en directo | Sigue equipo, rivales y liga durante cada sesión | Media | OpenF1 permite eventos casi en directo; DOTD, penalizaciones y correcciones pueden llegar tarde | Etiqueta “provisional”, reconciliación con resultado oficial y medición del error |
| 7 | Hindsight y auditoría de decisiones | Explica cuánto costó cada cambio, boost o chip frente al óptimo | Alta para datos locales; media para histórico importado | Base local y resultados oficiales; el histórico de equipos puede ser incompleto | Informe de una jornada con equipo real, equipo óptimo y diferencia explicada |
| 8 | Inteligencia de sesión | Ritmo largo, degradación, riesgo DNF, adelantamientos y comparación de pilotos | Media-alta | OpenF1 y Jolpica; la previsión meteorológica necesitaría otra fuente | Añadir un panel pequeño y comprobar que cambia la predicción de forma explicable |

## Orden recomendado

### Experimento A: precios

1. Guardar precio y puntos reales de cada activo por jornada.
2. Implementar el cálculo de ventana móvil y los umbrales como estrategia versionada, no como reglas fijas en la interfaz.
3. Mostrar cambio esperado, probabilidad por tramo y puntos necesarios.
4. Ejecutar backtesting. Si el acierto de tramo no es suficiente, mantener solo “puntos necesarios” y ocultar la probabilidad.

### Experimento B: planificador y chips

1. Proyectar tres GP con bandas de incertidumbre.
2. Optimizar puntos netos descontando cambios adicionales.
3. Añadir crecimiento esperado del presupuesto como objetivo configurable.
4. Simular chips sin activarlos nunca en la cuenta oficial: la aplicación asesora, el usuario confirma en F1 Fantasy.

### Experimento C: directo y rivales

1. Construir puntuación provisional por evento.
2. Reconciliarla al terminar la sesión con el feed oficial.
3. Activar rivales solo donde la cuenta real devuelva alineaciones válidas.
4. Degradar con elegancia a clasificación e histórico si el endpoint privado deja de responder.

## Funciones que no se recomiendan ahora

- Copiar juegos completos de predicción de posiciones o ligas con reglas propias: cambia el producto de asesor a plataforma de juego.
- Chat o asistente de IA genérico: añade coste y no mejora la calidad del consejo si antes no existe un planificador sólido.
- Concursos con dinero o pagos entre usuarios: introduce regulación, soporte y riesgos ajenos al objetivo.
- Dependencia directa de F1 Fantasy Tools, GridRival u otra app sin API pública y permiso explícito.

## Criterios para conservar una integración

Una función pasa del laboratorio a la versión estable solo si:

1. funciona con datos reales y conserva un modo útil cuando falla una fuente;
2. no expone credenciales ni datos privados fuera del dispositivo;
3. mejora una decisión medible del usuario;
4. tiene pruebas automáticas y no rompe las actuales;
5. explica si el dato es oficial, estimado o provisional.
