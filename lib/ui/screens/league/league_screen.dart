import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/models/league_analytics.dart';
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
        return _LeagueDashboard(
          token: token ?? '',
          snapshotRaw: snapshotRaw,
          onSessionUpdated: () => setState(() => _refreshKey++),
        );
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
                'Accede con tu cuenta para elegir liga, ver su evolución y consultar el medallero.',
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
                        builder: (_) => const FantasyLoginScreen(),
                      ),
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

class _LeagueDashboard extends ConsumerStatefulWidget {
  const _LeagueDashboard({
    required this.token,
    required this.snapshotRaw,
    required this.onSessionUpdated,
  });

  final String token;
  final String? snapshotRaw;
  final VoidCallback onSessionUpdated;

  @override
  ConsumerState<_LeagueDashboard> createState() => _LeagueDashboardState();
}

class _LeagueDashboardState extends ConsumerState<_LeagueDashboard> {
  late Future<Map<String, dynamic>> _request;
  Map<String, dynamic>? _snapshot;
  String? _selectedLeagueId;

  @override
  void initState() {
    super.initState();
    _readSnapshot(widget.snapshotRaw);
    _load();
  }

  void _readSnapshot(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      _snapshot = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _snapshot = null;
    }
  }

  void _load() {
    final cachedLeagues = _snapshot?['leagues'];
    if (cachedLeagues is Map) {
      _request = Future.value(Map<String, dynamic>.from(cachedLeagues));
      return;
    }
    final api = ref.read(fantasyApiProvider);
    final season = ref.read(currentSeasonProvider);
    _request = api.getLeagueEntrants(
      season: season,
      bearerToken: widget.token,
    );
  }

  Future<void> _captureHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FantasyLoginScreen()),
    );
    if (!mounted) return;
    widget.onSessionUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (requestSnapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              StatusBanner(
                message:
                    'No se pudieron cargar tus ligas. Vuelve a conectar la cuenta.',
                isError: true,
                onRetry: _captureHistory,
              ),
            ],
          );
        }

        final leagues = _extractLeagues(requestSnapshot.data);
        if (leagues.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              StatusBanner(
                message: 'La cuenta no devolvió ligas privadas.',
                onRetry: _captureHistory,
              ),
            ],
          );
        }

        final ids = leagues.map(_leagueId).whereType<String>().toList();
        if (_selectedLeagueId == null || !ids.contains(_selectedLeagueId)) {
          _selectedLeagueId = ids.firstOrNull;
        }
        final selectedId = _selectedLeagueId;
        final analytics = selectedId == null || _snapshot == null
            ? const LeagueAnalytics(events: [], members: [])
            : LeagueAnalytics.fromSnapshot(_snapshot!, selectedId);
        final selectedLeague = leagues.firstWhere(
          (league) => _leagueId(league) == selectedId,
          orElse: () => leagues.first,
        );

        return RefreshIndicator(
          color: AppColors.lime,
          onRefresh: _captureHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            children: [
              const SectionHead(
                kicker: 'Competición',
                title: 'Tu liga F1',
              ),
              const SizedBox(height: 6),
              Text(
                leagues.length == 1
                    ? 'Tienes una liga capturada.'
                    : 'Tienes ${leagues.length} ligas. Elige cuál quieres analizar.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _LeagueSelector(
                leagues: leagues,
                selectedId: selectedId,
                onChanged: (id) => setState(() => _selectedLeagueId = id),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _captureHistory,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('ACTUALIZAR LIGAS E HISTORIAL'),
              ),
              const SizedBox(height: 18),
              if (analytics.members.isEmpty)
                StatusBanner(
                  message:
                      'Esta captura aún no incluye el historial por GP. Pulsa actualizar para añadir gráficas y medallero.',
                  onRetry: _captureHistory,
                )
              else ...[
                _LeagueSummary(
                  name: _leagueName(selectedLeague),
                  analytics: analytics,
                ),
                const SizedBox(height: 20),
                _CurrentStandings(analytics: analytics),
                const SizedBox(height: 22),
                _TrendSection(analytics: analytics),
                const SizedBox(height: 22),
                _MedalTable(analytics: analytics),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LeagueSelector extends StatelessWidget {
  const _LeagueSelector({
    required this.leagues,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> leagues;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return RefCard(
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedId),
        initialValue: selectedId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Liga activa',
          prefixIcon: Icon(Icons.emoji_events_rounded),
        ),
        items: [
          for (final league in leagues)
            if (_leagueId(league) case final id?)
              DropdownMenuItem(
                value: id,
                child: Text(
                  _leagueName(league),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _LeagueSummary extends StatelessWidget {
  const _LeagueSummary({required this.name, required this.analytics});

  final String name;
  final LeagueAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Kicker('Liga seleccionada'),
          const SizedBox(height: 5),
          Text(name, style: AppText.syne(24)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TagChip('${analytics.members.length} equipos',
                  color: AppColors.lime),
              TagChip('${analytics.events.length} GP', color: AppColors.cyan),
              if (analytics.hasHistory)
                const TagChip('Historial completo', color: AppColors.ok),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentStandings extends StatelessWidget {
  const _CurrentStandings({required this.analytics});

  final LeagueAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHead(kicker: 'Ahora', title: 'Clasificación'),
        const SizedBox(height: 10),
        for (var i = 0; i < analytics.members.length; i++) ...[
          RefCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#${analytics.members[i].currentRank ?? i + 1}',
                    style: AppText.mono(11, color: _rankColor(i + 1)),
                  ),
                ),
                Expanded(
                  child: Text(
                    analytics.members[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${_formatPoints(analytics.members[i].currentTotal ?? _lastValue(analytics.members[i].cumulativePoints))} pts',
                  style: AppText.mono(10, color: AppColors.cyan),
                ),
              ],
            ),
          ),
          if (i != analytics.members.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.analytics});

  final LeagueAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHead(
          kicker: 'Campeonato',
          title: 'Evolución por GP',
        ),
        const SizedBox(height: 5),
        Text(
          analytics.hasHistory
              ? 'Puntos acumulados y posición de cada equipo.'
              : 'Se necesitan dos GPs capturados para dibujar una tendencia.',
          style: AppText.body(12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        _LeagueChartCard(
          title: 'Puntos de Fantasy',
          analytics: analytics,
          positions: false,
        ),
        const SizedBox(height: 12),
        _LeagueChartCard(
          title: 'Posición en la liga',
          analytics: analytics,
          positions: true,
        ),
      ],
    );
  }
}

class _LeagueChartCard extends StatelessWidget {
  const _LeagueChartCard({
    required this.title,
    required this.analytics,
    required this.positions,
  });

  final String title;
  final LeagueAnalytics analytics;
  final bool positions;

  static const colors = [
    AppColors.lime,
    AppColors.cyan,
    AppColors.magenta,
    AppColors.violet,
    AppColors.orange,
    AppColors.ok,
  ];

  @override
  Widget build(BuildContext context) {
    final members = analytics.members.take(colors.length).toList();
    return RefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body(14, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              for (var i = 0; i < members.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      members[i].name,
                      style: AppText.body(10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: LineChart(_chartData(members)),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<LeagueMemberTrend> members) {
    final maxPosition = math.max(1, analytics.members.length);
    final allPointValues = members
        .expand((member) => member.cumulativePoints)
        .whereType<double>()
        .toList();
    final pointMax =
        allPointValues.isEmpty ? 1.0 : allPointValues.reduce(math.max) * 1.08;
    return LineChartData(
      minX: 0,
      maxX: math.max(1, analytics.events.length - 1).toDouble(),
      minY: positions ? 1 : 0,
      maxY: positions ? maxPosition.toDouble() : math.max(1, pointMax),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.border1,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (value, meta) {
              final text = positions
                  ? 'P${maxPosition + 1 - value.round()}'
                  : value.round().toString();
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  text,
                  style: AppText.mono(8, color: AppColors.textTertiary),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval:
                math.max(1, (analytics.events.length / 4).ceil()).toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= analytics.events.length) {
                return const SizedBox.shrink();
              }
              final label = analytics.events[index].label;
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  label.length > 7 ? label.substring(0, 7) : label,
                  style: AppText.mono(8, color: AppColors.textTertiary),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        for (var i = 0; i < members.length; i++)
          LineChartBarData(
            spots: [
              for (var eventIndex = 0;
                  eventIndex < analytics.events.length;
                  eventIndex++)
                if ((positions
                        ? members[i].positions[eventIndex]?.toDouble()
                        : members[i].cumulativePoints[eventIndex])
                    case final value?)
                  FlSpot(
                    eventIndex.toDouble(),
                    positions ? maxPosition + 1 - value : value,
                  ),
            ],
            color: colors[i],
            barWidth: 2.4,
            isCurved: true,
            dotData: FlDotData(show: analytics.events.length <= 8),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }
}

class _MedalTable extends StatelessWidget {
  const _MedalTable({required this.analytics});

  final LeagueAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final rows = [...analytics.members]..sort((a, b) {
        final gold = b.gold.compareTo(a.gold);
        if (gold != 0) return gold;
        final silver = b.silver.compareTo(a.silver);
        if (silver != 0) return silver;
        return b.bronze.compareTo(a.bronze);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHead(kicker: 'Palmarés', title: 'Medallero'),
        const SizedBox(height: 5),
        Text(
          'Podios conseguidos por puntos en cada Gran Premio.',
          style: AppText.body(12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        RefCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Kicker('Equipo')),
                  _medalHeader('1º', AppColors.gold),
                  _medalHeader('2º', AppColors.silver),
                  _medalHeader('3º', AppColors.orange),
                ],
              ),
              const Divider(height: 20),
              for (var i = 0; i < rows.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12, weight: FontWeight.w700),
                      ),
                    ),
                    _medalValue(rows[i].gold, AppColors.gold),
                    _medalValue(rows[i].silver, AppColors.silver),
                    _medalValue(rows[i].bronze, AppColors.orange),
                  ],
                ),
                if (i != rows.length - 1) const Divider(height: 18),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _medalHeader(String text, Color color) => SizedBox(
        width: 42,
        child: Text(text,
            textAlign: TextAlign.center, style: AppText.mono(9, color: color)),
      );

  Widget _medalValue(int value, Color color) => SizedBox(
        width: 42,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: AppText.syne(17, color: color),
        ),
      );
}

List<Map<String, dynamic>> _extractLeagues(dynamic node) {
  const preferred = {
    'leagues',
    'league_entrants',
    'results',
    'details',
    'value',
    'leaguesdata',
  };
  if (node is Map) {
    for (final entry in node.entries) {
      if (preferred.contains(entry.key.toString().toLowerCase()) &&
          entry.value is List) {
        final rows = (entry.value as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        if (rows.isNotEmpty) return rows;
      }
    }
    for (final value in node.values) {
      final rows = _extractLeagues(value);
      if (rows.isNotEmpty) return rows;
    }
  }
  return const [];
}

String? _leagueId(Map<String, dynamic> league) => _first(league, const [
      'league_id',
      'leagueid',
      'id',
    ])?.toString();

String _leagueName(Map<String, dynamic> league) => _decode(
      (_first(league, const [
                'league_name',
                'leaguename',
                'name',
                'display_name',
              ]) ??
              'Liga')
          .toString(),
    );

dynamic _first(Map map, List<String> keys) {
  final wanted = keys.map((key) => key.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (!wanted.contains(entry.key.toString().toLowerCase())) continue;
    final value = entry.value;
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}

String _decode(String value) {
  try {
    return Uri.decodeComponent(value.replaceAll('+', ' '));
  } catch (_) {
    return value;
  }
}

Color _rankColor(int rank) => switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.orange,
      _ => AppColors.lime,
    };

double? _lastValue(List<double?> values) {
  for (final value in values.reversed) {
    if (value != null) return value;
  }
  return null;
}

String _formatPoints(double? value) {
  if (value == null) return '—';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
