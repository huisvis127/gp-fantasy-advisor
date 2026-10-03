import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/prediction.dart';
import 'constants.dart';
import 'providers.dart';

class FantasyAssetInfo {
  const FantasyAssetInfo({
    required this.id,
    required this.name,
    required this.teamName,
    required this.position,
    required this.seasonPoints,
    required this.wins,
    required this.priceMillions,
    required this.expectedPoints,
    required this.kind,
  });

  final String id;
  final String name;
  final String teamName;
  final int position;
  final double seasonPoints;
  final int wins;
  final double priceMillions;
  final double expectedPoints;
  final FantasyAssetKind kind;

  AssetPrediction toPrediction() {
    final rankScore = (100 - (position - 1) * 4.5).clamp(0, 100).toDouble();
    final formScore = (expectedPoints * 4).clamp(0, 100).toDouble();
    return AssetPrediction(
      assetId: id,
      expectedPoints: expectedPoints,
      winProbability:
          wins > 0 ? (0.05 + wins * 0.03).clamp(0, 0.55).toDouble() : 0.01,
      podiumProbability: (rankScore / 120).clamp(0, 0.85).toDouble(),
      top10Probability: kind == FantasyAssetKind.driver
          ? (position <= 10 ? 0.78 : 0.35).toDouble()
          : 1,
      priceMillions: priceMillions,
      breakdown: {
        'forma_2026': formScore,
        'clasificacion_2026': rankScore,
        'valor': (expectedPoints / priceMillions * 18).clamp(0, 100).toDouble(),
      },
    );
  }
}

enum FantasyAssetKind { driver, constructor }

final fantasyDriverAssetInfoProvider =
    FutureProvider<List<FantasyAssetInfo>>((ref) async {
  final json = await _loadJsonWithFallback(
    ref,
    'https://api.jolpi.ca/ergast/f1/2026/driverStandings.json',
    AssetPaths.driverStandingsFallback,
  );
  final standings =
      json['MRData']?['StandingsTable']?['StandingsLists'] as List<dynamic>? ??
          [];
  final round =
      int.tryParse(standings.firstOrNull?['round']?.toString() ?? '') ?? 9;
  final rows =
      standings.firstOrNull?['DriverStandings'] as List<dynamic>? ?? [];
  final maxPoints = rows
      .map((r) => double.tryParse(r['points']?.toString() ?? '') ?? 0)
      .fold<double>(0, math.max);

  return rows.map((raw) {
    final row = raw as Map<String, dynamic>;
    final driver = row['Driver'] as Map<String, dynamic>;
    final constructors = row['Constructors'] as List<dynamic>? ?? const [];
    final constructor = constructors.isEmpty
        ? const <String, dynamic>{}
        : constructors.first as Map<String, dynamic>;
    final points = double.tryParse(row['points']?.toString() ?? '') ?? 0;
    final position = int.tryParse(row['position']?.toString() ?? '') ?? 99;
    final wins = int.tryParse(row['wins']?.toString() ?? '') ?? 0;
    final id = driver['driverId'].toString();
    final name =
        '${driver['givenName'] ?? ''} ${driver['familyName'] ?? ''}'.trim();
    final baseExpected = round <= 0 ? points : points / round;
    return FantasyAssetInfo(
      id: id,
      name: name.isEmpty ? id : name,
      teamName: constructor['name']?.toString() ?? '',
      position: position,
      seasonPoints: points,
      wins: wins,
      priceMillions: _driverPrice(points, maxPoints, position),
      expectedPoints: (baseExpected + wins * 0.7).clamp(1, 35).toDouble(),
      kind: FantasyAssetKind.driver,
    );
  }).toList();
});

final fantasyConstructorAssetInfoProvider =
    FutureProvider<List<FantasyAssetInfo>>((ref) async {
  final json = await _loadJsonWithFallback(
    ref,
    'https://api.jolpi.ca/ergast/f1/2026/constructorStandings.json',
    AssetPaths.constructorStandingsFallback,
  );
  final standings =
      json['MRData']?['StandingsTable']?['StandingsLists'] as List<dynamic>? ??
          [];
  final round =
      int.tryParse(standings.firstOrNull?['round']?.toString() ?? '') ?? 9;
  final rows =
      standings.firstOrNull?['ConstructorStandings'] as List<dynamic>? ?? [];
  final maxPoints = rows
      .map((r) => double.tryParse(r['points']?.toString() ?? '') ?? 0)
      .fold<double>(0, math.max);

  return rows.map((raw) {
    final row = raw as Map<String, dynamic>;
    final constructor = row['Constructor'] as Map<String, dynamic>;
    final points = double.tryParse(row['points']?.toString() ?? '') ?? 0;
    final position = int.tryParse(row['position']?.toString() ?? '') ?? 99;
    final wins = int.tryParse(row['wins']?.toString() ?? '') ?? 0;
    final id = constructor['constructorId'].toString();
    final name = constructor['name']?.toString() ?? id;
    final baseExpected = round <= 0 ? points : points / round;
    return FantasyAssetInfo(
      id: id,
      name: name,
      teamName: name,
      position: position,
      seasonPoints: points,
      wins: wins,
      priceMillions: _constructorPrice(points, maxPoints, position),
      expectedPoints: (baseExpected + wins * 0.8).clamp(2, 50).toDouble(),
      kind: FantasyAssetKind.constructor,
    );
  }).toList();
});

final fallbackDriverPredictionsProvider =
    FutureProvider<List<AssetPrediction>>((ref) async {
  final rows = await ref.watch(fantasyDriverAssetInfoProvider.future);
  return rows.map((r) => r.toPrediction()).toList();
});

final constructorPredictionsProvider =
    FutureProvider<List<AssetPrediction>>((ref) async {
  final rows = await ref.watch(fantasyConstructorAssetInfoProvider.future);
  return rows.map((r) => r.toPrediction()).toList();
});

final fantasyAssetNameProvider =
    FutureProvider<Map<String, FantasyAssetInfo>>((ref) async {
  final drivers = await ref.watch(fantasyDriverAssetInfoProvider.future);
  final constructors =
      await ref.watch(fantasyConstructorAssetInfoProvider.future);
  return {
    for (final row in [...drivers, ...constructors]) row.id: row
  };
});

Future<Map<String, dynamic>> _loadJsonWithFallback(
  Ref ref,
  String url,
  String fallbackAsset,
) async {
  try {
    final response = await ref.watch(dioProvider).get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
    if (response.statusCode == 200 && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
  } catch (_) {
    // Sigue con el asset empaquetado.
  }
  final raw = await rootBundle.loadString(fallbackAsset);
  return jsonDecode(raw) as Map<String, dynamic>;
}

double _driverPrice(double points, double maxPoints, int position) {
  if (maxPoints <= 0) return 5;
  final score = points / maxPoints;
  final rankPenalty = math.max(0, position - 1) * 0.22;
  return (4.0 + score * 26.0 - rankPenalty).clamp(4.0, 31.0).toDouble();
}

double _constructorPrice(double points, double maxPoints, int position) {
  if (maxPoints <= 0) return 6;
  final score = points / maxPoints;
  final rankPenalty = math.max(0, position - 1) * 0.35;
  return (6.0 + score * 22.0 - rankPenalty).clamp(6.0, 30.0).toDouble();
}
