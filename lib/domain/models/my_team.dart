/// Equipo del usuario: importado (Plan A/B) o introducido a mano (Plan C,
/// sección 3.1). La app trata ambos casos igual una vez rellenado este modelo.
class MyTeam {
  const MyTeam({
    required this.driverIds,
    required this.constructorIds,
    required this.remainingBudgetMillions,
    this.boostedDriverId,
    this.source = MyTeamSource.manual,
    this.chipsUsed = const <String>{},
  });

  final List<String> driverIds; // exactamente 5
  final List<String> constructorIds; // exactamente 2
  final double remainingBudgetMillions;
  final String? boostedDriverId;
  final MyTeamSource source;
  final Set<String> chipsUsed;

  bool get isComplete => driverIds.length == 5 && constructorIds.length == 2;

  MyTeam copyWith({
    List<String>? driverIds,
    List<String>? constructorIds,
    double? remainingBudgetMillions,
    String? boostedDriverId,
    MyTeamSource? source,
    Set<String>? chipsUsed,
  }) {
    return MyTeam(
      driverIds: driverIds ?? this.driverIds,
      constructorIds: constructorIds ?? this.constructorIds,
      remainingBudgetMillions:
          remainingBudgetMillions ?? this.remainingBudgetMillions,
      boostedDriverId: boostedDriverId ?? this.boostedDriverId,
      source: source ?? this.source,
      chipsUsed: chipsUsed ?? this.chipsUsed,
    );
  }
}

enum MyTeamSource { importedApi, importedWebview, manual }
