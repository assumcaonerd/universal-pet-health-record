import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pet_health_record/models/adherence_summary.dart';

void main() {
  test('adherence summary separates on-time and late taken doses', () {
    final summary = AdherenceSummary.fromJson({
      'prescriptionId': 'rx1',
      'recorded': 3,
      'taken': 2,
      'skipped': 1,
      'adherencePercent': 66.7,
      'events': [
        {'id': 'e1', 'scheduledAt': '2026-08-26T10:00:00Z', 'administeredAt': '2026-08-26T10:10:00Z', 'status': 'TAKEN'},
        {'id': 'e2', 'scheduledAt': '2026-08-26T22:00:00Z', 'administeredAt': '2026-08-26T22:45:00Z', 'status': 'TAKEN'},
        {'id': 'e3', 'scheduledAt': '2026-08-27T10:00:00Z', 'administeredAt': null, 'status': 'SKIPPED'},
      ],
    });
    expect(summary.onTimeTaken, 1);
    expect(summary.lateTaken, 1);
    expect(summary.skipped, 1);
    expect(summary.adherencePercent, 66.7);
  });
}
