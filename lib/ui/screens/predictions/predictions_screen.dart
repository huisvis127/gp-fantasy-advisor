import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/localization.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/engine/model_weights.dart';
import '../../../domain/models/prediction.dart';
import '../../widgets/ref_widgets.dart';

/// Pantalla «Ranking» (tab-pilotos + tab-constructores de la referencia):
/// sliders de pesos que suman 100% y recalculan al instante, subpestañas
/// Pilotos/Constructores, y el ranking completo con E[puntos], precio,
/// puntos-por-millón y desglose "por qué" al tocar cada fila.
class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key});

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionWindowSelector extends StatelessWidget {
  const _PredictionWindowSelector({
    required this.active,
    required this.automatic,
    required this.fridayAvailable,
    required this.saturdayAvailable,
    required this.onSelected,
    required this.onAutomatic,
  });

  final PredictionDataWindow active;
  final bool automatic;
  final bool fridayAvailable;
  final bool saturdayAvailable;
  final ValueChanged<PredictionDataWindow> onSelected;
  final VoidCallback onAutomatic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            for (final window in PredictionDataWindow.values) ...[
              if (window != PredictionDataWindow.values.first)
                const SizedBox(width: 6),
              Expanded(
                child: _WindowButton(
                  label: window.shortLabel,
                  selected: active == window,
                  enabled: switch (window) {
                    PredictionDataWindow.preWeekend => true,
                    PredictionDataWindow.friday => fridayAvailable,
                    PredictionDataWindow.saturday => saturdayAvailable,
                  },
                  onTap: () => onSelected(window),
                ),
              ),
            ],
          ],
        ),
        if (!automatic)
          TextButton(
            onPressed: onAutomatic,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(top: 3),
            ),
          child: Text(context.tr('Usar última disponible automáticamente')),
          ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.lime : AppColors.textSecondary;
    return Opacity(
      opacity: enabled ? 1 : .35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.lime.withValues(alpha: .07)
                : AppColors.surface3,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: selected ? AppColors.lime : AppColors.border1,
            ),
          ),
          child: Text(
            context.tr(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(10.5, color: color, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  int _subTab = 0;
  String? _expandedId;
  bool _weightsOpen = false;

  @override
  Widget build(BuildContext context) {
    final weights = ref.watch(userWeightsProvider);
    final mode = ref.watch(weightsModeProvider);
    final driversAsync = ref.watch(driverPredictionsProvider);
    final constructorsAsync = ref.watch(engineConstructorPredictionsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final weekend = ref.watch(weekendDataProvider).valueOrNull;
    final requestedWindow = ref.watch(predictionDataWindowProvider);
    final activeWindow = weekend?.resolveWindow(requestedWindow) ??
        PredictionDataWindow.preWeekend;
    final effectiveModel = ref.watch(effectiveWeightsProvider).valueOrNull;
    final activeSessions =
        weekend?.sessionsFor(activeWindow) ?? const <String>{};
    final sessionWeights = effectiveModel?.sessionWeightsFor(
          isSprint: weekend?.isSprintWeekend ?? false,
          availableSessions: activeSessions,
        ) ??
        const <String, double>{};

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        // ===== ETAPA DEL FIN DE SEMANA =====
        Row(
          children: [
            TagChip(
              weekend?.labelFor(activeWindow) ?? 'PRE-FINDE',
              color: activeWindow == PredictionDataWindow.preWeekend
                  ? AppColors.textSecondary
                  : AppColors.cyan,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _windowDescription(activeWindow, weekend),
                style: AppText.body(10.5, color: AppColors.textTertiary),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => ref.invalidate(weekendDataProvider),
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PredictionWindowSelector(
          active: activeWindow,
          automatic: requestedWindow == null,
          fridayAvailable:
              weekend?.isWindowAvailable(PredictionDataWindow.friday) ?? false,
          saturdayAvailable:
              weekend?.isWindowAvailable(PredictionDataWindow.saturday) ??
                  false,
          onSelected: (window) =>
              ref.read(predictionDataWindowProvider.notifier).select(window),
          onAutomatic: () => ref
              .read(predictionDataWindowProvider.notifier)
              .useLatestAvailable(),
        ),
        const SizedBox(height: 7),
        Text(
          _mixDescription(
            activeWindow,
            activeSessions,
            sessionWeights,
            effectiveModel,
          ),
          style: AppText.body(10, color: AppColors.textTertiary),
        ),
        if (weekend?.error != null) ...[
          StatusBanner(
              message: weekend!.error!,
              isError: true,
              onRetry: () => ref.invalidate(weekendDataProvider)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        // ===== PESOS DEL MODELO (sliders, como la referencia) =====
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _weightsOpen = !_weightsOpen),
                child: Row(
                  children: [
                    const Expanded(
                      child: SectionHead(
                        kicker: 'Modelo',
                        title: 'Pesos de la predicción',
                      ),
                    ),
                    Icon(
                      _weightsOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              if (_weightsOpen) ...[
                const SizedBox(height: 10),
                SubTabs(
                  labels: const ['Aficionado', 'Profi'],
                  selectedIndex: mode == WeightsMode.aficionado ? 0 : 1,
                  onSelected: (i) => ref
                      .read(weightsModeProvider.notifier)
                      .set(i == 0 ? WeightsMode.aficionado : WeightsMode.profi),
                ),
                const SizedBox(height: 8),
                Text(
                  mode == WeightsMode.aficionado
                      ? 'Los 4 pesos que importan. Al subir uno bajan los otros tres; '
                          'los avanzados (forma, circuito, equipo, abandonos) quedan '
                          'preconfigurados con los valores calibrados '
                          '(${kAdvancedWeightKeys.fold<double>(0, (s, k) => s + (weights[k] ?? 0)).round()}% del total).'
                      : 'Los 8 pesos del modelo. Suman 100%: al subir uno bajan los '
                          'demás. Todo se recalcula al instante.',
                  style: AppText.body(11.5, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 10),
                if (mode == WeightsMode.aficionado)
                  for (final key in kMainWeightKeys)
                    SliderBox(
                      label: kWeightLabels[key] ?? key,
                      value: weights[key] ?? 0,
                      onChanged: (v) => ref
                          .read(userWeightsProvider.notifier)
                          .setWeight(key, v, rebalanceWithin: kMainWeightKeys),
                    )
                else ...[
                  for (final key in kMainWeightKeys)
                    SliderBox(
                      label: kWeightLabels[key] ?? key,
                      value: weights[key] ?? 0,
                      onChanged: (v) => ref
                          .read(userWeightsProvider.notifier)
                          .setWeight(key, v),
                    ),
                  for (final key in kAdvancedWeightKeys)
                    SliderBox(
                      label: kWeightLabels[key] ?? key,
                      value: weights[key] ?? 0,
                      accent: key == 'riesgo_dnf'
                          ? AppColors.warning
                          : AppColors.cyan,
                      onChanged: (v) => ref
                          .read(userWeightsProvider.notifier)
                          .setWeight(key, v),
                    ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(userWeightsProvider.notifier).reset(),
                    child: Text(context.tr('Restaurar calibrados')),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ===== SUBPESTAÑAS =====
        SubTabs(
          labels: const ['Pilotos', 'Constructores'],
          selectedIndex: _subTab,
          onSelected: (i) => setState(() {
            _subTab = i;
            _expandedId = null;
          }),
        ),
        const SizedBox(height: 12),

        // ===== RANKING =====
        if (_subTab == 0)
          _buildBoard(driversAsync, catalog, isConstructor: false)
        else
          _buildBoard(constructorsAsync, catalog, isConstructor: true),
      ],
    );
  }

  String _windowDescription(
    PredictionDataWindow window,
    WeekendData? weekend,
  ) {
    return switch (window) {
      PredictionDataWindow.preWeekend =>
        'Base previa al GP: histórico, forma, circuito y riesgo. Sin datos del fin de semana.',
      PredictionDataWindow.friday when weekend?.isSprintWeekend == true =>
        'Versión para Sprint: usa únicamente FP1, antes de Sprint Qualifying.',
      PredictionDataWindow.friday
          when weekend?.sessions.contains('fp2') != true =>
        'Versión provisional del viernes con FP1. Se completará automáticamente tras FP2.',
      PredictionDataWindow.friday =>
        'Versión del viernes con FP1 y FP2 disponibles. Lista para decidir con margen.',
      PredictionDataWindow.saturday =>
        'Versión final pre-cierre: viernes más FP3, siempre antes de Qualifying.',
    };
  }

  String _mixDescription(
    PredictionDataWindow window,
    Set<String> sessions,
    Map<String, double> sessionWeights,
    ModelWeights? model,
  ) {
    if (window == PredictionDataWindow.preWeekend ||
        sessionWeights.isEmpty ||
        model == null) {
      return 'Nunca se usan Qualifying ni Sprint Qualifying del GP actual. '
          '“Ritmo a una vuelta” significa únicamente histórico anterior. '
          'Los puntos esperados suman clasificación + carrera + Sprint, si la hay.';
    }
    const order = ['fp1', 'fp2', 'fp3'];
    final sessionText = order
        .where(sessionWeights.containsKey)
        .map(
          (key) =>
              '${key.toUpperCase()} ${(sessionWeights[key]! * 100).round()}%',
        )
        .join(' · ');
    final oneLapBlend = (model.practiceBlendFor(
              kind: 'one_lap',
              availableSessions: sessions,
            ) *
            100)
        .round();
    final paceBlend = (model.practiceBlendFor(
              kind: 'pace',
              availableSessions: sessions,
            ) *
            100)
        .round();
    return 'Sesiones: $sessionText. Dentro de cada faceta, los libres pesan '
        '$oneLapBlend% en vuelta rápida y $paceBlend% en ritmo. Los puntos '
        'esperados suman clasificación + carrera + Sprint, si la hay.';
  }

  Widget _buildBoard(
    AsyncValue<List<AssetPrediction>> async,
    Map<String, FantasyAssetInfo> catalog, {
    required bool isConstructor,
  }) {
    return async.when(
      data: (preds) {
        if (preds.isEmpty) {
          return StatusBanner(
            message: context.tr('Sin datos todavía. Sincroniza desde la pestaña Resumen.'),
          );
        }
        final sorted = [...preds]
          ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
        final maxScore = sorted.first.expectedPoints;
        final bestValueId = ([...preds]
              ..sort((a, b) => b.pointsPerValue.compareTo(a.pointsPerValue)))
            .first
            .assetId;

        return Column(
          children: [
            for (var i = 0; i < sorted.length; i++) ...[
              _row(sorted[i], i + 1, maxScore, bestValueId, catalog,
                  isConstructor: isConstructor),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('La cifra grande son los puntos Fantasy esperados del fin de semana. '
                'Toca una fila para ver clasificación, carrera y Sprint. '
                'pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).'),
                style: AppText.body(10.5, color: AppColors.textTertiary),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
        ),
      ),
      error: (e, _) => StatusBanner(
        message: context.tr('Error: {error}', values: {'error': e}),
        isError: true,
        onRetry: () {
          ref.invalidate(driverPredictionsProvider);
          ref.invalidate(engineConstructorPredictionsProvider);
        },
      ),
    );
  }

  Widget _row(
    AssetPrediction pred,
    int rank,
    double maxScore,
    String bestValueId,
    Map<String, FantasyAssetInfo> catalog, {
    required bool isConstructor,
  }) {
    final info = catalog[pred.assetId];
    final name = info?.name ?? prettifyId(pred.assetId);
    final team = isConstructor
        ? '${pred.priceMillions.toStringAsFixed(1)} M\$'
        : (info?.teamName ?? '');
    final color = isConstructor
        ? teamColor(pred.assetId)
        : teamColor(info?.teamName.toLowerCase().replaceAll(' ', '_'));

    final chips = <TagChip>[
      if (rank == 1) TagChip(context.tr('Pick'), color: AppColors.lime),
      if (!isConstructor && pred.winProbability >= 0.18)
        TagChip(context.tr('Capitán'), color: AppColors.cyan),
      if (pred.assetId == bestValueId)
        TagChip(context.tr('Valor'), color: AppColors.violet),
      if (!isConstructor && (pred.breakdown['riesgo_dnf'] ?? 0) > 25)
        TagChip(context.tr('Riesgo DNF'), color: AppColors.warning),
    ];

    final isExpanded = _expandedId == pred.assetId;

    return RankingRow(
      rank: rank,
      teamColor: color,
      name: name,
      teamName: team,
      score: pred.expectedPoints,
      maxScore: maxScore,
      priceMillions: pred.priceMillions,
      chips: chips,
      onTap: () =>
          setState(() => _expandedId = isExpanded ? null : pred.assetId),
      expanded: isExpanded
          ? _breakdown(pred, catalog, isConstructor: isConstructor)
          : null,
    );
  }

  Widget _breakdown(
    AssetPrediction pred,
    Map<String, FantasyAssetInfo> catalog, {
    required bool isConstructor,
  }) {
    if (isConstructor) {
      // Para constructores el desglose son los E[puntos] de sus 2 pilotos.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16),
          Text(context.tr('POR QUÉ'), style: AppText.mono(9)),
          const SizedBox(height: 6),
          for (final entry in pred.breakdown.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(catalog[entry.key]?.name ?? prettifyId(entry.key),
                      style: AppText.body(12, color: AppColors.textSecondary)),
                  Text('${entry.value.toStringAsFixed(1)} pts',
                      style: AppText.body(12, weight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(context.tr('PUNTOS FANTASY ESPERADOS'), style: AppText.mono(9)),
        const SizedBox(height: 6),
        for (final entry in pred.pointBreakdown.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  switch (entry.key) {
                    'clasificacion' => context.tr('Clasificación'),
                    'carrera' => context.tr('Carrera'),
                    'sprint' => context.tr('Sprint'),
                    _ => prettifyId(entry.key),
                  },
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                Text(
                  '${entry.value.toStringAsFixed(1)} pts',
                  style: AppText.body(12, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'No incluye adelantamientos, posiciones ganadas, vuelta rápida ni '
          'Driver of the Day: su media reciente empeoró el backtest.',
          style: AppText.body(10.5, color: AppColors.textTertiary),
        ),
        const Divider(height: 16),
        Text(context.tr('POR QUÉ (0–100 POR FACETA)'), style: AppText.mono(9)),
        const SizedBox(height: 6),
        for (final key in kWeightKeys)
          if (pred.breakdown.containsKey(key))
            FeatureBarRow(
                label: kWeightLabels[key] ?? key, value: pred.breakdown[key]!),
        const SizedBox(height: 6),
        Row(
          children: [
            _probPill(context.tr('VICTORIA'), pred.winProbability),
            const SizedBox(width: 6),
            _probPill(context.tr('PODIO'), pred.podiumProbability),
            const SizedBox(width: 6),
            _probPill(context.tr('TOP 10'), pred.top10Probability),
          ],
        ),
      ],
    );
  }

  Widget _probPill(String label, double prob) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label ${(prob * 100).toStringAsFixed(0)}%',
        style: AppText.mono(8.5, color: AppColors.textSecondary),
      ),
    );
  }
}
