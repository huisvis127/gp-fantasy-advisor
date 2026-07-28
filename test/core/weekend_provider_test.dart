import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/weekend_provider.dart';
import 'package:gp_fantasy_advisor/domain/models/race.dart';

Race _race(DateTime date) => Race(
      season: 2026,
      round: 8,
      raceName: 'GP de prueba',
      circuitId: 'test',
      circuitName: 'Test',
      country: 'Spain',
      date: date,
    );

void main() {
  test('solo reconoce libres; rechaza Qualifying y Sprint Qualifying', () {
    expect(practiceSessionKeyOf('Practice 1'), 'fp1');
    expect(practiceSessionKeyOf('Practice 2'), 'fp2');
    expect(practiceSessionKeyOf('Practice 3'), 'fp3');
    expect(practiceSessionKeyOf('Qualifying'), isNull);
    expect(practiceSessionKeyOf('Sprint Qualifying'), isNull);
    expect(practiceSessionKeyOf('Sprint Shootout'), isNull);
  });

  test('separa la foto del viernes de la de viernes más sábado', () {
    const weekend = WeekendData(
      sessions: {'fp1', 'fp2', 'fp3'},
      byDriverId: {
        'driver': {
          'pace:fp1': 1,
          'pace:fp2': 2,
          'pace:fp3': 3,
          'pace:quali': 99,
        },
      },
    );

    expect(
      weekend.sessionsFor(PredictionDataWindow.friday),
      {'fp1', 'fp2'},
    );
    expect(
      weekend.byDriverIdFor(PredictionDataWindow.friday)['driver'],
      {'pace:fp1': 1, 'pace:fp2': 2},
    );
    expect(
      weekend.byDriverIdFor(PredictionDataWindow.saturday)['driver'],
      {'pace:fp1': 1, 'pace:fp2': 2, 'pace:fp3': 3},
    );
  });

  test('en Sprint no ofrece ventana del sábado', () {
    const weekend = WeekendData(
      sessions: {'fp1', 'fp3'},
      isSprintWeekend: true,
    );

    expect(
      weekend.isWindowAvailable(PredictionDataWindow.saturday),
      isFalse,
    );
    expect(
      weekend.latestAvailableWindow,
      PredictionDataWindow.friday,
    );
  });

  test('consulta sesiones archivadas para una carrera anterior', () {
    expect(
      shouldLoadWeekendData(
        _race(DateTime(2026, 6, 7, 15)),
        DateTime(2026, 6, 8, 9),
      ),
      isTrue,
    );
  });

  test('consulta desde tres días antes y durante el día de carrera', () {
    final race = _race(DateTime(2026, 6, 7, 15));
    expect(
      shouldLoadWeekendData(race, DateTime(2026, 6, 4, 16)),
      isTrue,
    );
    expect(
      shouldLoadWeekendData(race, DateTime(2026, 6, 7, 18)),
      isTrue,
    );
  });

  test('no consulta una carrera futura cuyo fin de semana no ha empezado', () {
    expect(
      shouldLoadWeekendData(
        _race(DateTime(2026, 6, 7, 15)),
        DateTime(2026, 6, 3, 12),
      ),
      isFalse,
    );
  });
}
