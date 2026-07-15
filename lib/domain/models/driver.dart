class Driver {
  const Driver({
    required this.id,
    required this.code,
    required this.givenName,
    required this.familyName,
    required this.constructorId,
    required this.number,
  });

  final String id; // ej. "verstappen" (driverId estilo Ergast/Jolpica)
  final String code; // ej. "VER"
  final String givenName;
  final String familyName;
  final String constructorId;
  final int? number;

  String get fullName => '$givenName $familyName';

  factory Driver.fromJolpica(Map<String, dynamic> json, String constructorId) {
    return Driver(
      id: json['driverId'] as String,
      code: (json['code'] as String?) ?? '???',
      givenName: json['givenName'] as String,
      familyName: json['familyName'] as String,
      constructorId: constructorId,
      number: int.tryParse(json['permanentNumber']?.toString() ?? ''),
    );
  }
}
