import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(fantasyAuthServiceProvider);
    return FutureBuilder<List<String?>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        auth.readStoredToken(),
        auth.readSessionSnapshot(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final token = snapshot.data?[0];
        final snapshotRaw = snapshot.data?[1];
        if ((token == null || token.isEmpty) &&
            (snapshotRaw == null || snapshotRaw.isEmpty)) {
          return _signedOut();
        }
        return _LeaguesList(token: token ?? '', snapshotRaw: snapshotRaw);
      },
    );
  }

  Widget _signedOut() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Clasificación privada'),
              const SizedBox(height: 6),
              Text('Tu liga', style: AppText.syne(32)),
              const SizedBox(height: 8),
              Text(
                'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('INICIAR SESIÓN'),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FantasyLoginScreen()),
                    );
                    if (mounted) setState(() => _refreshKey++);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaguesList extends ConsumerStatefulWidget {
  const _LeaguesList({required this.token, this.snapshotRaw});

  final String token;
  final String? snapshotRaw;

  @override
  ConsumerState<_LeaguesList> createState() => _LeaguesListState();
}

class _LeaguesListState extends ConsumerState<_LeaguesList> {
  late Future<Map<String, dynamic>> _request;
  Map<String, dynamic>? _snapshot;

  @override
  void initState() {
    super.initState();
    final raw = widget.snapshotRaw;
    if (raw != null && raw.isNotEmpty) {
      try {
        _snapshot = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _snapshot = null;
      }
    }
    _load();
  }

  void _load() {
    final cachedLeagues = _snapshot?['leagues'];
    if (cachedLeagues is Map) {
      _request = Future.value(Map<String, dynamic>.from(cachedLeagues));
      return;
    }
    final api = ref.read(fantasyApiProvider);
    final season = ref.read(currentSeasonProvider);
    _request = api.getLeagueEntrants(season: season, bearerToken: widget.token);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              StatusBanner(
                message:
                    'No se pudieron cargar tus ligas. La sesión puede haber caducado o el servicio no responde.',
                isError: true,
                onRetry: _retry,
              ),
            ],
          );
        }

        final leagues = _extractList(snapshot.data, const {
          'leagues',
          'league_entrants',
          'results',
          'details',
          'value',
        });
        if (leagues.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: const [
              StatusBanner(
                message:
                    'La sesión es válida, pero la cuenta no devolvió ligas privadas.',
              ),
            ],
          );
        }

        return RefreshIndicator(
          color: AppColors.lime,
          onRefresh: () async {
            _retry();
            await _request;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              const SectionHead(
                kicker: 'Competición',
                title: 'Mis ligas',
              ),
              const SizedBox(height: 5),
              Text(
                'Toca una liga para consultar la clasificación.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final league in leagues) ...[
                _leagueCard(league),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _leagueCard(Map<String, dynamic> league) {
    final id = _first(league, const ['league_id', 'leagueid', 'id']);
    final rawName = _first(league,
            const ['league_name', 'leaguename', 'name', 'display_name']) ??
        'Liga';
    final name = _decodeDisplayText(rawName.toString());
    var count = _first(league,
        const ['entry_count', 'entryCount', 'members_count', 'memebercount']);
    final cachedLeaderboards = _snapshot?['leaderboards'];
    final cached = cachedLeaderboards is Map && id != null
        ? cachedLeaderboards[id.toString()]
        : null;
    if (cached is Map) {
      final capturedRows = _extractList(cached, const {
        'leaderboards',
        'leaderboard',
        'entries',
        'results',
        'member',
        'details',
        'value',
      });
      if (capturedRows.isNotEmpty) count = capturedRows.length;
    }
    final rank = _first(league, const ['rank', 'position', 'overall_rank']);
    return RefCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: id == null
            ? null
            : () => _openLeaderboard(id.toString(), name.toString()),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.lime.withValues(alpha: .35)),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.lime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toString(),
                        style: AppText.body(14, weight: FontWeight.w700)),
                    if (count != null)
                      Text('$count participantes',
                          style:
                              AppText.body(11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              if (rank != null) TagChip('#$rank', color: AppColors.cyan),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLeaderboard(String id, String name) async {
    final api = ref.read(fantasyApiProvider);
    final season = ref.read(currentSeasonProvider);
    final cachedLeaderboards = _snapshot?['leaderboards'];
    final cached = cachedLeaderboards is Map ? cachedLeaderboards[id] : null;
    final request = cached is Map
        ? Future.value(Map<String, dynamic>.from(cached))
        : api.getLeagueLeaderboard(
            season: season,
            leagueId: id,
            bearerToken: widget.token,
          );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      builder: (_) => _LeaderboardSheet(
        name: name,
        request: request,
      ),
    );
  }
}

class _LeaderboardSheet extends StatelessWidget {
  const _LeaderboardSheet({required this.name, required this.request});

  final String name;
  final Future<Map<String, dynamic>> request;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(9)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(name, style: AppText.syne(20))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: request,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: StatusBanner(
                          message: 'No se pudo abrir la clasificación.',
                          isError: true),
                    );
                  }
                  final rows = _extractList(snapshot.data, const {
                    'leaderboards',
                    'leaderboard',
                    'entries',
                    'results',
                    'member',
                    'details',
                    'value',
                  });
                  if (rows.isEmpty) {
                    return const Center(
                        child: Text('Sin participantes disponibles.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (_, index) {
                      final row = rows[index];
                      final rank = _first(row, const [
                            'rank',
                            'position',
                            'overall_rank',
                            'userrank'
                          ]) ??
                          index + 1;
                      final rawName = _first(row, const [
                            'team_name',
                            'entry_name',
                            'display_name',
                            'name',
                            'user_name',
                            'teamname',
                            'username'
                          ]) ??
                          'Participante';
                      final name = _displayValue(rawName);
                      final points = _first(row, const [
                        'points',
                        'total_points',
                        'score',
                        'overall_points',
                        'ovpoints',
                        'totalpoints'
                      ]);
                      return RefCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 35,
                                child: Text('#$rank',
                                    style: AppText.mono(10,
                                        color: AppColors.lime))),
                            Expanded(
                                child: Text(name,
                                    style: AppText.body(13,
                                        weight: FontWeight.w700))),
                            if (points != null)
                              Text('$points pts',
                                  style:
                                      AppText.mono(10, color: AppColors.cyan)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _extractList(
    dynamic node, Set<String> preferredKeys) {
  if (node is Map) {
    for (final entry in node.entries) {
      if (preferredKeys.contains(entry.key.toString().toLowerCase()) &&
          entry.value is List) {
        final maps = (entry.value as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (maps.isNotEmpty) return maps;
      }
    }
    for (final value in node.values) {
      final result = _extractList(value, preferredKeys);
      if (result.isNotEmpty) return result;
    }
  } else if (node is List) {
    final maps =
        node.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (maps.isNotEmpty) return maps;
  }
  return const [];
}

dynamic _first(Map<String, dynamic> map, List<String> keys) {
  final wanted = keys.map((key) => key.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (!wanted.contains(entry.key.toLowerCase())) continue;
    final value = entry.value;
    if (value != null && value.toString().isNotEmpty) return value;
  }
  return null;
}

String _decodeDisplayText(String value) {
  try {
    return Uri.decodeComponent(value.replaceAll('+', ' '));
  } catch (_) {
    return value;
  }
}

String _displayValue(dynamic value) {
  if (value is List) {
    final items = value
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => _decodeDisplayText(item.toString()))
        .toList();
    return items.isEmpty ? 'Participante' : items.join(' / ');
  }
  return _decodeDisplayText(value.toString());
}
