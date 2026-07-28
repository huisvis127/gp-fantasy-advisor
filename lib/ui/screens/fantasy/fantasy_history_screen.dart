import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/localization.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';

class FantasyHistoryScreen extends ConsumerWidget {
  const FantasyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final simulation = ref.watch(fantasySeasonSimulationProvider);
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);

    return simulation.when(
      loading: () => const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime)),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(14),
        child: StatusBanner(
          message: context.tr('Error: {error}', values: {'error': error}),
          isError: true,
          onRetry: () => ref.invalidate(fantasySeasonSimulationProvider),
        ),
      ),
      data: (simulation) {
        if (simulation.rounds.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: StatusBanner(
                message:
                    'Aún no hay resultados completos en la caché. Sincroniza en Resumen para reconstruir la temporada.'),
          );
        }
        final team = simulation.currentTeam!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            RefCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(
                        kicker: 'Desde el inicio de la liga',
                        title: 'Fantasy de la app'),
                    const SizedBox(height: 7),
                    Text(
                        context.tr('La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.'),
                        style:
                            AppText.body(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    Center(
                        child: TotalPill(
                            value: simulation.totalPoints.toStringAsFixed(0),
                        label: context.tr('pts sin chips'))),
                  ]),
            ),
            const SizedBox(height: 12),
            RefCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Alineación simulada actual'),
                    const SizedBox(height: 12),
                    Text(context.tr('PILOTOS'),
                        style:
                            AppText.mono(10, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 96,
                      children: [
                        for (final id in team.driverIds)
                          AssetCard(
                            tag:
                                '${catalog[id]?.priceMillions.toStringAsFixed(1) ?? '--'} M\$${id == team.boostedDriverId ? ' · X2' : ''}',
                            name: nameOf(id),
                            subtitle: catalog[id]?.teamName ?? '',
                            barColor: teamColor(catalog[id]
                                ?.teamName
                                .toLowerCase()
                                .replaceAll(' ', '_')),
                            tagColor: id == team.boostedDriverId
                                ? AppColors.cyan
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('CONSTRUCTORES'),
                        style:
                            AppText.mono(10, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      for (var i = 0; i < team.constructorIds.length; i++) ...[
                        Expanded(
                          child: AssetCard(
                            tag:
                                '${catalog[team.constructorIds[i]]?.priceMillions.toStringAsFixed(1) ?? '--'} M\$',
                            name: nameOf(team.constructorIds[i]),
                            subtitle: context.tr('Constructor'),
                            barColor: teamColor(team.constructorIds[i]),
                            tagColor: AppColors.orange,
                          ),
                        ),
                        if (i < team.constructorIds.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ]),
                  ]),
            ),
            const SizedBox(height: 14),
            Text(context.tr('CARRERA A CARRERA'),
                style: AppText.mono(10, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            for (final round in simulation.rounds.reversed)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border1)),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: Text('R${round.race.round} · ${round.race.raceName}',
                      style: AppText.body(12, weight: FontWeight.w700)),
                  subtitle: Text(
                      round.transfersIn.isEmpty
                          ? 'Equipo conservado'
                          : '${round.transfersIn.length} cambio${round.transfersIn.length == 1 ? '' : 's'} gratuito${round.transfersIn.length == 1 ? '' : 's'}',
                      style: AppText.body(10.5, color: AppColors.textTertiary)),
                  trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '${round.points >= 0 ? '+' : ''}${round.points.toStringAsFixed(0)} pts',
                            style: AppText.body(12,
                                color: AppColors.lime,
                                weight: FontWeight.w800)),
                        Text(
                            '${round.cumulativePoints.toStringAsFixed(0)} total',
                            style: AppText.mono(7)),
                      ]),
                  children: [
                    TransferNote(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tope ${round.budgetMillions.toStringAsFixed(1)} M\$'
                              ' · equipo ${round.teamValueMillions.toStringAsFixed(1)} M\$'
                              ' · libre ${round.cashMillions.toStringAsFixed(1)} M\$',
                              style: AppText.body(10.5),
                            ),
                          ),
                          if (round.budgetChangeMillions.abs() >= .05)
                            Text(
                              '${round.budgetChangeMillions >= 0 ? '+' : ''}'
                              '${round.budgetChangeMillions.toStringAsFixed(1)} M\$',
                              style: AppText.mono(
                                8,
                                color: round.budgetChangeMillions >= 0
                                    ? AppColors.lime
                                    : AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(context.tr('PILOTOS ELEGIDOS'), style: AppText.mono(8)),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final id in round.team.driverIds)
                            _HistoryAssetPill(
                              name: nameOf(id),
                              changed: round.transfersIn.contains(id),
                              boosted: round.team.boostedDriverId == id,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(context.tr('CONSTRUCTORES ELEGIDOS'),
                          style: AppText.mono(8)),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final id in round.team.constructorIds)
                            _HistoryAssetPill(
                              name: nameOf(id),
                              changed: round.transfersIn.contains(id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!round.hasOfficialPrices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Algún precio de esta ronda no estaba en caché; se usó el mejor dato disponible.',
                            style: AppText.body(
                              9.5,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    if (round.transfersIn.isEmpty)
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'El modelo no encontró un cambio gratuito que mejorase el equipo.',
                              style: AppText.body(10.5,
                                  color: AppColors.textTertiary)))
                    else
                      for (var i = 0; i < round.transfersIn.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                              '${nameOf(round.transfersOut[i])}  →  ${nameOf(round.transfersIn[i])}',
                              style: AppText.body(
                                11,
                                color: AppColors.cyan,
                                weight: FontWeight.w700,
                              )),
                        ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryAssetPill extends StatelessWidget {
  const _HistoryAssetPill({
    required this.name,
    this.changed = false,
    this.boosted = false,
  });

  final String name;
  final bool changed;
  final bool boosted;

  @override
  Widget build(BuildContext context) {
    final color = changed ? AppColors.lime : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: changed ? .12 : .06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: changed ? .9 : .35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: changed
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: .5), blurRadius: 6)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: AppText.body(
              10,
              color: changed ? AppColors.textPrimary : AppColors.textSecondary,
              weight: changed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (boosted) ...[
            const SizedBox(width: 5),
            Text(
              'X2',
              style: AppText.mono(8, color: AppColors.cyan),
            ),
          ],
        ],
      ),
    );
  }
}
