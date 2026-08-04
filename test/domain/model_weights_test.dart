import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/model_weights.dart';

void main() {
  const weights = ModelWeights(
    w1RitmoCarrera: .20,
    w2RitmoClasificacion: .32,
    w3VueltaRapida: .24,
    w4Consistencia: .10,
    w5Forma: .04,
    w6AfinidadCircuito: .04,
    w7FormaEquipo: .04,
    w8RiesgoDnf: .02,
    sessionWeightsAfterFp2: {'fp1': .50, 'fp2': .50},
    sessionWeightsAfterFp3: {'fp1': .42, 'fp2': .13, 'fp3': .45},
  );

  test('usa el modelo independiente de FP1 y FP2', () {
    expect(
      weights.sessionWeightsFor(
        isSprint: false,
        availableSessions: {'fp1', 'fp2'},
      ),
      {'fp1': .50, 'fp2': .50},
    );
  });

  test('usa el modelo independiente de las tres libres', () {
    expect(
      weights.sessionWeightsFor(
        isSprint: false,
        availableSessions: {'fp1', 'fp2', 'fp3'},
      ),
      {'fp1': .42, 'fp2': .13, 'fp3': .45},
    );
  });

  test('ignora clasificación y sprint quali', () {
    expect(
      weights.sessionWeightsFor(
        isSprint: false,
        availableSessions: {'fp1', 'fp2', 'fp3', 'quali', 'sq'},
      ),
      {'fp1': .42, 'fp2': .13, 'fp3': .45},
    );
  });
}
