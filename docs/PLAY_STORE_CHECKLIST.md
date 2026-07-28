# Publicación de Polewise en Google Play

## Datos que faltan antes de publicar

- Nombre público o marca del desarrollador.
- Nombre legal verificado en Play Console.
- Correo público de soporte.
- URL pública definitiva de la política de privacidad.
- Endpoint del receptor de estadísticas anónimas.
- Clave privada de subida a Google Play. La configuración usa
  `android/key.properties` cuando existe y recurre a la clave de pruebas solo
  para compilaciones locales.

## Configuración de la compilación

```text
--dart-define=POLEWISE_DEVELOPER_NAME=<nombre o marca>
--dart-define=POLEWISE_SUPPORT_EMAIL=<correo>
--dart-define=POLEWISE_PRIVACY_URL=<url https pública>
```

Copiar `android/key.properties.example` como `android/key.properties` y
completarlo con la clave de subida. Tanto el fichero como los almacenes `.jks`
están excluidos del repositorio.

## Ficha recomendada

**Nombre:** Polewise

**Descripción breve:**

Analiza pilotos, compara opciones y prepara tu equipo fantasy de carreras.

**Inicio de la descripción completa:**

Polewise es un asistente no oficial de análisis y estrategia para fantasy de
automovilismo. Consulta el calendario, estudia el rendimiento de pilotos y
constructores, prueba diferentes prioridades y prepara una alineación dentro
de tu presupuesto.

Polewise es una aplicación no oficial y no está asociada de ninguna manera con
las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD
CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de
Formula One Licensing B.V.

## Seguridad de los datos

La declaración final debe revisarse contra el artefacto que se vaya a subir.
Con la implementación actual:

- La conexión a la cuenta fantasy es opcional.
- La sesión, el identificador, el equipo y las ligas se almacenan cifrados en
  el dispositivo y se pueden borrar desde Ajustes.
- No existe formulario propio de correo y contraseña.
- Las estadísticas de uso requieren consentimiento. No se envían datos de
  cuenta fantasy ni contenido del usuario; Firebase puede procesar un
  identificador de instalación, datos técnicos y una región aproximada.
- La recopilación del identificador publicitario y la personalización de
  anuncios están desactivadas en el manifiesto.
- El receptor de estadísticas recibe la versión, el día, un identificador que
  cambia diariamente y contadores de eventos permitidos.
- Deben declararse también los flujos de datos de Jolpica-F1, OpenF1, el
  navegador integrado y Google Analytics for Firebase.

## Pruebas obligatorias antes del envío

- Confirmar que rechazar las estadísticas no produce ninguna petición.
- Confirmar que desactivarlas elimina la cola local.
- Confirmar que “Borrar sesión y datos locales” elimina token, snapshot,
  equipo y ligas importadas.
- Revisar el icono normal, redondo, adaptativo y temático.
- Probar el acceso web en un teléfono real.
- Publicar la política de privacidad y comprobar que abre sin autenticación.
- Sustituir la firma de debug por una clave de lanzamiento protegida.
