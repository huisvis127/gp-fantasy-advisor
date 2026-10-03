import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/race.dart';
import '../../widgets/ref_widgets.dart';
import 'countdown_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final seasons = ref.watch(availableSeasonsProvider);
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final racesAsync = ref.watch(seasonRacesProvider);
    final raceAsync = ref.watch(selectedRaceProvider);
    final predictionsAsync = ref.watch(driverPredictionsProvider);
    final constructorsAsync = ref.watch(engineConstructorPredictionsProvider);
    final catalogAsync = ref.watch(fantasyAssetNameProvider);
    final pricesEstimated =
        ref.watch(pricesAreEstimatedProvider).valueOrNull ?? true;

    final weekend = ref.watch(weekendDataProvider).valueOrNull;

    return RefreshIndicator(
      color: AppColors.lime,
      onRefresh: () async {
        ref.invalidate(weekendDataProvider);
        await ref.read(syncControllerProvider.notifier).syncNow();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('F1 Fantasy'),
                const SizedBox(height: 6),
                Text('Resumen', style: AppText.syne(34)),
                const SizedBox(height: 4),
                Text(
                  'Elige temporada y Gran Premio para analizar.',
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: NeonSelect<int>(
                        label: 'Temporada',
                        value: selectedSeason,
                        items: seasons,
                        itemLabel: (s) => '$s',
                        onChanged: (s) =>
                            ref.read(selectedSeasonProvider.notifier).state = s,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: NeonSelect<Race>(
                        label: 'Gran Premio',
                        value: raceAsync.valueOrNull,
                        items: racesAsync.valueOrNull ?? const <Race>[],
                        itemLabel: (r) => 'R${r.round} · ${r.raceName}',
                        onChanged: (r) =>
                            ref.read(selectedRoundProvider.notifier).state =
                                r.round,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                raceAsync.when(
                  data: (race) => race == null
                      ? Text(
                          'Sin calendario todavia. Desliza para sincronizar.',
                          style: AppText.body(
                            12,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : _RaceInfo(race: race),
                  loading: () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    'No se pudo cargar el calendario guardado.',
                    style: AppText.body(12, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SyncBanner(
            sync: sync,
            onRetry: () => ref.read(syncControllerProvider.notifier).syncNow(),
          ),
          if (pricesEstimated) ...[
            const SizedBox(height: 8),
            const StatusBanner(
              message:
                  'Precios estimados a partir de la clasificacion. Se actualizaran cuando responda F1 Fantasy.',
            ),
          ],
          const SizedBox(height: 16),
          SectionHead(
            kicker: 'Recomendacion',
            title: 'Picks del GP',
            trailing: TagChip(
              weekend?.stageLabel ?? 'PRE-FINDE',
              color: (weekend?.isEmpty ?? true)
                  ? AppColors.textSecondary
                  : AppColors.cyan,
            ),
          ),
          const SizedBox(height: 10),
          predictionsAsync.when(
            data: (preds) {
              if (preds.isEmpty) {
                return Text(
                  'Aun no hay datos suficientes para predecir.',
                  style: AppText.body(12, color: AppColors.textTertiary),
                );
              }
              final catalog = catalogAsync.valueOrNull ?? const {};
              String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);
              String teamOf(String id) => catalog[id]?.teamName ?? '';

              final byPoints = [...preds]
                ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
              final byWin = [...preds]
                ..sort((a, b) => b.winProbability.compareTo(a.winProbability));
              final byValue = [...preds]
                ..sort((a, b) => b.pointsPerValue.compareTo(a.pointsPerValue));
              final expensive =
                  preds.where((p) => p.priceMillions >= 15).toList()..sort(
                    (a, b) => a.pointsPerValue.compareTo(b.pointsPerValue),
                  );

              final pick = byPoints.first;
              final captain = byWin.first;
              final value = byValue.first;
              final avoid = expensive.isEmpty ? byPoints.last : expensive.first;
              final topConstructor = constructorsAsync.valueOrNull?.firstOrNull;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RecCard(
                          tag: 'Pick',
                          color: AppColors.lime,
                          name: nameOf(pick.assetId),
                          subtitle: teamOf(pick.assetId),
                          score: pick.expectedPoints.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RecCard(
                          tag: 'Capitan x2',
                          color: AppColors.cyan,
                          name: nameOf(captain.assetId),
                          subtitle:
                              '${(captain.winProbability * 100).toStringAsFixed(0)}% victoria',
                          score: captain.expectedPoints.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RecCard(
                          tag: 'Valor',
                          color: AppColors.violet,
                          name: nameOf(value.assetId),
                          subtitle:
                              '${value.pointsPerValue.toStringAsFixed(2)} pts/M · ${value.priceMillions.toStringAsFixed(1)} M',
                          score: value.expectedPoints.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RecCard(
                          tag: 'Evitar',
                          color: AppColors.error,
                          name: nameOf(avoid.assetId),
                          subtitle:
                              '${avoid.pointsPerValue.toStringAsFixed(2)} pts/M · ${avoid.priceMillions.toStringAsFixed(1)} M',
                          score: avoid.expectedPoints.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  if (topConstructor != null) ...[
                    const SizedBox(height: 12),
                    RecCard(
                      tag: 'Marca top',
                      color: AppColors.orange,
                      name: nameOf(topConstructor.assetId),
                      subtitle:
                          '${topConstructor.priceMillions.toStringAsFixed(1)} M · ${topConstructor.pointsPerValue.toStringAsFixed(2)} pts/M',
                      score: topConstructor.expectedPoints.toStringAsFixed(1),
                    ),
                  ],
                ],
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lime,
                ),
              ),
            ),
            error: (_, __) => StatusBanner(
              message: 'No se pudieron calcular las predicciones.',
              isError: true,
              onRetry: () => ref.invalidate(driverPredictionsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceInfo extends StatelessWidget {
  const _RaceInfo({required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final dateText = DateFormat(
      "EEEE d 'de' MMMM · HH:mm",
      'es',
    ).format(race.date);
    final isPast = race.date.isBefore(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(race.raceName, style: AppText.syne(19)),
        const SizedBox(height: 2),
        Text(
          '${race.circuitName} · ${race.country}',
          style: AppText.body(12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: AppText.body(11.5, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),
        if (!isPast) CountdownWidget(targetDate: race.date),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (race.hasSprint)
              TagChip('Fin de semana sprint', color: AppColors.orange),
            if (isPast)
              TagChip('GP ya disputado · modo analisis', color: AppColors.cyan),
          ],
        ),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.sync, required this.onRetry});

  final SyncState sync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (sync.syncing) {
      return const StatusBanner(
        message: 'Sincronizando calendario, resultados y precios...',
        isLoading: true,
      );
    }
    if (sync.fatalError != null) {
      return StatusBanner(
        message:
            'No se pudo actualizar ahora. Se muestran los datos guardados y estimaciones.',
        isError: true,
        onRetry: onRetry,
      );
    }
    final report = sync.report;
    if (report == null) {
      return StatusBanner(
        message:
            'Sin sincronizar todavia. Desliza hacia abajo para descargar datos.',
        onRetry: onRetry,
      );
    }
    if (report.errors.isNotEmpty) {
      return StatusBanner(
        message:
            'Datos disponibles. Algunas fuentes externas no respondieron y se usan estimaciones.',
        onRetry: onRetry,
      );
    }
    final when = sync.lastSync == null
        ? ''
        : ' (${DateFormat('HH:mm').format(sync.lastSync!)})';
    return StatusBanner(
      message:
          'Datos al dia$when: ${report.racesSynced} carreras de calendario, '
          '${report.resultsSynced} resultados nuevos.',
    );
  }
}
