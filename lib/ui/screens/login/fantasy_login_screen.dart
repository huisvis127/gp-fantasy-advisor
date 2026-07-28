import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/localization.dart';
import '../../../core/usage_analytics.dart';
import '../../widgets/glass_card.dart';
import '../my_team/manual_team_entry_screen.dart';
import 'fantasy_login_webview_screen.dart';

class FantasyLoginScreen extends ConsumerStatefulWidget {
  const FantasyLoginScreen({super.key});

  @override
  ConsumerState<FantasyLoginScreen> createState() => _FantasyLoginScreenState();
}

class _FantasyLoginScreenState extends ConsumerState<FantasyLoginScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(usageAnalyticsProvider.notifier)
          .track('screen_fantasy_login'),
    );
  }

  Future<void> _openBrowser() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FantasyLoginWebViewScreen()),
    );
    if (result == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Cuenta F1 Fantasy'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Acceso seguro'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('Inicia sesión en la web oficial. Polewise no recibe ni '
                  'almacena tu contraseña; únicamente copia de forma cifrada '
                  'la sesión, tu equipo y tus ligas en este dispositivo.',
                ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(usageAnalyticsProvider.notifier)
                          .track('fantasy_login_opened');
                      await _openBrowser();
                    },
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: Text(context.tr('ABRIR WEB OFICIAL')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualTeamEntryScreen(),
                      ),
                    ),
                    child: Text(context.tr('Introducir equipo manualmente')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.'),
            style: AppText.body(11.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
