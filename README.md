# GP Fantasy Advisor

Aplicación Android no oficial para preparar equipos de F1 Fantasy, consultar datos de pista y analizar ligas. Versión actual: **1.4.4+32**. No está afiliada a Formula One Licensing B.V.

## Empezar

Esta carpeta es la única raíz del proyecto. Abre aquí el editor y ejecuta los comandos desde aquí.

Requisitos: Flutter **3.44.8** (Dart incluido), Java 17 o compatible, y Android SDK. La aplicación funciona desde Android 8 (API 26); para compilar se necesita la API indicada por Flutter, actualmente 36.

```bash
flutter pub get
flutter analyze
flutter test
node --test test/data/capture_league_limit_test.cjs
flutter build apk --release
```

La APK se genera en `build/app/outputs/flutter-apk/app-release.apk`. La copia local entregada de la versión 1.4.4 está en `dist/GP-Fantasy-Advisor-1.4.4.apk`. Los instaladores quedan fuera de Git; el repositorio contiene el código fuente.

## Funciones actuales

- **Resumen y análisis:** próximo GP, sincronización, predicciones y pesos configurables.
- **Fantasy:** equipo personal e ideal con el ×2 incluido en sus proyecciones, mercado de precios, plan de tres GP, chips y puntuación provisional en directo.
- **Circuito:** contexto del GP y datos de sesiones.
- **Liga:** clasificación, evolución, medallero y diferenciales. Se admiten ligas de hasta **20 equipos**. Las ligas mayores aparecen bloqueadas: no se pueden seleccionar ni descargar su historial o alineaciones. Si falta el tamaño, se comprueba la clasificación antes de continuar. La captura solicita solo la liga activa y su historial de forma secuencial. Cada equipo puede elegir entre **40 colores (20 neón y 20 normales)**, combinados en la paleta y guardados por liga y equipo. El color se aplica a la clasificación, leyendas, gráficas, medallero y detalle desplegable. El detalle muestra pilotos, constructores, multiplicadores y puntos del fin de semana, separados del total de temporada.
- **Ajustes:** modo claro u oscuro, idiomas, sincronización y alertas locales de cierre. La apariencia se conserva entre sesiones.

## Dónde está cada cosa

```text
lib/                  aplicación Flutter
  core/               tema, preferencias, proveedores y alertas
  data/               APIs, persistencia y repositorios
  domain/             modelos, predicciones y optimizadores
  ui/                 pantallas y componentes
android/              configuración y recursos Android
assets/               reglas, pesos, catálogos e icono
test/                 pruebas de interfaz, lógica, APIs y persistencia
tools/                scripts de calibración y backtesting
docs/                 índice, planes, informes y especificación histórica
.github/workflows/    verificaciones y compilación en GitHub
dist/                 APK local actual; ignorada por Git
.local/               archivo local de material anterior; ignorado por Git
```

Consulta el [índice de documentación](docs/README.md) y la [guía de herramientas](tools/README.md). `lib/data/db/database.g.dart` es código generado necesario para la base de datos y se mantiene en Git. Al modificar las tablas, regenera con:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Git y GitHub

Repositorio: [huisvis127/gp-fantasy-advisor](https://github.com/huisvis127/gp-fantasy-advisor).

Trabaja en ramas y envía los cambios mediante una pull request a `main`. Las ramas antiguas se conservan como historial; no representan carpetas adicionales de la aplicación. GitHub comprueba el código y las pruebas y genera una APK descargable en los artefactos de la ejecución.

```bash
git status
git switch -c feature/nombre-del-cambio
git add <archivos>
git commit -m "Describe el cambio"
git push -u origin feature/nombre-del-cambio
```

`.gitignore` excluye compilaciones, cachés, capturas locales, instaladores, sesiones del editor y credenciales.

## Firma y distribución

La numeración de Android (`versionCode`, después de `+` en `pubspec.yaml`) debe superar todas las APK distribuidas anteriormente. El Android de prueba tenía instalada la versión 1.4.0 con código 28; las entregas posteriores usan códigos crecientes; la actual 1.4.4 usa código 32. Antes de entregar una APK, verifica la firma y prueba la actualización sobre una versión anterior, además de comprobar que la copia de `dist/` coincida con la compilación.

Sin `android/key.properties`, la APK de release se firma con la clave de desarrollo y sirve para instalación y pruebas locales. Para Google Play, configura una clave de subida privada con `android/key.properties.example` como referencia y genera:

```bash
flutter build appbundle --release
```

El paquete queda en `build/app/outputs/bundle/release/app-release.aab`. Las claves, contraseñas y `key.properties` no se suben a Git.

## Datos

Jolpica proporciona calendario y resultados; los feeds oficiales de F1 Fantasy aportan precios y puntos; OpenF1 aporta datos de sesiones. La contraseña se introduce en la web oficial embebida, y la sesión privada se guarda cifrada en el dispositivo. Si una fuente falla, se conserva la caché disponible. La puntuación en directo y las estimaciones de precios se indican como provisionales.

La validación histórica y sus limitaciones están documentadas en [los informes](docs/README.md). El acceso oficial y las notificaciones requieren comprobación adicional en un teléfono real.

Después de instalar una actualización, usa **Liga → Actualizar** para capturar las alineaciones de los equipos visibles. Solo se muestran las alineaciones que permite consultar la web oficial; si falta acceso o puntuación del GP capturado, el detalle lo indica sin sustituir los puntos por el total de temporada. La captura solicita como máximo 20 equipos con tres peticiones simultáneas.

La proyección Fantasy suma clasificación, carrera y Sprint cuando corresponde, con el ×2 del piloto elegido. Es una estimación parcial: no predice adelantamientos, posiciones ganadas, Driver of the Day ni puntos de paradas en boxes. La pantalla muestra la etapa de datos (pre-finde o prácticas disponibles) y explica fallos de sesiones. Un fallo de FP2/FP3 conserva las métricas válidas de las otras prácticas; las respuestas vacías no bloquean posteriores actualizaciones.

La clasificación de liga se refresca desde el feed oficial y cruza GUID, identificadores sociales y número de equipo sin contar alias como miembros nuevos. Las capturas anteriores con estructura `current/rounds` siguen siendo legibles. El icono verde neón de Polewise se conserva en todos los tamaños y en los recursos adaptativos de Android.

Los cálculos de equipo ideal, cambios, estrategia y revisión se ejecutan en un isolate, con una sola optimización simultánea. Las pestañas se cargan al visitarlas. Si Jolpica y OpenF1 discrepan sobre el país de un GP y el filtro de país responde 400/404, se consulta el índice del año y se seleccionan únicamente las prácticas terminadas dentro de la ventana de ese GP.
