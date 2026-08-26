import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/models/care_reminder.dart';

void main() {
  test('care reminder serializes and restores vaccine due date', () {
    final due = DateTime.utc(2026, 9, 10, 12);
    final reminder = CareReminder(id: 'vaccine:v1', petId: 'p1', petName: 'Zoe', kind: CareReminderKind.vaccine, title: 'Vacina: V10', dueAt: due, sourceId: 'v1');
    final restored = CareReminder.fromJson(reminder.toJson());
    expect(restored.kind, CareReminderKind.vaccine);
    expect(restored.petName, 'Zoe');
    expect(restored.dueAt, due);
  });
}
