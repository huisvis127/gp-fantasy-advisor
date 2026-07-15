class RaceResult {
  const RaceResult({
    required this.season,
    required this.round,
    required this.driverId,
    required this.constructorId,
    required this.gridPosition,
    required this.finishPosition,
    required this.status,
    this.fastestLap = false,
  });

  final int season;
  final int round;
  final String driverId;
  final String constructorId;
  final int gridPosition;
  final int? finishPosition; // null si DNF/DSQ
  final String status; // "Finished", "+1 Lap", "Accident", ...
  final bool fastestLap;

  bool get isDnf => finishPosition == null && !status.contains('Lap');

  factory RaceResult.fromJolpica(
    Map<String, dynamic> json,
    int season,
    int round,
  ) {
    final driver = json['Driver'] as Map<String, dynamic>;
    final constructor = json['Constructor'] as Map<String, dynamic>;
    final status = json['status'] as String;
    final posText = json['position'] as String?;
    return RaceResult(
      season: season,
      round: round,
      driverId: driver['driverId'] as String,
      constructorId: constructor['constructorId'] as String,
      gridPosition: int.tryParse(json['grid']?.toString() ?? '') ?? 0,
      finishPosition:
          status == 'Finished' || status.contains('Lap') ? int.tryParse(posText ?? '') : null,
      status: status,
      fastestLap: (json['FastestLap']?['rank'] as String?) == '1',
    );
  }
}
