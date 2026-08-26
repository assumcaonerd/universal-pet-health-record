import '../core/offline_store.dart';
import '../models/care_reminder.dart';
import '../models/pet.dart';

class ReminderService {
  ReminderService(this.store);
  final OfflineStore store;

  Future<List<CareReminder>> upcoming(List<Pet> pets, {DateTime? now, int horizonDays = 45}) async {
    final clock = now ?? DateTime.now();
    final horizon = clock.add(Duration(days: horizonDays));
    final reminders = <CareReminder>[];

    for (final pet in pets) {
      final snapshot = await store.loadClinicalSnapshot(pet.id);
      if (snapshot == null) continue;

      for (final raw in snapshot.vaccinations) {
        final vaccine = Map<String, dynamic>.from(raw as Map);
        final due = DateTime.tryParse(vaccine['nextDueDate'] as String? ?? '');
        if (due == null || due.isAfter(horizon)) continue;
        final sourceId = vaccine['id'] as String? ?? '${vaccine['vaccineName']}-${due.toIso8601String()}';
        reminders.add(CareReminder(
          id: 'vaccine:$sourceId',
          petId: pet.id,
          petName: pet.name,
          kind: CareReminderKind.vaccine,
          title: 'Vacina: ${vaccine['vaccineName'] ?? 'próxima dose'}',
          dueAt: due,
          sourceId: sourceId,
          detail: vaccine['batchNumber'] == null ? null : 'Lote ${vaccine['batchNumber']}',
        ));
      }

      for (final prescription in snapshot.prescriptions) {
        final start = prescription.startsAt;
        final end = prescription.endsAt;
        final interval = prescription.intervalMinutes;
        if (start == null || interval == null || interval <= 0) continue;

        var doseAt = start;
        final hardStop = end == null || end.isAfter(horizon) ? horizon : end;
        var generated = 0;
        while (!doseAt.isAfter(hardStop) && generated < 256) {
          if (!doseAt.isBefore(clock.subtract(const Duration(hours: 24)))) {
            reminders.add(CareReminder(
              id: 'medication:${prescription.id}:${doseAt.toIso8601String()}',
              petId: pet.id,
              petName: pet.name,
              kind: CareReminderKind.medication,
              title: '${prescription.medication} • ${prescription.dosage}',
              dueAt: doseAt,
              sourceId: prescription.id,
              detail: prescription.instructions?.isNotEmpty == true ? prescription.instructions : prescription.frequency,
            ));
          }
          doseAt = doseAt.add(Duration(minutes: interval));
          generated++;
        }
      }

      for (final record in snapshot.records) {
        final due = record.followUpAt;
        if (due == null || due.isAfter(horizon) || due.isBefore(clock.subtract(const Duration(days: 7)))) continue;
        reminders.add(CareReminder(
          id: 'followup:${record.id}',
          petId: pet.id,
          petName: pet.name,
          kind: CareReminderKind.followUp,
          title: 'Retorno veterinário',
          dueAt: due,
          sourceId: record.id,
          detail: record.diagnosis?.isNotEmpty == true ? record.diagnosis : record.type,
        ));
      }
    }

    reminders.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return reminders;
  }
}
