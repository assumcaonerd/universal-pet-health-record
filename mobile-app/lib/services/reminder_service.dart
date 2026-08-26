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

      // Prescrições ainda não possuem uma data final estruturada no contrato.
      // Não inferimos vencimento a partir do campo textual "duration" para evitar lembretes clínicos errados.
    }

    reminders.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return reminders;
  }
}
