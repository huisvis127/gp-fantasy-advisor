import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
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
          message: 'No se pudo reconstruir la temporada: $error',
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
                        'La estrategia conserva el equipo o usa hasta dos cambios gratuitos si mejoran la proyección. No usa chips.',
                        style:
                            AppText.body(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    Center(
                        child: TotalPill(
                            value: simulation.totalPoints.toStringAsFixed(0),
                            label: 'pts sin chips')),
                  ]),
            ),
            const SizedBox(height: 12),
            RefCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Alineación simulada actual'),
                    const SizedBox(height: 12),
                    Text('PILOTOS',
                        style:
                            AppText.mono(10, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.1,
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
                    Text('CONSTRUCTORES',
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
                            subtitle: 'Constructor',
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
            Text('CARRERA A CARRERA',
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'X2 · ${nameOf(round.team.boostedDriverId ?? '')}',
                        style: AppText.body(10.5,
                            color: AppColors.cyan, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                              style: AppText.body(11)),
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
