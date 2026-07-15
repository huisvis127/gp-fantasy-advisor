import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants.dart';

/// El JSON crudo de la tabla de puntuación (no el objeto `ScoringTable`)
/// porque `Isolate.run` necesita un valor "sendable"; el `Map<String,dynamic>`
/// se reconstruye en `ScoringTable.fromJson` dentro del Isolate
/// (ver domain/engine/isolate_runner.dart).
final scoringJsonProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await rootBundle.loadString(AssetPaths.scoringTable);
  return jsonDecode(raw) as Map<String, dynamic>;
});
