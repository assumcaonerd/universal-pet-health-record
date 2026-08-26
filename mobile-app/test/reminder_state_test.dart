import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/services/reminder_state_service.dart';

void main() {
  test('completed reminder state survives serialization', () {
    final completedAt = DateTime.utc(2026, 8, 26, 15);
    final state = ReminderState(completedAt: completedAt);
    final restored = ReminderState.fromJson(state.toJson());
    expect(restored.completed, isTrue);
    expect(restored.completedAt, completedAt);
  });

  test('snoozed reminder state preserves next alert time', () {
    final until = DateTime.utc(2026, 8, 27, 9);
    final restored = ReminderState.fromJson(ReminderState(snoozedUntil: until).toJson());
    expect(restored.completed, isFalse);
    expect(restored.snoozedUntil, until);
  });
}
