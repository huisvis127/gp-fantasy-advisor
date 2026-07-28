import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/localization.dart';
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
  bool _useMyTeamBudget = false;

  @override
  Widget build(BuildContext context) {
    final myBudget = ref.watch(myTeamPurchasingPowerProvider).valueOrNull;
    final budget = _useMyTeamBudget && myBudget != null ? myBudget : 100.0;
    final request = (priority: _priority, budgetMillions: budget);
    final comboAsync = ref.watch(optimalTeamProvider(request));
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final driverPredictions =
        ref.watch(driverPredictionsProvider).valueOrNull ?? const [];
    final constructorPredictions =
        ref.watch(engineConstructorPredictionsProvider).valueOrNull ?? const [];
    final prices = {
      for (final prediction in [
        ...driverPredictions,
        ...constructorPredictions
      ])
        prediction.assetId: prediction.priceMillions,
    };
    final race = ref.watch(selectedRaceProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: 'Presupuesto ${budget.toStringAsFixed(1)} M\$',
                title: race == null
                    ? 'Equipo ideal'
                    : 'Equipo ideal · ${race.raceName}',
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                    '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.'),
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['100 M\$', 'Mi equipo'],
                selectedIndex: _useMyTeamBudget ? 1 : 0,
                onSelected: (i) {
                  if (i == 1 && myBudget == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            'Introduce y guarda un equipo completo para usar su presupuesto.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _useMyTeamBudget = i == 1);
                },
              ),
              if (_useMyTeamBudget && myBudget != null) ...[
                const SizedBox(height: 7),
                Text(
                  context.tr(
                    'Valor del equipo más dinero libre: {budget} M\$',
                    values: {'budget': myBudget.toStringAsFixed(1)},
                  ),
                  style: AppText.body(10.5, color: AppColors.textTertiary),
                ),
              ],
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['Pilotos', 'Equilibrado', 'Constructores'],
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
              return const StatusBanner(
                message:
                    'No hay datos suficientes para optimizar. Sincroniza en Resumen.',
              );
            }
            return _result(context, combo, catalog, prices, budget);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.lime),
            ),
          ),
          error: (e, _) => StatusBanner(
            message: context.tr('Error: {error}', values: {'error': e}),
            isError: true,
            onRetry: () => ref.invalidate(optimalTeamProvider(request)),
          ),
        ),
      ],
    );
  }

  Widget _result(
    BuildContext context,
    TeamCombo combo,
    Map<String, FantasyAssetInfo> catalog,
    Map<String, double> prices,
    double budget,
  ) {
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);
    String teamOf(String id) => catalog[id]?.teamName ?? '';
    double priceOf(String id) => prices[id] ?? catalog[id]?.priceMillions ?? 0;
    Color colorOfDriver(String id) {
      final info = catalog[id];
      return teamColor(info?.teamName.toLowerCase().replaceAll(' ', '_'));
    }

    final remaining = budget - combo.totalCostMillions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: TotalPill(
            value: combo.totalExpectedPoints.toStringAsFixed(1),
            label: context.tr('pts esperados'),
          ),
        ),
        const SizedBox(height: 14),
        Text(context.tr('PILOTOS'),
            style: AppText.mono(10, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 96,
          children: [
            for (final id in combo.driverIds)
              AssetCard(
                tag:
                    '${priceOf(id).toStringAsFixed(1)} M\$${id == combo.boostedDriverId ? ' · X2' : ''}',
                name: nameOf(id),
                subtitle: teamOf(id),
                barColor: colorOfDriver(id),
                tagColor: id == combo.boostedDriverId ? AppColors.cyan : null,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(context.tr('CONSTRUCTORES'),
            style: AppText.mono(10, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final id in combo.constructorIds) ...[
              Expanded(
                child: AssetCard(
                  tag: '${priceOf(id).toStringAsFixed(1)} M\$',
                  name: nameOf(id),
                  subtitle: context.tr('Constructor'),
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
                TextSpan(text: context.tr('Coste total ')),
                TextSpan(
                  text: '${combo.totalCostMillions.toStringAsFixed(1)} M\$',
                  style: AppText.body(12,
                      color: AppColors.lime, weight: FontWeight.w800),
                ),
                TextSpan(
                  text: context.tr(' · te sobran {remaining} M\$.', values: {
                    'remaining': remaining.toStringAsFixed(1),
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
