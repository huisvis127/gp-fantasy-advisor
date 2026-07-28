import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/league_selection_provider.dart';
import '../../../core/localization.dart';
import '../../../core/providers.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/race.dart';
import '../../../domain/models/prediction.dart';
import '../../../domain/services/league_snapshot_reader.dart';
import '../../widgets/ref_widgets.dart';
import 'countdown_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final requestedWindow = ref.watch(predictionDataWindowProvider);
    final activeWindow = weekend?.resolveWindow(requestedWindow) ??
        PredictionDataWindow.preWeekend;

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
                Text(context.tr('Resumen'), style: AppText.syne(34)),
                const SizedBox(height: 4),
                Text(
                  context.tr('Elige temporada y Gran Premio para analizar.'),
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: NeonSelect<int>(
                        label: context.tr('Temporada'),
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
                        label: context.tr('Gran Premio'),
                        value: raceAsync.valueOrNull,
                        items: racesAsync.valueOrNull ?? const <Race>[],
                        itemLabel: (r) => 'R${r.round} · ${r.raceName}',
                        onChanged: (r) => ref
                            .read(selectedRoundProvider.notifier)
                            .state = r.round,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                raceAsync.when(
                  data: (race) => race == null
                      ? Text(
                          context.tr('Sin calendario todavia. Desliza para sincronizar.'),
                          style:
                              AppText.body(12, color: AppColors.textTertiary),
                        )
                      : _RaceInfo(race: race),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    context.tr('No se pudo cargar el calendario guardado.'),
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
          const SizedBox(height: 12),
          const _LatestLeagueGpCard(),
          if (pricesEstimated) ...[
            const SizedBox(height: 8),
            const StatusBanner(
              message:
                  'Precios estimados a partir de la tabla del Mundial. Se actualizarán cuando responda F1 Fantasy.',
            ),
          ],
          const SizedBox(height: 16),
          SectionHead(
            kicker: 'Recomendacion',
            title: 'Picks del GP',
            trailing: TagChip(
              weekend?.labelFor(activeWindow) ?? 'PRE-FINDE',
              color: activeWindow == PredictionDataWindow.preWeekend
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
              final expensive = preds
                  .where((p) => p.priceMillions >= 15)
                  .toList()
                ..sort((a, b) => a.pointsPerValue.compareTo(b.pointsPerValue));

              final used = <String>{};
              AssetPrediction distinct(List<AssetPrediction> ordered) {
                final available = ordered.where(
                  (prediction) => !used.contains(prediction.assetId),
                );
                final selected =
                    available.isEmpty ? ordered.first : available.first;
                used.add(selected.assetId);
                return selected;
              }

              final pick = distinct(byPoints);
              final captain = distinct(byWin);
              final value = distinct(byValue);
              final avoid = distinct(
                expensive.isEmpty ? byPoints.reversed.toList() : expensive,
              );
              final topConstructor = constructorsAsync.valueOrNull?.firstOrNull;

              return Column(
                children: [
                  RecCard(
                    tag: 'Pick principal',
                    color: AppColors.lime,
                    name: nameOf(pick.assetId),
                    subtitle:
                        '${teamOf(pick.assetId)} · Mejor puntuacion esperada',
                    score: pick.expectedPoints.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 12),
                  RecCard(
                    tag: 'Capitan x2 alternativo',
                    color: AppColors.cyan,
                    name: nameOf(captain.assetId),
                    subtitle:
                        '${teamOf(captain.assetId)} · ${(captain.winProbability * 100).toStringAsFixed(0)}% victoria',
                    score: captain.expectedPoints.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 12),
                  RecCard(
                    tag: 'Mejor valor',
                    color: AppColors.violet,
                    name: nameOf(value.assetId),
                    subtitle:
                        '${teamOf(value.assetId)} · ${value.pointsPerValue.toStringAsFixed(2)} pts/M · ${value.priceMillions.toStringAsFixed(1)} M',
                    score: value.expectedPoints.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 12),
                  RecCard(
                    tag: 'Evitar por valor',
                    color: AppColors.error,
                    name: nameOf(avoid.assetId),
                    subtitle:
                        '${teamOf(avoid.assetId)} · ${avoid.pointsPerValue.toStringAsFixed(2)} pts/M · ${avoid.priceMillions.toStringAsFixed(1)} M',
                    score: avoid.expectedPoints.toStringAsFixed(1),
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.lime),
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

class _LatestLeagueGpCard extends ConsumerWidget {
  const _LatestLeagueGpCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLeagueId = ref.watch(selectedPrivateLeagueIdProvider);
    final auth = ref.watch(fantasyAuthServiceProvider);
    return FutureBuilder<String?>(
      future: auth.readSessionSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const RefCard(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final raw = snapshot.data;
        LeagueLatestGp? latest;
        if (raw != null && raw.isNotEmpty) {
          try {
            latest = LeagueSnapshotReader.latestGp(
              raw,
              selectedLeagueId: selectedLeagueId,
            );
          } catch (_) {
            latest = null;
          }
        }
        if (latest == null) {
          return StatusBanner(
            message: context.tr(
              'Actualiza una liga privada para ver aquí la clasificación del último GP.',
            ),
          );
        }
        final result = latest;
        return RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('ÚLTIMO GRAN PREMIO'), style: AppText.mono(9)),
                        const SizedBox(height: 4),
                        Text(result.leagueName, style: AppText.syne(18)),
                      ],
                    ),
                  ),
                  TagChip('R${result.round}', color: AppColors.cyan),
                ],
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < result.standings.length; index++) ...[
                if (index > 0) const Divider(height: 15),
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#${result.standings[index].rank}',
                        style: AppText.mono(9, color: AppColors.lime),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        result.standings[index].name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12.5, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatLeaguePoints(result.standings[index].points)} pts',
                      style: AppText.mono(9, color: AppColors.cyan),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

String _formatLeaguePoints(double points) => points == points.roundToDouble()
    ? points.round().toString()
    : points.toStringAsFixed(1);

class _RaceInfo extends StatelessWidget {
  const _RaceInfo({required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    final dateText =
        DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(race.date);
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
        Text(dateText,
            style: AppText.body(11.5, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        if (!isPast) CountdownWidget(targetDate: race.date),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (race.hasSprint)
              const TagChip('Fin de semana sprint', color: AppColors.orange),
            if (isPast)
              const TagChip('GP ya disputado · modo analisis',
                  color: AppColors.cyan),
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
