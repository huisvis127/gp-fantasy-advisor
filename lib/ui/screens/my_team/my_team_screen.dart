import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/constants.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/providers.dart'
    show
        teamImportServiceProvider,
        currentSeasonProvider,
        fantasyAuthServiceProvider;
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/team_import_service.dart';
import '../../../domain/engine/team_optimizer.dart';
import '../../../domain/models/my_team.dart';
import '../../../domain/models/prediction.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';

/// Pantalla «Mi equipo» (tab-myteam de la referencia): SIN login ni liga.
/// Replicas tu equipo tocando cada hueco (5 pilotos + 2 constructores, con
/// la hoja .picker-sheet de la referencia), y la app te da:
///  - puntuación esperada del equipo para el GP seleccionado,
///  - el piloto óptimo para el boost ×2,
///  - los 3 mejores planes de cambios (0/1/2 y 3º con -10 pts).
class MyTeamScreen extends ConsumerStatefulWidget {
  const MyTeamScreen({super.key});

  @override
  ConsumerState<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends ConsumerState<MyTeamScreen> {
  static const int _driverSlots = 5;
  static const int _constructorSlots = 2;

  final List<String?> _drivers = List.filled(_driverSlots, null);
  final List<String?> _constructors = List.filled(_constructorSlots, null);
  bool _loadedFromStorage = false;
  bool _importing = false;
  String? _importError;
  double? _budgetCapMillions;
  double _storedBankMillions = 0;

  void _hydrate(MyTeam? team) {
    if (_loadedFromStorage || team == null) return;
    _loadedFromStorage = true;
    _storedBankMillions = team.remainingBudgetMillions;
    for (var i = 0; i < _driverSlots && i < team.driverIds.length; i++) {
      _drivers[i] = team.driverIds[i];
    }
    for (
      var i = 0;
      i < _constructorSlots && i < team.constructorIds.length;
      i++
    ) {
      _constructors[i] = team.constructorIds[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final strings = AppStrings(ref.watch(appLocaleProvider));
    final teamAsync = ref.watch(myTeamProvider);
    final driversAsync = ref.watch(driverPredictionsProvider);
    final constructorsAsync = ref.watch(engineConstructorPredictionsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};

    teamAsync.whenData(_hydrate);

    final driverPreds = driversAsync.valueOrNull ?? const <AssetPrediction>[];
    final constructorPreds =
        constructorsAsync.valueOrNull ?? const <AssetPrediction>[];
    final predById = {
      for (final p in [...driverPreds, ...constructorPreds]) p.assetId: p,
    };

    double priceOf(String? id) => id == null
        ? 0
        : (predById[id]?.priceMillions ?? catalog[id]?.priceMillions ?? 0);
    double pointsOf(String? id) =>
        id == null ? 0 : (predById[id]?.expectedPoints ?? 0);
    String nameOf(String? id) => id == null
        ? strings.t('choose')
        : (catalog[id]?.name ?? prettifyId(id));

    final chosenIds = [
      ..._drivers,
      ..._constructors,
    ].whereType<String>().toList();
    final totalCost = chosenIds.fold<double>(0, (sum, id) => sum + priceOf(id));
    final totalPoints = chosenIds.fold<double>(
      0,
      (sum, id) => sum + pointsOf(id),
    );
    final isComplete =
        !_drivers.contains(null) && !_constructors.contains(null);
    _budgetCapMillions ??= _loadedFromStorage && isComplete
        ? totalCost + _storedBankMillions
        : GameRules.initialBudgetMillions;
    final remaining = _budgetCapMillions! - totalCost;

    // Boost: el piloto del equipo con más puntos esperados (×2).
    String? boostId;
    double boostGain = 0;
    for (final id in _drivers.whereType<String>()) {
      if (pointsOf(id) > boostGain) {
        boostGain = pointsOf(id);
        boostId = id;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: strings.t('manual_imported'),
                title: strings.t('my_team'),
              ),
              const SizedBox(height: 6),
              Text(
                strings.t('team_intro'),
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _importing
                      ? null
                      : () => _importFromFantasy(catalog),
                  icon: _importing
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.lime,
                          ),
                        )
                      : Icon(
                          Icons.cloud_download_rounded,
                          size: 16,
                          color: AppColors.cyan,
                        ),
                  label: Text(
                    _importing
                        ? strings.t('importing')
                        : strings.t('import_team'),
                  ),
                ),
              ),
              if (_importError != null) ...[
                const SizedBox(height: 8),
                StatusBanner(
                  message: _importError!,
                  isError: true,
                  onRetry: () => _importFromFantasy(catalog),
                ),
              ],
              const SizedBox(height: 14),
              if (isComplete)
                Center(
                  child: TotalPill(
                    value: totalPoints.toStringAsFixed(1),
                    label: strings.t('expected_points'),
                  ),
                ),
              if (isComplete) const SizedBox(height: 14),
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
                  for (var i = 0; i < _driverSlots; i++)
                    AssetCard(
                      tag: _drivers[i] == null
                          ? '${strings.t('driver')} ${i + 1}'
                          : '${priceOf(_drivers[i]).toStringAsFixed(1)} M\$ · ${pointsOf(_drivers[i]).toStringAsFixed(1)} pts',
                      name: nameOf(_drivers[i]),
                      subtitle: _drivers[i] == null
                          ? strings.t('tap_choose')
                          : (catalog[_drivers[i]]?.teamName ?? ''),
                      barColor: _drivers[i] == null
                          ? AppColors.border2
                          : teamColor(
                              catalog[_drivers[i]]?.teamName
                                  .toLowerCase()
                                  .replaceAll(' ', '_'),
                            ),
                      onTap: () => _pickDriver(i, driverPreds, catalog),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.t('constructors'),
                style: AppText.mono(10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _constructorSlots; i++) ...[
                    Expanded(
                      child: AssetCard(
                        tag: _constructors[i] == null
                            ? '${strings.t('constructor')} ${i + 1}'
                            : '${priceOf(_constructors[i]).toStringAsFixed(1)} M\$ · ${pointsOf(_constructors[i]).toStringAsFixed(1)} pts',
                        name: nameOf(_constructors[i]),
                        subtitle: _constructors[i] == null
                            ? strings.t('tap_choose')
                            : strings.t('constructor'),
                        barColor: _constructors[i] == null
                            ? AppColors.border2
                            : teamColor(_constructors[i]),
                        tagColor: AppColors.orange,
                        onTap: () =>
                            _pickConstructor(i, constructorPreds, catalog),
                      ),
                    ),
                    if (i < _constructorSlots - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TransferNote(
                isError: remaining < 0,
                child: Text(
                  remaining >= 0
                      ? '${strings.t('cost')} ${totalCost.toStringAsFixed(1)} M\$  ·  ${strings.t('bank')} ${remaining.toStringAsFixed(1)} M\$'
                      : '${strings.t('over_budget')} ${(-remaining).toStringAsFixed(1)} M\$',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isComplete ? () => _save(remaining) : null,
                      child: Text(strings.t('save_team')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      for (var i = 0; i < _driverSlots; i++) {
                        _drivers[i] = null;
                      }
                      for (var i = 0; i < _constructorSlots; i++) {
                        _constructors[i] = null;
                      }
                    }),
                    child: Text(strings.t('clear')),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ===== BOOST =====
        if (isComplete && boostId != null) ...[
          const SizedBox(height: 14),
          RecCard(
            tag: strings.t('recommended_boost'),
            color: AppColors.cyan,
            name: nameOf(boostId),
            subtitle:
                '${strings.t('boost_gain')} · ${boostGain.toStringAsFixed(1)}',
            score: '+${boostGain.toStringAsFixed(1)}',
          ),
        ],

        // ===== SUGERENCIA DE CAMBIOS =====
        if (isComplete) ...[
          const SizedBox(height: 14),
          SectionHead(
            kicker: strings.t('decision_center'),
            title: strings.t('decision_sub'),
          ),
          const SizedBox(height: 8),
          _DecisionCenter(catalog: catalog, strings: strings),
        ],
      ],
    );
  }

  /// Importa el equipo real desde la cuenta de F1 Fantasy. Si no hay sesión
  /// guardada, abre primero el login. Cualquier fallo se muestra con detalle
  /// en un banner (nunca en silencio).
  Future<void> _importFromFantasy(Map<String, FantasyAssetInfo> catalog) async {
    final strings = AppStrings(ref.read(appLocaleProvider));
    setState(() {
      _importing = true;
      _importError = null;
    });
    try {
      final auth = ref.read(fantasyAuthServiceProvider);
      var token = await auth.readStoredToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const FantasyLoginScreen()),
        );
        token = await auth.readStoredToken();
        if (loggedIn != true || token == null || token.isEmpty) {
          setState(() {
            _importing = false;
            _importError = strings.t('no_session');
          });
          return;
        }
      }

      final driverCatalog = <String, String>{};
      final constructorCatalog = <String, String>{};
      for (final entry in catalog.entries) {
        if (entry.value.kind == FantasyAssetKind.driver) {
          driverCatalog[entry.key] = entry.value.name;
        } else {
          constructorCatalog[entry.key] = entry.value.name;
        }
      }

      final service = ref.read(teamImportServiceProvider);
      final season = ref.read(currentSeasonProvider);
      final team = await service.importMyTeam(
        season: season,
        driverCatalog: driverCatalog,
        constructorCatalog: constructorCatalog,
      );

      setState(() {
        for (var i = 0; i < _driverSlots; i++) {
          _drivers[i] = i < team.driverIds.length ? team.driverIds[i] : null;
        }
        for (var i = 0; i < _constructorSlots; i++) {
          _constructors[i] = i < team.constructorIds.length
              ? team.constructorIds[i]
              : null;
        }
        _storedBankMillions = team.remainingBudgetMillions;
        _budgetCapMillions = null;
        _importing = false;
      });
      await ref.read(myTeamProvider.notifier).save(team);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface3,
            content: Text(
              '${strings.t('imported_team')}: ${team.driverIds.length} '
              '${strings.t('drivers').toLowerCase()}, '
              '${team.constructorIds.length} ${strings.t('constructors').toLowerCase()}.',
              style: AppText.body(13, color: AppColors.lime),
            ),
          ),
        );
      }
    } on TeamImportException {
      setState(() {
        _importing = false;
        _importError = strings.t('import_failed');
      });
    } catch (e) {
      setState(() {
        _importing = false;
        _importError = '${strings.t('unexpected_import')}: $e';
      });
    }
  }

  Future<void> _pickDriver(
    int slot,
    List<AssetPrediction> preds,
    Map<String, FantasyAssetInfo> catalog,
  ) async {
    final strings = AppStrings(ref.read(appLocaleProvider));
    if (preds.isEmpty) return;
    final options = [...preds]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final available = options
        .where(
          (p) => !_drivers.contains(p.assetId) || _drivers[slot] == p.assetId,
        )
        .toList();
    final chosen = await showPickerSheet<AssetPrediction>(
      context: context,
      title: '${strings.t('driver')} ${slot + 1}',
      items: available,
      selected: available
          .where((p) => p.assetId == _drivers[slot])
          .cast<AssetPrediction?>()
          .firstOrNull,
      itemLabel: (p) => catalog[p.assetId]?.name ?? prettifyId(p.assetId),
      itemMeta: (p) =>
          '${catalog[p.assetId]?.teamName ?? ''} · ${p.priceMillions.toStringAsFixed(1)} M\$ · ${p.expectedPoints.toStringAsFixed(1)} pts',
      itemColor: (p) => teamColor(
        catalog[p.assetId]?.teamName.toLowerCase().replaceAll(' ', '_'),
      ),
    );
    if (chosen != null) setState(() => _drivers[slot] = chosen.assetId);
  }

  Future<void> _pickConstructor(
    int slot,
    List<AssetPrediction> preds,
    Map<String, FantasyAssetInfo> catalog,
  ) async {
    final strings = AppStrings(ref.read(appLocaleProvider));
    if (preds.isEmpty) return;
    final options = [...preds]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final available = options
        .where(
          (p) =>
              !_constructors.contains(p.assetId) ||
              _constructors[slot] == p.assetId,
        )
        .toList();
    final chosen = await showPickerSheet<AssetPrediction>(
      context: context,
      title: '${strings.t('constructor')} ${slot + 1}',
      items: available,
      selected: available
          .where((p) => p.assetId == _constructors[slot])
          .cast<AssetPrediction?>()
          .firstOrNull,
      itemLabel: (p) => catalog[p.assetId]?.name ?? prettifyId(p.assetId),
      itemMeta: (p) =>
          '${p.priceMillions.toStringAsFixed(1)} M\$ · ${p.expectedPoints.toStringAsFixed(1)} pts',
      itemColor: (p) => teamColor(p.assetId),
    );
    if (chosen != null) setState(() => _constructors[slot] = chosen.assetId);
  }

  Future<void> _save(double remainingBudget) async {
    final strings = AppStrings(ref.read(appLocaleProvider));
    final team = MyTeam(
      driverIds: _drivers.whereType<String>().toList(),
      constructorIds: _constructors.whereType<String>().toList(),
      remainingBudgetMillions: remainingBudget < 0 ? 0 : remainingBudget,
      source: MyTeamSource.manual,
    );
    await ref.read(myTeamProvider.notifier).save(team);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface3,
          content: Text(
            strings.t('team_saved'),
            style: AppText.body(13, color: AppColors.lime),
          ),
        ),
      );
    }
  }
}

class _DecisionCenter extends ConsumerWidget {
  const _DecisionCenter({required this.catalog, required this.strings});

  final Map<String, FantasyAssetInfo> catalog;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final centerAsync = ref.watch(teamDecisionCenterProvider);
    final team = ref.watch(myTeamProvider).valueOrNull;
    return centerAsync.when(
      data: (center) {
        if (center == null || team == null) {
          return StatusBanner(message: strings.t('complete_team'));
        }
        final budget =
            center.currentTeam.totalCostMillions + team.remainingBudgetMillions;
        return Column(
          children: [
            _DecisionCard(
              label: strings.t('one_change'),
              result: center.oneTransfer?.resultingTeam,
              transfer: center.oneTransfer,
              current: center.currentTeam,
              budget: budget,
              catalog: catalog,
              strings: strings,
              accent: AppColors.cyan,
            ),
            const SizedBox(height: 10),
            _DecisionCard(
              label: strings.t('two_changes'),
              result: center.twoTransfers?.resultingTeam,
              transfer: center.twoTransfers,
              current: center.currentTeam,
              budget: budget,
              catalog: catalog,
              strings: strings,
              accent: AppColors.orange,
            ),
            const SizedBox(height: 10),
            _DecisionCard(
              label: strings.t('perfect_team'),
              result: center.perfectTeam,
              current: center.currentTeam,
              budget: budget,
              catalog: catalog,
              strings: strings,
              accent: AppColors.violet,
              perfect: true,
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
            const SizedBox(height: 8),
            Text(strings.t('loading'), style: AppText.mono(9)),
          ],
        ),
      ),
      error: (error, _) => StatusBanner(
        message: '${strings.t('no_valid_plan')} $error',
        isError: true,
        onRetry: () => ref.invalidate(teamDecisionCenterProvider),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.label,
    required this.result,
    required this.current,
    required this.budget,
    required this.catalog,
    required this.strings,
    required this.accent,
    this.transfer,
    this.perfect = false,
  });

  final String label;
  final TeamCombo? result;
  final TeamCombo current;
  final double budget;
  final Map<String, FantasyAssetInfo> catalog;
  final AppStrings strings;
  final Color accent;
  final TransferPlan? transfer;
  final bool perfect;

  String _name(String id) => catalog[id]?.name ?? prettifyId(id);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final gain = result == null
        ? null
        : result!.totalExpectedPoints - current.totalExpectedPoints;
    final positive = gain != null && gain >= 0;
    final ids = result == null
        ? const <String>[]
        : [...result!.driverIds, ...result!.constructorIds];
    final currentIds = {...current.driverIds, ...current.constructorIds};

    return RefCard(
      padding: const EdgeInsets.all(14),
      borderColor: accent.withValues(alpha: perfect ? 0.48 : 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfect
                          ? strings.t('reference')
                          : (positive
                                ? strings.t('best_option')
                                : strings.t('not_worth')),
                      style: AppText.mono(8.5, color: accent),
                    ),
                    const SizedBox(height: 3),
                    Text(label, style: AppText.syne(20)),
                  ],
                ),
              ),
              if (result != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result!.totalExpectedPoints.toStringAsFixed(1),
                      style: AppText.syne(25, color: AppColors.lime),
                    ),
                    Text(strings.t('points'), style: AppText.mono(8)),
                  ],
                ),
            ],
          ),
          if (perfect) ...[
            const SizedBox(height: 7),
            Text(
              strings.t('perfect_sub'),
              style: AppText.body(10.5, color: AppColors.textTertiary),
            ),
          ],
          if (result == null) ...[
            const SizedBox(height: 12),
            Text(
              strings.t('no_valid_plan'),
              style: AppText.body(12, color: AppColors.textSecondary),
            ),
          ] else ...[
            if (!perfect && transfer != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  border: Border.all(color: AppColors.border1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TransferColumn(
                        label: strings.t('out'),
                        ids: transfer!.transfersOut,
                        nameOf: _name,
                        color: AppColors.error,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.cyan,
                      ),
                    ),
                    Expanded(
                      child: _TransferColumn(
                        label: strings.t('in'),
                        ids: transfer!.transfersIn,
                        nameOf: _name,
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ids.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                childAspectRatio: 2.15,
              ),
              itemBuilder: (context, index) {
                final id = ids[index];
                final info = catalog[id];
                final constructor = index >= result!.driverIds.length;
                final color = constructor
                    ? teamColor(id)
                    : teamColor(
                        info?.teamName.toLowerCase().replaceAll(' ', '_'),
                      );
                final incoming = !currentIds.contains(id) && !perfect;
                return Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.075),
                    border: Border.all(
                      color: incoming
                          ? AppColors.lime
                          : color.withValues(alpha: 0.55),
                      width: incoming ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        constructor
                            ? strings.t('constructor').toUpperCase()
                            : '${strings.t('driver').toUpperCase()} ${index + 1}',
                        maxLines: 1,
                        style: AppText.mono(7.2, color: color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _name(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(11.5, weight: FontWeight.w800),
                      ),
                      Text(
                        '${info?.priceMillions.toStringAsFixed(1) ?? '—'} M\$',
                        style: AppText.body(8.5, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: strings.t('cost'),
                    value:
                        '${result!.totalCostMillions.toStringAsFixed(1)} M\$',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _Metric(
                    label: strings.t('bank'),
                    value:
                        '${(budget - result!.totalCostMillions).clamp(0, double.infinity).toStringAsFixed(1)} M\$',
                  ),
                ),
                if (!perfect && gain != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: _Metric(
                      label: strings.t('impact'),
                      value:
                          '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}',
                      color: gain >= 0 ? AppColors.lime : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferColumn extends StatelessWidget {
  const _TransferColumn({
    required this.label,
    required this.ids,
    required this.nameOf,
    required this.color,
  });

  final String label;
  final List<String> ids;
  final String Function(String) nameOf;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.mono(7.5, color: AppColors.textTertiary)),
      const SizedBox(height: 4),
      for (final id in ids)
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            nameOf(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(10, color: color, weight: FontWeight.w800),
          ),
        ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(AppRadii.xs),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.mono(7)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          style: AppText.body(
            11,
            color: color ?? AppColors.textPrimary,
            weight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
