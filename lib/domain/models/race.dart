class Race {
  const Race({
    required this.season,
    required this.round,
    required this.raceName,
    required this.circuitId,
    required this.circuitName,
    required this.country,
    required this.date,
    this.hasSprint = false,
    this.sessionTimes = const {},
  });

  final int season;
  final int round;
  final String raceName;
  final String circuitId;
  final String circuitName;
  final String country;
  final DateTime date;
  final bool hasSprint;
  final Map<String, DateTime> sessionTimes;

  String get objectiveKey => hasSprint ? 'sprint' : 'race';

  factory Race.fromJolpica(Map<String, dynamic> json) {
    final circuit = json['Circuit'] as Map<String, dynamic>;
    final location = circuit['Location'] as Map<String, dynamic>;

    // Fecha + hora de salida (si Jolpica la da) para la cuenta atrás exacta.
    final dateText = json['date'] as String;
    final timeText = json['time'] as String?;
    final date = timeText == null
        ? DateTime.parse(dateText)
        : DateTime.parse('${dateText}T$timeText').toLocal();
    DateTime? sessionDate(String key) {
      final session = json[key];
      if (session is! Map<String, dynamic>) return null;
      final sessionDay = session['date']?.toString();
      if (sessionDay == null) return null;
      final sessionTime = session['time']?.toString();
      return sessionTime == null
          ? DateTime.parse(sessionDay)
          : DateTime.parse('${sessionDay}T$sessionTime').toLocal();
    }

    final sessions = <String, DateTime>{'race': date};
    const sessionKeys = {
      'FirstPractice': 'fp1',
      'SecondPractice': 'fp2',
      'ThirdPractice': 'fp3',
      'SprintShootout': 'sprint_qualifying',
      'SprintQualifying': 'sprint_qualifying',
      'Sprint': 'sprint',
      'Qualifying': 'qualifying',
    };
    for (final entry in sessionKeys.entries) {
      final value = sessionDate(entry.key);
      if (value != null) sessions[entry.value] = value;
    }

    return Race(
      season: int.parse(json['season'] as String),
      round: int.parse(json['round'] as String),
      raceName: json['raceName'] as String,
      circuitId: circuit['circuitId'] as String,
      circuitName: circuit['circuitName'] as String,
      country: location['country'] as String,
      date: date,
      hasSprint: json.containsKey('Sprint'),
      sessionTimes: sessions,
    );
  }
}
