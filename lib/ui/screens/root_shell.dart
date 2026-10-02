import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/app_locale.dart';
import '../../core/theme.dart';
import '../widgets/ref_widgets.dart';
import '../widgets/lazy_tab_stack.dart';
import 'home/home_screen.dart';
import 'circuit/circuit_screen.dart';
import 'fantasy/fantasy_screen.dart';
import 'league/league_screen.dart';
import 'predictions/predictions_screen.dart';
import 'settings/settings_screen.dart';

/// Armazón de la app replicando el shell de la referencia: cabecera fija
/// con marca lima + etiqueta mono, y barra inferior con pestañas mono
/// uppercase e indicador lima superior (`.app-header` / `.bottom-nav`).
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  static const _tabs = [
    ('summary', Icons.speed_rounded),
    ('analysis', Icons.query_stats_rounded),
    ('fantasy', Icons.auto_awesome_rounded),
    ('circuit', Icons.route_rounded),
    ('league', Icons.emoji_events_rounded),
  ];

  static const _screens = [
    HomeScreen(),
    PredictionsScreen(),
    FantasyScreen(),
    CircuitScreen(),
    LeagueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final selectedRace = ref.watch(selectedRaceProvider).valueOrNull;
    final strings = AppStrings(ref.watch(appLocaleProvider));

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // .app-header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border1)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GP Fantasy Advisor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.syne(18, color: AppColors.lime)
                              .copyWith(
                                shadows: [
                                  Shadow(
                                    color: AppColors.lime.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text('F1', style: AppText.mono(10)),
                      if (selectedRace != null &&
                          constraints.maxWidth >= 600) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            selectedRace.raceName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.mono(
                              9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: strings.t('settings'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        icon: Icon(
                          Icons.settings_rounded,
                          size: 19,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LazyTabStack(index: _index, children: _screens),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          border: Border(top: BorderSide(color: AppColors.border1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 2,
                            width: 26,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? AppColors.lime
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: i == _index
                                  ? [
                                      BoxShadow(
                                        color: AppColors.lime.withValues(
                                          alpha: 0.65,
                                        ),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          Icon(
                            _tabs[i].$2,
                            size: 20,
                            color: i == _index
                                ? AppColors.lime
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.t(_tabs[i].$1),
                            style: AppText.mono(
                              8,
                              color: i == _index
                                  ? AppColors.lime
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
