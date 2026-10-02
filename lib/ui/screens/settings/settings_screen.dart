import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/alert_settings.dart';
import '../../../core/theme.dart';
import '../../../core/app_appearance.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';

/// Pantalla «Ajustes»: sincronización manual con informe visible, pesos del
/// modelo, y el login de F1 Fantasy como algo TOTALMENTE OPCIONAL (solo para
/// importar tu equipo; toda la app funciona sin cuenta y sin liga).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final alerts = ref.watch(alertSettingsProvider);
    final languageCode = ref.watch(appLocaleProvider);
    final strings = AppStrings(languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          RefCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.light_mode_rounded, color: AppColors.lime),
              title: Text('Modo claro', style: AppText.syne(16)),
              subtitle: Text(
                'Fondos suaves y colores con buen contraste.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              value: ref.watch(appAppearanceProvider) == Brightness.light,
              onChanged: (enabled) => ref
                  .read(appAppearanceProvider.notifier)
                  .setLightMode(enabled),
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  kicker: strings.t('settings'),
                  title: strings.t('language'),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.t('language_sub'),
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final code in supportedLanguageCodes)
                      ChoiceChip(
                        label: Text(AppStrings.languageNames[code]!),
                        selected: languageCode == code,
                        onSelected: (_) => ref
                            .read(appLocaleProvider.notifier)
                            .setLanguage(code),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHead(kicker: 'Datos', title: 'Sincronización'),
                const SizedBox(height: 8),
                Text(
                  sync.lastSync == null
                      ? 'Todavía no se ha sincronizado en esta sesión.'
                      : 'Última sincronización: ${DateFormat('dd/MM HH:mm').format(sync.lastSync!)}.',
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                if (sync.report != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${sync.report!.racesSynced} carreras de calendario · '
                    '${sync.report!.resultsSynced} resultados nuevos · '
                    '${sync.report!.pricesSynced} precios.',
                    style: AppText.body(11.5, color: AppColors.textTertiary),
                  ),
                ],
                if (sync.report?.errors.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  StatusBanner(
                    message: sync.report!.errors.join('\n'),
                    isError: true,
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: sync.syncing
                      ? null
                      : () =>
                            ref.read(syncControllerProvider.notifier).syncNow(),
                  child: Text(
                    sync.syncing ? 'SINCRONIZANDO…' : 'SINCRONIZAR AHORA',
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
                const SectionHead(
                  kicker: 'Recordatorios',
                  title: 'Alertas de cierre',
                ),
                const SizedBox(height: 7),
                Text(
                  'Recibe avisos locales 24 horas y 1 hora antes del cierre '
                  'oficial. No requiere cuenta ni servidor.',
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Avisarme antes del cierre',
                    style: AppText.body(13, weight: FontWeight.w700),
                  ),
                  value: alerts.valueOrNull ?? false,
                  onChanged: alerts.isLoading
                      ? null
                      : (value) async {
                          final accepted = await ref
                              .read(alertSettingsProvider.notifier)
                              .setEnabled(value);
                          if (context.mounted && value && !accepted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Android no concedió permiso para avisos.',
                                ),
                              ),
                            );
                          }
                        },
                  activeThumbColor: AppColors.lime,
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
                  kicker: 'Modelo',
                  title: 'Pesos de predicción',
                ),
                const SizedBox(height: 8),
                Text(
                  'Los sliders están en la pestaña Análisis. Desde aquí puedes '
                  'volver a los valores calibrados del modelo.',
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(userWeightsProvider.notifier).reset(),
                  child: const Text('Restaurar pesos calibrados'),
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
                  kicker: 'Tu cuenta',
                  title: 'Cuenta F1 Fantasy',
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para importar tu equipo real y consultar tus ligas. '
                  'El análisis público y el editor manual siguen disponibles si el '
                  'servicio oficial no responde.',
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FantasyLoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Gestionar sesión'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHead(kicker: 'Legal', title: 'Aviso'),
                const SizedBox(height: 8),
                Text(
                  'App no oficial. No afiliada a Formula One Licensing B.V. '
                  'Datos de Jolpica-F1 y OpenF1. Las predicciones son estimaciones '
                  'estadísticas, no garantías. Tus datos no salen del dispositivo.',
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
