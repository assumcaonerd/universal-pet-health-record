import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/models/clinical_models.dart';

void main() {
  test('parses prescription payload', () {
    final value = Prescription.fromJson({
      'id': 'rx1',
      'medication': 'Amoxicilina',
      'dosage': '10 mg',
      'frequency': '12/12h',
      'duration': '7 dias',
      'prescribedAt': '2026-08-26T12:00:00.000Z',
    });
    expect(value.medication, 'Amoxicilina');
    expect(value.frequency, '12/12h');
    expect(value.duration, '7 dias');
  });

  test('parses active life threatening allergy', () {
    final value = Allergy.fromJson({
      'id': 'a1',
      'allergen': 'Penicilina',
      'severity': 'LIFE_THREATENING',
      'active': true,
      'createdAt': '2026-08-26T12:00:00.000Z',
    });
    expect(value.allergen, 'Penicilina');
    expect(value.severity, 'LIFE_THREATENING');
    expect(value.active, isTrue);
  });

  test('preserves medical record version history', () {
    final record = MedicalRecord.fromJson({
      'id': 'm1',
      'type': 'Consulta',
      'diagnosis': 'Dermatite',
      'occurredAt': '2026-08-20T12:00:00.000Z',
      'currentVersion': 2,
      'versions': [
        {'version': 1, 'diagnosis': 'Alergia', 'reason': 'Initial clinical record', 'createdAt': '2026-08-20T12:00:00.000Z'},
        {'version': 2, 'diagnosis': 'Dermatite', 'reason': 'Correção após exame', 'createdAt': '2026-08-21T12:00:00.000Z'},
      ],
    });
    expect(record.currentVersion, 2);
    expect(record.versions, hasLength(2));
    expect(record.versions.last.reason, 'Correção após exame');
  });
}
