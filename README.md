# Fantasy Companion F1

Aplicación Android no oficial para consultar datos, analizar pilotos y constructores, preparar un equipo de F1 Fantasy y revisar las ligas del usuario. Mantiene la disposición y la lógica de la aplicación MotoGP de referencia, adaptadas a la identidad visual roja y oscura de Fórmula 1.

No está afiliada a Formula One Licensing B.V.

## Navegación

- **Resumen**: siguiente Gran Premio, estado de sincronización y recomendaciones principales.
- **Análisis**: ranking configurable con pesos de rendimiento, forma, circuito y riesgo.
- **Fantasy**: equipo ideal según presupuesto y consulta/importación del equipo personal.
- **Circuito**: información del GP seleccionado y afinidad de cada participante.
- **Liga**: selector de liga activa, clasificación, gráficas de puntos y posiciones por GP, y medallero de podios.

## Datos y privacidad

- Calendario, resultados y clasificación: Jolpica F1.
- Precios y catálogo de F1 Fantasy: feeds públicos oficiales actuales.
- Cuenta, equipo y ligas: se abren dentro de la web oficial. La contraseña no pasa por la aplicación ni se guarda en ella.
- La sesión capturada y los datos privados se almacenan cifrados en el dispositivo.
- Al actualizar la cuenta se captura también la clasificación de cada GP cerrado para construir el histórico de la liga.
- Si una fuente temporalmente no responde, se conservan los últimos datos válidos y se muestra el estado de la sincronización.

## Compilar y comprobar

Requiere Flutter estable y Android SDK con API 26 o superior.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura principal

```text
lib/core/             tema, constantes y configuración remota
lib/data/             APIs, base de datos y repositorios
lib/domain/           modelos, puntuación, predicción y optimizador
lib/ui/screens/       pantallas organizadas por sección
lib/ui/widgets/       componentes visuales compartidos
assets/               reglas, pesos y configuración de respaldo
test/                 pruebas de APIs, modelos y lógica
```

## Nota sobre el acceso oficial

F1 Fantasy puede cambiar sus servicios privados o sus comprobaciones de seguridad. El flujo principal usa la propia web oficial embebida para reducir ese riesgo. La comprobación definitiva del acceso, del equipo y de las ligas debe hacerse en un teléfono con una cuenta real.
