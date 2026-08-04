# GP Fantasy Advisor

Aplicación Android no oficial para consultar datos, analizar pilotos y constructores, preparar una estrategia de F1 Fantasy y revisar las ligas del usuario. Mantiene la identidad visual roja y oscura del proyecto.

No está afiliada a Formula One Licensing B.V.

## Navegación

- **Resumen**: siguiente Gran Premio, sincronización y recomendaciones principales.
- **Análisis**: ranking configurable con pesos de rendimiento, forma, circuito y riesgo.
- **Fantasy**: equipo ideal y personal, mercado de precios, plan a tres Grandes Premios y puntuación provisional en directo.
- **Circuito**: información del GP, afinidad e inteligencia de las sesiones de pista.
- **Liga**: clasificación, evolución, medallero y estrategia de diferenciales frente a rivales.
- **Ajustes**: sincronización y alertas locales 24 horas y 1 hora antes del cierre oficial.

## Datos y privacidad

- Calendario, resultados y clasificación: Jolpica F1.
- Precios, puntos, propiedad y catálogo de F1 Fantasy: feeds públicos oficiales actuales.
- Ritmo y consistencia de las sesiones: OpenF1.
- Cuenta, equipo y ligas: se abren dentro de la web oficial. La contraseña no pasa por la aplicación ni se guarda en ella.
- La sesión capturada y los datos privados se almacenan cifrados en el dispositivo.
- Si una fuente no responde, se conservan los últimos datos válidos y se muestra el estado de sincronización.
- La puntuación en directo y las probabilidades de precios se identifican como provisionales o estimadas.

## Compilar y comprobar

Requiere Flutter estable y Android SDK con API 26 o superior.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk` y el paquete de Play Store en `build/app/outputs/bundle/release/app-release.aab`.

Para publicar, copia `android/key.properties.example` como `android/key.properties`, crea una clave de subida y completa sus valores. Sin ese archivo, las compilaciones locales se firman con la clave de desarrollo y no deben publicarse.

## Estructura principal

```text
lib/core/             tema, constantes, proveedores y alertas
lib/data/             APIs, base de datos y repositorios
lib/domain/           modelos, puntuación, predicción y optimizadores
lib/ui/screens/       pantallas organizadas por sección
lib/ui/widgets/       componentes visuales compartidos
assets/               reglas, pesos y configuración de respaldo
test/                 pruebas de APIs, persistencia y lógica
```

## Nota sobre el acceso oficial

F1 Fantasy puede cambiar sus servicios privados o sus comprobaciones de seguridad. El flujo principal usa la propia web oficial embebida para reducir ese riesgo. La comprobación definitiva del acceso, del equipo y de las ligas debe hacerse en un teléfono con una cuenta real.
