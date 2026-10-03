import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/db/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('persiste equipo, precios y puntos por jornada para hindsight', () async {
    await database.saveTeamSnapshot(TeamSnapshotsCompanion.insert(
      season: 2026,
      round: 10,
      driverIdsCsv: 'd1,d2,d3,d4,d5',
      constructorIdsCsv: 'c1,c2',
      remainingBudgetMillions: 1.5,
      savedAt: DateTime(2026, 7, 1),
    ));
    await database.upsertFantasyPoints([
      FantasyPointsTableCompanion.insert(
        assetId: 'd1',
        assetType: 'driver',
        season: 2026,
        round: 10,
        points: 25,
      ),
    ]);
    await database.upsertPrices([
      FantasyPricesCompanion.insert(
        assetId: 'd1',
        assetType: 'driver',
        season: 2026,
        round: 10,
        priceMillions: 12,
      ),
    ]);

    expect(await database.allTeamSnapshots(), hasLength(1));
    expect(await database.fantasyPointsForRound(2026, 10), hasLength(1));
    expect(await database.pricesForRound(2026, 10), hasLength(1));
  });
}
