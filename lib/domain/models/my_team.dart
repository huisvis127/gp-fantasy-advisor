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

  /// Suma la proyección de los siete activos y aplica el Boost ×2 al piloto
  /// importado/guardado. Si la captura no trae capitán, se puede pasar el
  /// piloto recomendado como respaldo visible en la UI.
  double projectedPoints(
    Map<String, double> expectedPointsByAsset, {
    String? suggestedBoostedDriverId,
  }) {
    final assets = [...driverIds, ...constructorIds];
    final base = assets.fold<double>(
      0,
      (sum, id) => sum + (expectedPointsByAsset[id] ?? 0),
    );
    final boostId =
        boostedDriverId != null && driverIds.contains(boostedDriverId)
        ? boostedDriverId
        : suggestedBoostedDriverId != null &&
              driverIds.contains(suggestedBoostedDriverId)
        ? suggestedBoostedDriverId
        : null;
    return base + (boostId == null ? 0 : expectedPointsByAsset[boostId] ?? 0);
  }

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
