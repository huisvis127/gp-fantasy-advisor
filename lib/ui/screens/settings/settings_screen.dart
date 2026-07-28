import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/localization.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/usage_analytics.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';
import 'legal_screens.dart';

/// Pantalla «Ajustes»: sincronización manual con informe visible, pesos del
/// modelo, y el login de F1 Fantasy como algo TOTALMENTE OPCIONAL (solo para
/// importar tu equipo; toda la app funciona sin cuenta y sin liga).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final usageConsent = ref.watch(usageAnalyticsProvider);
    final usageEnabled = usageConsent.valueOrNull == UsageConsent.allowed;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ajustes'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  kicker: 'Idioma',
                  title: 'Idioma de la aplicación',
                ),
                const SizedBox(height: 8),
                Text(
                  context
                      .tr('Elige el idioma de todos los textos de Polewise.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.language_rounded),
                    label: Text(
                      ref.watch(appLanguageProvider).label,
                    ),
                    onPressed: () async {
                      final activeLanguage = ref.read(appLanguageProvider);
                      final selectedLanguage = await showDialog<AppLanguage>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title:
                              Text(dialogContext.tr('Idioma de la aplicación')),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final language in AppLanguage.values)
                                  RadioListTile<AppLanguage>(
                                    value: language,
                                    groupValue: activeLanguage,
                                    title: Text(language.label),
                                    onChanged: (value) =>
                                        Navigator.of(dialogContext).pop(value),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (selectedLanguage != null && context.mounted) {
                        await ref
                            .read(appLanguageProvider.notifier)
                            .setLanguage(selectedLanguage);
                      }
                    },
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
                const SectionHead(kicker: 'Datos', title: 'Sincronización'),
                const SizedBox(height: 8),
                Text(
                  sync.lastSync == null
                      ? context
                          .tr('Todavía no se ha sincronizado en esta sesión.')
                      : context.tr('Última sincronización: {date}.', values: {
                          'date': DateFormat(
                            'dd/MM HH:mm',
                            Localizations.localeOf(context).languageCode,
                          ).format(sync.lastSync!),
                        }),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                if (sync.report != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                        '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.',
                        values: {
                          'races': sync.report!.racesSynced,
                          'results': sync.report!.resultsSynced,
                          'prices': sync.report!.pricesSynced,
                        }),
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
                      : () async {
                          await ref
                              .read(usageAnalyticsProvider.notifier)
                              .track('sync_requested');
                          await ref
                              .read(syncControllerProvider.notifier)
                              .syncNow();
                        },
                  child: Text(context.tr(
                      sync.syncing ? 'SINCRONIZANDO…' : 'SINCRONIZAR AHORA')),
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
                    kicker: 'Modelo', title: 'Pesos de predicción'),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(usageAnalyticsProvider.notifier)
                        .track('model_weights_reset');
                    ref.read(userWeightsProvider.notifier).reset();
                  },
                  child: Text(context.tr('Restaurar pesos calibrados')),
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
                  context.tr(
                      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ref
                        .read(usageAnalyticsProvider.notifier)
                        .track('fantasy_login_opened');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          settings: const RouteSettings(name: '/fantasy-login'),
                          builder: (_) => const FantasyLoginScreen()),
                    );
                  },
                  child: Text(context.tr('Gestionar sesión')),
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
                  kicker: 'Privacidad',
                  title: 'Estadísticas de uso',
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Compartir estadísticas anónimas')),
                  subtitle: Text(
                    context.tr(usageEnabled ? 'Activadas' : 'Desactivadas'),
                    style: AppText.body(
                      11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  value: usageEnabled,
                  onChanged: usageConsent.isLoading
                      ? null
                      : (enabled) =>
                          ref.read(usageAnalyticsProvider.notifier).setConsent(
                                enabled
                                    ? UsageConsent.allowed
                                    : UsageConsent.denied,
                              ),
                ),
                if (usageEnabled)
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(usageAnalyticsProvider.notifier)
                          .clearPendingData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context
                                .tr('Estadísticas pendientes eliminadas.')),
                          ),
                        );
                      }
                    },
                    child: Text(context.tr('Borrar estadísticas pendientes')),
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
                  kicker: 'Tus datos',
                  title: 'Borrado local',
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(context.tr('¿Borrar datos locales?')),
                        content: Text(context.tr(
                          'Se cerrará la sesión y se eliminarán el equipo y las ligas guardadas en Polewise.',
                        )),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(context.tr('Cancelar')),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(context.tr('Borrar')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref.read(fantasyAuthServiceProvider).logout();
                    await ref.read(myTeamProvider.notifier).clear();
                    await ref
                        .read(usageAnalyticsProvider.notifier)
                        .track('local_data_deleted');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              context.tr('Sesión y datos locales eliminados.')),
                        ),
                      );
                    }
                  },
                  child: Text(context.tr('Borrar sesión y datos locales')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHead(kicker: 'Legal', title: 'Información'),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.'),
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/privacy'),
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                      child: Text(context.tr('Privacidad')),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/about'),
                          builder: (_) => const AboutScreen(),
                        ),
                      ),
                      child: Text(context.tr('Acerca de Polewise')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
