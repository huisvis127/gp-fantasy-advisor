import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/localization.dart';
import '../../../core/theme.dart';
import '../../../core/usage_analytics.dart';
import '../../widgets/ref_widgets.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(usageAnalyticsProvider.notifier).track('screen_about'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Acerca de Polewise'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppMeta.appName,
                  style: AppText.syne(28, color: AppColors.lime),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(
                      'Asistente de análisis y estrategia para fantasy de automovilismo.'),
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'Versión', value: AppMeta.appVersion),
                _InfoRow(
                  label: 'Desarrollo',
                  value: AppMeta.developerName,
                ),
                if (AppMeta.supportEmail.isNotEmpty)
                  _InfoRow(
                    label: 'Soporte',
                    value: AppMeta.supportEmail,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHead(
                    kicker: 'Transparencia', title: 'Aplicación no oficial'),
                SizedBox(height: 9),
                SelectableText(
                  context.tr(AppMeta.disclaimer),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHead(kicker: 'Datos', title: 'Fuentes utilizadas'),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Las predicciones son estimaciones estadísticas y no garantizan resultados.'),
                  style: AppText.body(12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(usageAnalyticsProvider.notifier).track('screen_privacy'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Privacidad'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _PrivacySection(
            title: 'Responsable',
            body: AppMeta.supportEmail.isEmpty
                ? '${AppMeta.developerName}. El correo de soporte se muestra '
                    'en la ficha de Google Play.'
                : '${AppMeta.developerName} · ${AppMeta.supportEmail}',
          ),
          const _PrivacySection(
            title: 'Datos de la cuenta de fantasy',
            body: 'El acceso es opcional y se realiza en la web oficial dentro '
                'de un navegador integrado. Polewise puede copiar el token de '
                'sesión, el identificador de usuario, el equipo y las ligas '
                'para mostrarlos en la app. Esta información se cifra y se '
                'guarda únicamente en el dispositivo. Polewise no almacena la '
                'contraseña.',
          ),
          const _PrivacySection(
            title: 'Estadísticas de uso opcionales',
            body: 'Solo se activan con permiso. Polewise envía recuentos '
                'agrupados a su servicio y eventos generales a Google '
                'Analytics. Google puede procesar un identificador de '
                'instalación, datos técnicos del dispositivo y una región '
                'aproximada. No enviamos correo, cuenta, sesión, equipo, liga '
                'ni contenido. La recopilación del identificador publicitario '
                'y la personalización de anuncios están desactivadas.',
          ),
          const _PrivacySection(
            title: 'Servicios externos',
            body: 'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de '
                'fantasy para obtener datos deportivos. Esos servicios pueden '
                'recibir la dirección IP y los datos técnicos imprescindibles '
                'para responder a la conexión, conforme a sus propias '
                'políticas.',
          ),
          const _PrivacySection(
            title: 'Control y eliminación',
            body: 'Puedes desactivar las estadísticas en cualquier momento '
                'para detener recopilaciones futuras y borrar la cola local '
                'pendiente. Los datos ya procesados por Google se conservan '
                'según su política. También puedes eliminar desde Ajustes la '
                'sesión, el equipo y las ligas guardadas localmente. Esta '
                'acción no elimina la cuenta del servicio oficial.',
          ),
          const _PrivacySection(
            title: 'Seguridad y menores',
            body:
                'Los secretos de sesión se guardan mediante el almacenamiento '
                'seguro del sistema. Polewise no está dirigida específicamente '
                'a menores y no solicita edad, ubicación ni datos de pago.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              context.tr(label).toUpperCase(),
              style: AppText.mono(9, color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body(12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RefCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(title), style: AppText.syne(16)),
            const SizedBox(height: 7),
            SelectableText(
              context.tr(body),
              style: AppText.body(12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
