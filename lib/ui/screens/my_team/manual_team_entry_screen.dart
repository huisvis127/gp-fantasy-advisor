import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/constants.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/theme.dart';
import '../../../domain/models/my_team.dart';
import '../../../domain/models/prediction.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';

class ManualTeamEntryScreen extends ConsumerStatefulWidget {
  const ManualTeamEntryScreen({super.key});

  @override
  ConsumerState<ManualTeamEntryScreen> createState() =>
      _ManualTeamEntryScreenState();
}

class _ManualTeamEntryScreenState extends ConsumerState<ManualTeamEntryScreen> {
  final Set<String> _selectedDrivers = {};
  final Set<String> _selectedConstructors = {};

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driverPredictionsProvider);
    final constructorsAsync = ref.watch(constructorPredictionsProvider);
    final names = ref.watch(fantasyAssetNameProvider).valueOrNull ??
        const <String, FantasyAssetInfo>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Introducir mi equipo')),
      body: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => EmptyState.apiDown(
            onRetry: () => ref.invalidate(driverPredictionsProvider)),
        data: (drivers) => constructorsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => EmptyState.apiDown(
              onRetry: () => ref.invalidate(constructorPredictionsProvider)),
          data: (constructors) {
            if (drivers.isEmpty || constructors.isEmpty) {
              return const EmptyState.noData();
            }
            final spent = _sumPrices(drivers, _selectedDrivers) +
                _sumPrices(constructors, _selectedConstructors);
            final remaining = GameRules.initialBudgetMillions - spent;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDrivers.length}/5 pilotos · '
                          '${_selectedConstructors.length}/2 constructores',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        NeonBadge(
                          label: '${remaining.toStringAsFixed(1)} M',
                          color: remaining < 0 ? AppColors.error : AppColors.ok,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    children: [
                      Text('Pilotos',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ..._sorted(drivers).map((p) => _PickTile(
                            prediction: p,
                            info: names[p.assetId],
                            selected: _selectedDrivers.contains(p.assetId),
                            enabled: _selectedDrivers.contains(p.assetId) ||
                                _selectedDrivers.length <
                                    GameRules.driversPerTeam,
                            onChanged: () => _toggle(
                              p.assetId,
                              _selectedDrivers,
                              GameRules.driversPerTeam,
                            ),
                          )),
                      const SizedBox(height: AppSpacing.md),
                      Text('Constructores',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ..._sorted(constructors).map((p) => _PickTile(
                            prediction: p,
                            info: names[p.assetId],
                            selected: _selectedConstructors.contains(p.assetId),
                            enabled:
                                _selectedConstructors.contains(p.assetId) ||
                                    _selectedConstructors.length <
                                        GameRules.constructorsPerTeam,
                            onChanged: () => _toggle(
                              p.assetId,
                              _selectedConstructors,
                              GameRules.constructorsPerTeam,
                            ),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _canSave(remaining) ? () => _save(remaining) : null,
                      child: const Text('Guardar mi equipo'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<AssetPrediction> _sorted(List<AssetPrediction> rows) =>
      [...rows]..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));

  double _sumPrices(List<AssetPrediction> predictions, Set<String> ids) {
    final byId = {for (final p in predictions) p.assetId: p};
    return ids.fold(0.0, (s, id) => s + (byId[id]?.priceMillions ?? 0));
  }

  void _toggle(String id, Set<String> target, int max) {
    setState(() {
      if (target.contains(id)) {
        target.remove(id);
      } else if (target.length < max) {
        target.add(id);
      }
    });
  }

  bool _canSave(double remaining) {
    return _selectedDrivers.length == GameRules.driversPerTeam &&
        _selectedConstructors.length == GameRules.constructorsPerTeam &&
        remaining >= 0;
  }

  Future<void> _save(double remaining) async {
    final team = MyTeam(
      driverIds: _selectedDrivers.toList(),
      constructorIds: _selectedConstructors.toList(),
      remainingBudgetMillions: remaining,
      source: MyTeamSource.manual,
    );
    await ref.read(myTeamProvider.notifier).save(team);
    if (mounted) Navigator.of(context).pop();
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.prediction,
    required this.info,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AssetPrediction prediction;
  final FantasyAssetInfo? info;
  final bool selected;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: enabled ? (_) => onChanged() : null,
      title: Text(info?.name ?? prediction.assetId),
      subtitle: Text(
        '${info?.teamName ?? ''} · ${prediction.priceMillions.toStringAsFixed(1)} M · '
        '${prediction.expectedPoints.toStringAsFixed(1)} pts',
      ),
      activeColor: AppColors.accentCyan,
      contentPadding: EdgeInsets.zero,
    );
  }
}
