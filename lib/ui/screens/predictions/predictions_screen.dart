import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
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

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  int _subTab = 0;
  String? _expandedId;
  bool _weightsOpen = true;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final weights = ref.watch(userWeightsProvider);
    final mode = ref.watch(weightsModeProvider);
    final driversAsync = ref.watch(driverPredictionsProvider);
    final constructorsAsync = ref.watch(engineConstructorPredictionsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final weekend = ref.watch(weekendDataProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        // ===== ETAPA DEL FIN DE SEMANA =====
        Row(
          children: [
            TagChip(
              weekend?.stageLabel ?? 'PRE-FINDE',
              color: (weekend?.isEmpty ?? true)
                  ? AppColors.textSecondary
                  : AppColors.cyan,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (weekend == null || weekend.isEmpty)
                    ? 'Predicción con histórico. FP1, FP2 y FP3 se incorporan automáticamente.'
                    : 'Modelo previo a clasificación: usa solo las sesiones libres disponibles.',
                style: AppText.body(10.5, color: AppColors.textTertiary),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => ref.invalidate(weekendDataProvider),
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (weekend?.error != null) ...[
          StatusBanner(
            message: weekend!.error!,
            isError: true,
            onRetry: () => ref.invalidate(weekendDataProvider),
          ),
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
                    child: const Text('Restaurar calibrados'),
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

  Widget _buildBoard(
    AsyncValue<List<AssetPrediction>> async,
    Map<String, FantasyAssetInfo> catalog, {
    required bool isConstructor,
  }) {
    return async.when(
      data: (preds) {
        if (preds.isEmpty) {
          return const StatusBanner(
            message: 'Sin datos todavía. Sincroniza desde la pestaña Resumen.',
          );
        }
        final sorted = [...preds]
          ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
        final maxScore = sorted.first.expectedPoints;
        final bestValueId =
            ([
                  ...preds,
                ]..sort((a, b) => b.pointsPerValue.compareTo(a.pointsPerValue)))
                .first
                .assetId;

        return Column(
          children: [
            for (var i = 0; i < sorted.length; i++) ...[
              _row(
                sorted[i],
                i + 1,
                maxScore,
                bestValueId,
                catalog,
                isConstructor: isConstructor,
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Toca una fila para ver el desglose de por qué puntúa así. '
                'pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).',
                style: AppText.body(10.5, color: AppColors.textTertiary),
              ),
            ),
          ],
        );
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
        message: 'Error calculando el ranking: $e',
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
      if (rank == 1) TagChip('Pick', color: AppColors.lime),
      if (!isConstructor && pred.winProbability >= 0.18)
        TagChip('Capitán', color: AppColors.cyan),
      if (pred.assetId == bestValueId)
        TagChip('Valor', color: AppColors.violet),
      if (!isConstructor && (pred.breakdown['riesgo_dnf'] ?? 0) > 25)
        TagChip('Riesgo DNF', color: AppColors.warning),
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
          Text('POR QUÉ', style: AppText.mono(9)),
          const SizedBox(height: 6),
          for (final entry in pred.breakdown.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    catalog[entry.key]?.name ?? prettifyId(entry.key),
                    style: AppText.body(12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)} pts',
                    style: AppText.body(12, weight: FontWeight.w700),
                  ),
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
        Text('POR QUÉ (0–100 POR FACETA)', style: AppText.mono(9)),
        const SizedBox(height: 6),
        for (final key in kWeightKeys)
          if (pred.breakdown.containsKey(key))
            FeatureBarRow(
              label: kWeightLabels[key] ?? key,
              value: pred.breakdown[key]!,
            ),
        const SizedBox(height: 6),
        Row(
          children: [
            _probPill('VICTORIA', pred.winProbability),
            const SizedBox(width: 6),
            _probPill('PODIO', pred.podiumProbability),
            const SizedBox(width: 6),
            _probPill('TOP 10', pred.top10Probability),
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
