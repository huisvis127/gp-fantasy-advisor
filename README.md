# Polewise

Aplicación Android no oficial para consultar datos, analizar pilotos y constructores, preparar un equipo fantasy y revisar las ligas del usuario. Polewise utiliza una identidad visual negra y verde neón propia.

Polewise no está asociada de ninguna manera con las compañías de Formula 1.

## Navegación

- **Resumen**: siguiente Gran Premio, estado de sincronización y recomendaciones principales.
- **Análisis**: ranking configurable con pesos de rendimiento, forma, circuito y riesgo.
- **Fantasy**: equipo ideal según presupuesto y consulta/importación del equipo personal.
- **Circuito**: información del GP seleccionado y afinidad de cada participante.
- **Liga**: acceso mediante la web oficial de F1 Fantasy, ligas y clasificaciones.

## Datos y privacidad

- Calendario, resultados y clasificación: Jolpica F1.
- Precios y catálogo de F1 Fantasy: feeds públicos oficiales actuales.
- Cuenta, equipo y ligas: se abren dentro de la web oficial. La contraseña no pasa por la aplicación ni se guarda en ella.
- La sesión capturada y los datos privados se almacenan cifrados en el dispositivo.
- Las estadísticas de uso son opcionales y se desactivan por defecto. Con
  permiso, se envían recuentos agrupados al receptor propio y eventos generales
  a Google Analytics. No se envían datos de la cuenta fantasy ni contenido.
- El usuario puede borrar desde Ajustes la sesión, el equipo, las ligas y las
  estadísticas pendientes.
- Si una fuente temporalmente no responde, se conservan los últimos datos válidos y se muestra el estado de la sincronización.

## Compilar y comprobar

Requiere Flutter estable y Android SDK con API 26 o superior.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`. Para una
publicación real deben configurarse `POLEWISE_DEVELOPER_NAME`,
`POLEWISE_SUPPORT_EMAIL` y `POLEWISE_PRIVACY_URL` mediante `--dart-define`.

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
