import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/models/pet.dart';

void main() {
  test('parses pet payload from API', () {
    final pet = Pet.fromJson({
      'id': 'pet-1',
      'name': 'Luna',
      'species': 'DOG',
      'breed': 'Golden Retriever',
      'birthDate': '2024-01-10T00:00:00.000Z',
      'microchip': '123456789',
      'version': 3,
    });

    expect(pet.id, 'pet-1');
    expect(pet.name, 'Luna');
    expect(pet.species, 'DOG');
    expect(pet.version, 3);
    expect(pet.birthDate, isNotNull);
  });
}
