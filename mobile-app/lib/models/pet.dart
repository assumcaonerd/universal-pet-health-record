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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'birthDate': birthDate?.toIso8601String(),
        'microchip': microchip,
        'version': version,
      };

  Pet copyWith({String? name, String? species, String? breed, DateTime? birthDate, String? microchip, int? version}) => Pet(
        id: id,
        name: name ?? this.name,
        species: species ?? this.species,
        breed: breed ?? this.breed,
        birthDate: birthDate ?? this.birthDate,
        microchip: microchip ?? this.microchip,
        version: version ?? this.version,
      );
}
