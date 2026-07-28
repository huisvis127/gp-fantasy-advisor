import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/localization.dart';
import '../../../core/usage_analytics.dart';
import '../../widgets/ref_widgets.dart';
import 'fantasy_history_screen.dart';
import '../ideal/ideal_screen.dart';
import '../my_team/my_team_screen.dart';

/// Reúne las dos herramientas de juego en la pestaña Fantasy, igual que la
/// aplicación de referencia: propuesta óptima y equipo real del usuario.
class FantasyScreen extends ConsumerStatefulWidget {
  const FantasyScreen({super.key});

  @override
  ConsumerState<FantasyScreen> createState() => _FantasyScreenState();
}

class _FantasyScreenState extends ConsumerState<FantasyScreen> {
  int _tab = 0;

  static const _tabEvents = [
    'screen_fantasy_ideal',
    'screen_fantasy_team',
    'screen_fantasy_history',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHead(
                kicker: 'Estrategia',
                title: 'Tu juego',
              ),
              const SizedBox(height: 5),
              Text(
                context.tr('Construye el equipo ideal o analiza el que ya tienes.'),
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['Equipo ideal', 'Mi equipo', 'Historial'],
                selectedIndex: _tab,
                onSelected: (value) {
                  if (_tab == value) return;
                  setState(() => _tab = value);
                  ref
                      .read(usageAnalyticsProvider.notifier)
                      .track(_tabEvents[value]);
                },
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [
              IdealScreen(),
              MyTeamScreen(),
              FantasyHistoryScreen()
            ],
          ),
        ),
      ],
    );
  }
}
