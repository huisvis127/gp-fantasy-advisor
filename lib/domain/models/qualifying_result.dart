class QualifyingResult {
  const QualifyingResult({
    required this.season,
    required this.round,
    required this.driverId,
    required this.position,
    this.q1,
    this.q2,
    this.q3,
  });

  final int season;
  final int round;
  final String driverId;
  final int position;
  final Duration? q1;
  final Duration? q2;
  final Duration? q3;

  bool get reachedQ3 => q3 != null;
  bool get reachedQ2 => q2 != null;

  factory QualifyingResult.fromJolpica(
    Map<String, dynamic> json,
    int season,
    int round,
  ) {
    final driver = json['Driver'] as Map<String, dynamic>;
    return QualifyingResult(
      season: season,
      round: round,
      driverId: driver['driverId'] as String,
      position: int.parse(json['position'] as String),
      q1: _parseLapTime(json['Q1'] as String?),
      q2: _parseLapTime(json['Q2'] as String?),
      q3: _parseLapTime(json['Q3'] as String?),
    );
  }

  static Duration? _parseLapTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = double.tryParse(parts[1]) ?? 0;
    final millis = (seconds * 1000).round();
    return Duration(minutes: minutes, milliseconds: millis - (minutes * 60000));
  }
}
