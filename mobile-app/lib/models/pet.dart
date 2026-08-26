class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.microchip,
    this.version = 1,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final DateTime? birthDate;
  final String? microchip;
  final int version;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        breed: json['breed'] as String?,
        birthDate: json['birthDate'] == null ? null : DateTime.tryParse(json['birthDate'] as String),
        microchip: json['microchip'] as String?,
        version: (json['version'] as num?)?.toInt() ?? 1,
      );
}
