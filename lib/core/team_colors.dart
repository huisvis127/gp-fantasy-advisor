import 'dart:ui';

/// Color de acento por constructor (equivalente a la barra lateral `.bike`
/// de la app de referencia). Colores propios inspirados en las libreas 2026,
/// sin usar marcas registradas.
const Map<String, Color> kTeamColors = {
  'mercedes': Color(0xFF27F4D2),
  'red_bull': Color(0xFF3671C6),
  'ferrari': Color(0xFFE8002D),
  'mclaren': Color(0xFFFF8000),
  'aston_martin': Color(0xFF229971),
  'alpine': Color(0xFF0093CC),
  'williams': Color(0xFF64C4FF),
  'rb': Color(0xFF6692FF),
  'racing_bulls': Color(0xFF6692FF),
  'sauber': Color(0xFF52E252),
  'audi': Color(0xFFA50F2D),
  'haas': Color(0xFFB6BABD),
  'cadillac': Color(0xFFD4AF37),
};

Color teamColor(String? constructorId) {
  if (constructorId == null) return const Color(0xFF9B5CFF);
  final normalized =
      constructorId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final canonical = switch (normalized) {
    'mercedes' => 'mercedes',
    'ferrari' || 'scuderia ferrari' => 'ferrari',
    'mclaren' => 'mclaren',
    'red bull' || 'red bull racing' => 'red_bull',
    'aston martin' || 'aston martin f1 team' => 'aston_martin',
    'alpine' || 'alpine f1 team' => 'alpine',
    'williams' || 'williams racing' => 'williams',
    'rb' || 'rb f1 team' || 'racing bulls' => 'rb',
    'sauber' => 'sauber',
    'audi' => 'audi',
    'haas' || 'haas f1 team' => 'haas',
    'cadillac' || 'cadillac f1 team' => 'cadillac',
    _ => normalized.replaceAll(' ', '_'),
  };
  return kTeamColors[canonical] ?? const Color(0xFF9B5CFF);
}

/// Nombre legible a partir de un id tipo `max_verstappen` cuando no hay
/// catálogo (fallback defensivo).
String prettifyId(String id) {
  return id
      .split('_')
      .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
      .join(' ');
}
