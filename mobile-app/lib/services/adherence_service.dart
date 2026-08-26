import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../models/adherence_summary.dart';
import '../models/care_reminder.dart';

class AdherenceService {
  AdherenceService(this.api);
  final ApiClient api;
  static const _uuid = Uuid();

  Future<Map<String, dynamic>> record(CareReminder reminder, {required bool taken, DateTime? administeredAt, String? note}) {
    if (reminder.kind != CareReminderKind.medication) throw ArgumentError('Only medication reminders can record adherence');
    return api.post('/pets/${reminder.petId}/prescriptions/${reminder.sourceId}/adherence', {
      'scheduledAt': reminder.dueAt.toUtc().toIso8601String(),
      'status': taken ? 'TAKEN' : 'SKIPPED',
      if (taken) 'administeredAt': (administeredAt ?? DateTime.now()).toUtc().toIso8601String(),
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      'clientEventId': _uuid.v4(),
    }, authenticated: true);
  }

  Future<AdherenceSummary> summary(String petId, String prescriptionId) async {
    final json = await api.getObject('/pets/$petId/prescriptions/$prescriptionId/adherence');
    return AdherenceSummary.fromJson(json);
  }
}
