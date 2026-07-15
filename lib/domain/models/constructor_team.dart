/// Se llama `ConstructorTeam` (no `Constructor`) para no chocar con la
/// palabra reservada de Dart en constructores de clase.
class ConstructorTeam {
  const ConstructorTeam({
    required this.id,
    required this.name,
    required this.nationality,
  });

  final String id; // ej. "red_bull"
  final String name;
  final String nationality;

  factory ConstructorTeam.fromJolpica(Map<String, dynamic> json) {
    return ConstructorTeam(
      id: json['constructorId'] as String,
      name: json['name'] as String,
      nationality: (json['nationality'] as String?) ?? '',
    );
  }
}
