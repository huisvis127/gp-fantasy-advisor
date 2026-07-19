import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
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
  bool _showSimulation = true;

  @override
  Widget build(BuildContext context) {
    final comboAsync = ref.watch(optimalTeamProvider(_priority));
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final race = ref.watch(selectedRaceProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHead(
                kicker: 'Temporada 2026',
                title: 'Fantasy de la app',
              ),
              const SizedBox(height: 7),
              Text(
                'El equipo que habría gestionado el asesor desde el inicio, sin usar chips.',
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['Historial', 'Próximo GP'],
                selectedIndex: _showSimulation ? 0 : 1,
                onSelected: (index) =>
                    setState(() => _showSimulation = index == 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_showSimulation)
          _simulation(catalog)
        else ...[
          RefCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  kicker: 'Presupuesto 100 M\$',
                  title: race == null
                      ? 'Equipo ideal'
                      : 'Equipo ideal · ${race.raceName}',
                ),
                const SizedBox(height: 6),
                Text(
                  '5 pilotos + 2 constructores maximizando los puntos esperados '
                  'con tus pesos. Se recalcula al cambiar GP o sliders.',
                  style: AppText.body(11.5, color: AppColors.textTertiary),
                ),
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
                      'No hay datos suficientes para optimizar. Sincroniza en Pulso.',
                );
              }
              return _result(combo, catalog);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lime,
                ),
              ),
            ),
            error: (e, _) => StatusBanner(
              message: 'Error optimizando: $e',
              isError: true,
              onRetry: () => ref.invalidate(optimalTeamProvider(_priority)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _simulation(Map<String, FantasyAssetInfo> catalog) {
    final simulation = ref.watch(fantasySeasonSimulationProvider);
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);
    return simulation.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
              SizedBox(height: 12),
              Text('Simulando la temporada carrera a carrera…'),
            ],
          ),
        ),
      ),
      error: (error, _) => StatusBanner(
        message: 'No se pudo reconstruir la temporada: $error',
        isError: true,
        onRetry: () => ref.invalidate(fantasySeasonSimulationProvider),
      ),
      data: (simulation) {
        if (simulation.rounds.isEmpty) {
          return const StatusBanner(
            message:
                'Aún no hay resultados completos en la caché. Sincroniza en Pulso para reconstruir la temporada.',
          );
        }
        final team = simulation.currentTeam!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TotalPill(
                value: simulation.totalPoints.toStringAsFixed(0),
                label: 'pts sin chips',
              ),
            ),
            const SizedBox(height: 14),
            RefCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHead(
                    kicker: 'Alineación actual simulada',
                    title: 'Equipo del asesor',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PILOTOS',
                    style: AppText.mono(9, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final id in team.driverIds)
                        _SimAsset(label: nameOf(id), color: AppColors.cyan),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CONSTRUCTORES',
                    style: AppText.mono(9, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final id in team.constructorIds)
                        _SimAsset(label: nameOf(id), color: AppColors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'CARRERA A CARRERA',
              style: AppText.mono(10, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final round in simulation.rounds.reversed)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border1),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: Text(
                    'R${round.race.round} · ${round.race.raceName}',
                    style: AppText.body(12, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    round.transfersIn.isEmpty
                        ? 'Equipo conservado'
                        : '${round.transfersIn.length} cambio${round.transfersIn.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${round.points.toStringAsFixed(0)} pts',
                        style: AppText.body(
                          12,
                          color: AppColors.lime,
                          weight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${round.cumulativePoints.toStringAsFixed(0)} total',
                        style: AppText.mono(7),
                      ),
                    ],
                  ),
                  children: [
                    if (round.transfersIn.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'El modelo no encontró un cambio gratuito que mejorase el equipo.',
                          style: AppText.body(
                            10.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < round.transfersIn.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: AppColors.lime,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${nameOf(round.transfersOut[i])}  →  ${nameOf(round.transfersIn[i])}',
                                  style: AppText.body(10.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            const TransferNote(
              child: Text(
                'Simulación sin chips y con un máximo de dos cambios gratuitos por carrera. Los puntos usan los resultados reales guardados en el dispositivo.',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _result(TeamCombo combo, Map<String, FantasyAssetInfo> catalog) {
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
            label: 'pts esperados',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'PILOTOS',
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
          'CONSTRUCTORES',
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
                  subtitle: 'Constructor',
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
                const TextSpan(text: 'Coste total '),
                TextSpan(
                  text: '${combo.totalCostMillions.toStringAsFixed(1)} M\$',
                  style: AppText.body(
                    12,
                    color: AppColors.lime,
                    weight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' · te sobran ${remaining.toStringAsFixed(1)} M\$.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SimAsset extends StatelessWidget {
  const _SimAsset({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(label, style: AppText.body(10.5, weight: FontWeight.w700)),
  );
}
