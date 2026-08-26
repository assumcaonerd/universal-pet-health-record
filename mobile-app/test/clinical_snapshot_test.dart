import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/core/offline_store.dart';
import 'package:universal_pet_health_record/models/clinical_models.dart';

void main() {
  test('clinical snapshot preserves essential offline record', () {
    final snapshot = ClinicalSnapshot(
      petId: 'pet-1',
      savedAt: DateTime.utc(2026, 8, 26, 12),
      vaccinations: [
        {'vaccineName': 'Antirrábica', 'dateAdministered': '2026-08-20T00:00:00.000Z'},
      ],
      prescriptions: [
        Prescription(id: 'rx-1', medication: 'Medicamento', dosage: '10 mg', frequency: '12/12h', prescribedAt: DateTime.utc(2026, 8, 20)),
      ],
      allergies: [
        Allergy(id: 'a-1', allergen: 'Abelha', severity: 'SEVERE', active: true, createdAt: DateTime.utc(2026, 8, 20)),
      ],
      records: [
        MedicalRecord(id: 'm-1', type: 'Consulta', occurredAt: DateTime.utc(2026, 8, 20), currentVersion: 1, versions: const []),
      ],
    );

    final restored = ClinicalSnapshot.fromJson(snapshot.toJson());
    expect(restored.petId, 'pet-1');
    expect(restored.vaccinations.first['vaccineName'], 'Antirrábica');
    expect(restored.prescriptions.first.dosage, '10 mg');
    expect(restored.allergies.first.severity, 'SEVERE');
    expect(restored.records.first.type, 'Consulta');
  });
}
