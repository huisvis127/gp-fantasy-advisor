import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
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

  void _hydrate(MyTeam? team) {
    if (_loadedFromStorage || team == null) return;
    _loadedFromStorage = true;
    for (var i = 0; i < _driverSlots && i < team.driverIds.length; i++) {
      _drivers[i] = team.driverIds[i];
    }
    for (var i = 0;
        i < _constructorSlots && i < team.constructorIds.length;
        i++) {
      _constructors[i] = team.constructorIds[i];
    }
  }

  @override
  Widget build(BuildContext context) {
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
    String nameOf(String? id) =>
        id == null ? 'Elegir…' : (catalog[id]?.name ?? prettifyId(id));

    final chosenIds =
        [..._drivers, ..._constructors].whereType<String>().toList();
    final totalCost = chosenIds.fold<double>(0, (sum, id) => sum + priceOf(id));
    final totalPoints =
        chosenIds.fold<double>(0, (sum, id) => sum + pointsOf(id));
    final remaining = GameRules.initialBudgetMillions - totalCost;
    final isComplete =
        !_drivers.contains(null) && !_constructors.contains(null);

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
              const SectionHead(
                kicker: 'Manual o importado',
                title: 'Mi equipo',
              ),
              const SizedBox(height: 6),
              Text(
                'Replica tu equipo tocando cada hueco (no hace falta cuenta), '
                'o impórtalo de tu cuenta de F1 Fantasy con el botón.',
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _importing ? null : () => _importFromFantasy(catalog),
                  icon: _importing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.lime),
                        )
                      : const Icon(Icons.cloud_download_rounded,
                          size: 16, color: AppColors.cyan),
                  label: Text(_importing
                      ? 'Importando…'
                      : 'Traer equipo del Fantasy (requiere sesión)'),
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
                    label: 'pts esperados este GP',
                  ),
                ),
              if (isComplete) const SizedBox(height: 14),
              Text('PILOTOS',
                  style: AppText.mono(10, color: AppColors.textSecondary)),
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
                          ? 'Piloto ${i + 1}'
                          : '${priceOf(_drivers[i]).toStringAsFixed(1)} M\$ · ${pointsOf(_drivers[i]).toStringAsFixed(1)} pts',
                      name: nameOf(_drivers[i]),
                      subtitle: _drivers[i] == null
                          ? 'Toca para elegir'
                          : (catalog[_drivers[i]]?.teamName ?? ''),
                      barColor: _drivers[i] == null
                          ? AppColors.border2
                          : teamColor(catalog[_drivers[i]]
                              ?.teamName
                              .toLowerCase()
                              .replaceAll(' ', '_')),
                      onTap: () => _pickDriver(i, driverPreds, catalog),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('CONSTRUCTORES',
                  style: AppText.mono(10, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _constructorSlots; i++) ...[
                    Expanded(
                      child: AssetCard(
                        tag: _constructors[i] == null
                            ? 'Constructor ${i + 1}'
                            : '${priceOf(_constructors[i]).toStringAsFixed(1)} M\$ · ${pointsOf(_constructors[i]).toStringAsFixed(1)} pts',
                        name: nameOf(_constructors[i]),
                        subtitle: _constructors[i] == null
                            ? 'Toca para elegir'
                            : 'Constructor',
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
                      ? 'Coste ${totalCost.toStringAsFixed(1)} M\$ · presupuesto restante ${remaining.toStringAsFixed(1)} M\$.'
                      : 'Te pasas del presupuesto en ${(-remaining).toStringAsFixed(1)} M\$. '
                          'Los precios pueden ser estimados: ajusta tu selección.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isComplete ? () => _save(remaining) : null,
                      child: const Text('GUARDAR MI EQUIPO'),
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
                    child: const Text('Vaciar'),
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
            tag: 'Boost ×2 recomendado',
            color: AppColors.cyan,
            name: nameOf(boostId),
            subtitle:
                'Duplicaría ${boostGain.toStringAsFixed(1)} pts esperados',
            score: '+${boostGain.toStringAsFixed(1)}',
          ),
        ],

        // ===== SUGERENCIA DE CAMBIOS =====
        if (isComplete) ...[
          const SizedBox(height: 14),
          const SectionHead(kicker: 'Optimizador', title: 'Planes de cambios'),
          const SizedBox(height: 8),
          _TransferPlans(catalog: catalog),
        ],
      ],
    );
  }

  /// Importa el equipo real desde la cuenta de F1 Fantasy. Si no hay sesión
  /// guardada, abre primero el login. Cualquier fallo se muestra con detalle
  /// en un banner (nunca en silencio).
  Future<void> _importFromFantasy(Map<String, FantasyAssetInfo> catalog) async {
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
            _importError = 'Sin sesión: el login no llegó a capturar el token.';
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
          _constructors[i] =
              i < team.constructorIds.length ? team.constructorIds[i] : null;
        }
        _importing = false;
      });
      await ref.read(myTeamProvider.notifier).save(team);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface3,
            content: Text(
              'Equipo importado: ${team.driverIds.length} pilotos, '
              '${team.constructorIds.length} constructores.',
              style: AppText.body(13, color: AppColors.lime),
            ),
          ),
        );
      }
    } on TeamImportException catch (e) {
      setState(() {
        _importing = false;
        _importError = e.message;
      });
    } catch (e) {
      setState(() {
        _importing = false;
        _importError = 'Fallo inesperado importando: $e';
      });
    }
  }

  Future<void> _pickDriver(
    int slot,
    List<AssetPrediction> preds,
    Map<String, FantasyAssetInfo> catalog,
  ) async {
    if (preds.isEmpty) return;
    final options = [...preds]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final available = options
        .where(
            (p) => !_drivers.contains(p.assetId) || _drivers[slot] == p.assetId)
        .toList();
    final chosen = await showPickerSheet<AssetPrediction>(
      context: context,
      title: 'Piloto ${slot + 1}',
      items: available,
      selected: available
          .where((p) => p.assetId == _drivers[slot])
          .cast<AssetPrediction?>()
          .firstOrNull,
      itemLabel: (p) => catalog[p.assetId]?.name ?? prettifyId(p.assetId),
      itemMeta: (p) =>
          '${catalog[p.assetId]?.teamName ?? ''} · ${p.priceMillions.toStringAsFixed(1)} M\$ · ${p.expectedPoints.toStringAsFixed(1)} pts',
      itemColor: (p) => teamColor(
          catalog[p.assetId]?.teamName.toLowerCase().replaceAll(' ', '_')),
    );
    if (chosen != null) setState(() => _drivers[slot] = chosen.assetId);
  }

  Future<void> _pickConstructor(
    int slot,
    List<AssetPrediction> preds,
    Map<String, FantasyAssetInfo> catalog,
  ) async {
    if (preds.isEmpty) return;
    final options = [...preds]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final available = options
        .where((p) =>
            !_constructors.contains(p.assetId) ||
            _constructors[slot] == p.assetId)
        .toList();
    final chosen = await showPickerSheet<AssetPrediction>(
      context: context,
      title: 'Constructor ${slot + 1}',
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
          content: Text('Equipo guardado',
              style: AppText.body(13, color: AppColors.lime)),
        ),
      );
    }
  }
}

class _TransferPlans extends ConsumerWidget {
  const _TransferPlans({required this.catalog});

  final Map<String, FantasyAssetInfo> catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(transferPlansProvider);
    return plansAsync.when(
      data: (plans) {
        final realPlans = plans.where((p) => p.numberOfTransfers > 0).toList();
        if (realPlans.isEmpty) {
          return const StatusBanner(
            message:
                'Tu equipo ya está cerca del óptimo con los pesos actuales: '
                'ningún cambio mejora los puntos esperados. Guarda el equipo para actualizar.',
          );
        }
        return Column(
          children: [
            for (final plan in realPlans) ...[
              _planCard(plan),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).',
                style: AppText.body(10.5, color: AppColors.textTertiary),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
        ),
      ),
      error: (e, _) => StatusBanner(
        message: 'No se pudieron calcular los cambios: $e',
        isError: true,
        onRetry: () => ref.invalidate(transferPlansProvider),
      ),
    );
  }

  Widget _planCard(TransferPlan plan) {
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);
    final gainColor =
        plan.netExpectedGain > 0 ? AppColors.ok : AppColors.warning;
    return RefCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan.numberOfTransfers} CAMBIO${plan.numberOfTransfers == 1 ? '' : 'S'}'
                  '${plan.extraTransferPenaltyApplied != 0 ? ' · PENALIZACIÓN ${plan.extraTransferPenaltyApplied}' : ''}',
                  style: AppText.mono(9.5, color: AppColors.textSecondary),
                ),
              ),
              Text(
                '${plan.netExpectedGain >= 0 ? '+' : ''}${plan.netExpectedGain.toStringAsFixed(1)} pts',
                style: AppText.syne(15, color: gainColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < plan.transfersOut.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(nameOf(plan.transfersOut[i]),
                        style:
                            AppText.body(12.5, color: AppColors.textSecondary)),
                  ),
                  const Icon(Icons.login_rounded,
                      size: 14, color: AppColors.ok),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      i < plan.transfersIn.length
                          ? nameOf(plan.transfersIn[i])
                          : '',
                      style: AppText.body(12.5, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
