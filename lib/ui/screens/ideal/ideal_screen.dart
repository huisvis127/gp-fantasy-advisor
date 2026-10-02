import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/engine/team_optimizer.dart';
import '../../widgets/ref_widgets.dart';

/// Pantalla «Equipo ideal» (tab-bestteam de la referencia): el mejor equipo
/// de 5 pilotos + 2 constructores dentro de 100 M$, con toggle de prioridad
/// (pilotos / equilibrado / constructores) y total esperado en la píldora
/// grande (.future-total). Sin login ni liga: funciona solo con datos.
class IdealScreen extends ConsumerStatefulWidget {
  const IdealScreen({super.key});

  @override
  ConsumerState<IdealScreen> createState() => _IdealScreenState();
}

class _IdealScreenState extends ConsumerState<IdealScreen> {
  TeamPriority _priority = TeamPriority.balanced;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final comboAsync = ref.watch(optimalTeamProvider(_priority));
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final race = ref.watch(selectedRaceProvider).valueOrNull;
    final strings = AppStrings(ref.watch(appLocaleProvider));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: strings.t('budget_100'),
                title: race == null
                    ? strings.t('ideal_team')
                    : '${strings.t('ideal_team')} · ${race.raceName}',
              ),
              const SizedBox(height: 6),
              Text(
                strings.t('ideal_intro'),
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: [
                  strings.t('drivers'),
                  strings.t('balanced'),
                  strings.t('constructors'),
                ],
                selectedIndex: switch (_priority) {
                  TeamPriority.drivers => 0,
                  TeamPriority.balanced => 1,
                  TeamPriority.constructors => 2,
                },
                onSelected: (i) => setState(() {
                  _priority = switch (i) {
                    0 => TeamPriority.drivers,
                    2 => TeamPriority.constructors,
                    _ => TeamPriority.balanced,
                  };
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        comboAsync.when(
          data: (combo) {
            if (combo.driverIds.isEmpty) {
              return StatusBanner(message: strings.t('sync_to_optimize'));
            }
            return _result(combo, catalog, strings);
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lime,
              ),
            ),
          ),
          error: (e, _) => StatusBanner(
            message: '${strings.t('optimization_failed')}: $e',
            isError: true,
            onRetry: () => ref.invalidate(optimalTeamProvider(_priority)),
          ),
        ),
      ],
    );
  }

  Widget _result(
    TeamCombo combo,
    Map<String, FantasyAssetInfo> catalog,
    AppStrings strings,
  ) {
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);
    String teamOf(String id) => catalog[id]?.teamName ?? '';
    double priceOf(String id) => catalog[id]?.priceMillions ?? 0;
    Color colorOfDriver(String id) {
      final info = catalog[id];
      return teamColor(info?.teamName.toLowerCase().replaceAll(' ', '_'));
    }

    final remaining = 100.0 - combo.totalCostMillions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: TotalPill(
            value: combo.totalExpectedPoints.toStringAsFixed(1),
            label: strings.t('expected_points').toLowerCase(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.t('drivers'),
          style: AppText.mono(10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            for (final id in combo.driverIds)
              AssetCard(
                tag: '${priceOf(id).toStringAsFixed(1)} M\$',
                name: nameOf(id),
                subtitle: teamOf(id),
                barColor: colorOfDriver(id),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          strings.t('constructors'),
          style: AppText.mono(10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final id in combo.constructorIds) ...[
              Expanded(
                child: AssetCard(
                  tag: '${priceOf(id).toStringAsFixed(1)} M\$',
                  name: nameOf(id),
                  subtitle: strings.t('constructor'),
                  barColor: teamColor(id),
                  tagColor: AppColors.orange,
                ),
              ),
              if (id != combo.constructorIds.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 14),
        TransferNote(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${strings.t('total_cost')} '),
                TextSpan(
                  text: '${combo.totalCostMillions.toStringAsFixed(1)} M\$',
                  style: AppText.body(
                    12,
                    color: AppColors.lime,
                    weight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text:
                      ' · ${remaining.toStringAsFixed(1)} M\$ ${strings.t('remaining')}.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
