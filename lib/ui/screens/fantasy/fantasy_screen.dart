import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_locale.dart';
import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';
import '../ideal/ideal_screen.dart';
import '../my_team/my_team_screen.dart';
import '../market/market_screen.dart';
import '../strategy/strategy_screen.dart';
import '../live/live_screen.dart';

/// Reúne las dos herramientas de juego en la pestaña Fantasy, igual que la
/// aplicación de referencia: propuesta óptima y equipo real del usuario.
class FantasyScreen extends ConsumerStatefulWidget {
  const FantasyScreen({super.key});

  @override
  ConsumerState<FantasyScreen> createState() => _FantasyScreenState();
}

class _FantasyScreenState extends ConsumerState<FantasyScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final strings = AppStrings(ref.watch(appLocaleProvider));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: strings.t('strategy'),
                title: strings.t('your_game'),
              ),
              const SizedBox(height: 5),
              Text(
                strings.t('your_game_sub'),
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: [
                  strings.t('ideal'),
                  strings.t('team'),
                  strings.t('market'),
                  strings.t('plan'),
                  strings.t('live'),
                ],
                selectedIndex: _tab,
                onSelected: (value) => setState(() => _tab = value),
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
              MarketScreen(),
              StrategyScreen(),
              LiveScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
