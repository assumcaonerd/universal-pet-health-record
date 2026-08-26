import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/models/clinical_attachment.dart';

void main() {
  test('parses clinical attachment metadata and medical record link', () {
    final attachment = ClinicalAttachment.fromJson({
      'id': 'a1',
      'petId': 'p1',
      'medicalRecordId': 'r1',
      'fileName': 'hemograma.pdf',
      'mimeType': 'application/pdf',
      'storageKey': 'pets/p1/clinical/a1-hemograma.pdf',
      'sha256': 'a' * 64,
      'sizeBytes': 2048,
      'createdAt': '2026-08-26T12:00:00.000Z',
    });

    expect(attachment.fileName, 'hemograma.pdf');
    expect(attachment.medicalRecordId, 'r1');
    expect(attachment.sizeBytes, 2048);
    expect(attachment.sha256.length, 64);
  });
}
