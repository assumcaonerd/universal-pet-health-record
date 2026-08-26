import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/pet.dart';

class SyncConflict {
  const SyncConflict({required this.event, required this.reason, this.serverVersion});
  final PendingSyncEvent event;
  final String reason;
  final int? serverVersion;
}

class SyncResult {
  const SyncResult({required this.sent, required this.remaining, required this.conflicts});
  final int sent;
  final int remaining;
  final List<SyncConflict> conflicts;
}

class OfflineSyncService {
  OfflineSyncService(this.api, this.store);
  final ApiClient api;
  final OfflineStore store;

  Future<void> queuePetUpdate(Pet pet, Map<String, dynamic> payload) async {
    final deviceId = await store.deviceId();
    await store.enqueue(PendingSyncEvent(
      clientEventId: const Uuid().v4(),
      deviceId: deviceId,
      entityType: 'Pet',
      entityId: pet.id,
      operation: 'UPDATE',
      version: pet.version + 1,
      payload: payload,
    ));
    await store.upsertCachedPet(pet.copyWith(
      name: payload['name'] as String?,
      species: payload['species'] as String?,
      breed: payload['breed'] as String?,
      birthDate: payload['birthDate'] is String ? DateTime.tryParse(payload['birthDate'] as String) : pet.birthDate,
      microchip: payload['microchip'] as String?,
      version: pet.version + 1,
    ));
  }

  Future<SyncResult> flush() async {
    final pending = await store.queue();
    final remaining = <PendingSyncEvent>[];
    final conflicts = <SyncConflict>[];
    var sent = 0;

    for (final event in pending) {
      try {
        final response = await api.post('/sync/push', event.toJson(), authenticated: true);
        if (response['conflict'] == true) {
          conflicts.add(SyncConflict(
            event: event,
            reason: response['reason'] as String? ?? 'UNKNOWN_CONFLICT',
            serverVersion: (response['serverVersion'] as num?)?.toInt(),
          ));
          remaining.add(event);
        } else if (response['accepted'] == true || response['duplicate'] == true) {
          sent++;
        } else {
          remaining.add(event);
        }
      } catch (_) {
        remaining.add(event);
      }
    }

    await store.replaceQueue(remaining);
    return SyncResult(sent: sent, remaining: remaining.length, conflicts: conflicts);
  }
}
