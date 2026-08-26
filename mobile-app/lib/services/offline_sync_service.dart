import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/pet.dart';
import 'reminder_state_service.dart';

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
    await store.enqueue(PendingSyncEvent(clientEventId: const Uuid().v4(), deviceId: deviceId, entityType: 'Pet', entityId: pet.id, operation: 'UPDATE', version: pet.version + 1, payload: payload));
    final cached = Pet(id: pet.id, name: payload.containsKey('name') ? payload['name'] as String : pet.name, species: payload.containsKey('species') ? payload['species'] as String : pet.species, breed: payload.containsKey('breed') ? payload['breed'] as String? : pet.breed, birthDate: payload.containsKey('birthDate') ? (payload['birthDate'] is String ? DateTime.tryParse(payload['birthDate'] as String) : null) : pet.birthDate, microchip: payload.containsKey('microchip') ? payload['microchip'] as String? : pet.microchip, version: pet.version + 1);
    await store.upsertCachedPet(cached);
  }

  Future<String> queueAllergyCreate(String petId, {required String allergen, String? reaction, required String severity}) async {
    final deviceId = await store.deviceId();
    final allergyId = const Uuid().v4();
    await store.enqueue(PendingSyncEvent(clientEventId: const Uuid().v4(), deviceId: deviceId, entityType: 'Allergy', entityId: allergyId, operation: 'CREATE', version: 1, payload: {'petId': petId, 'allergen': allergen, 'reaction': reaction, 'severity': severity}));
    return allergyId;
  }

  Future<void> queueAllergyDeactivate(String allergyId) async {
    final deviceId = await store.deviceId();
    await store.enqueue(PendingSyncEvent(clientEventId: const Uuid().v4(), deviceId: deviceId, entityType: 'Allergy', entityId: allergyId, operation: 'DEACTIVATE', version: 1, payload: const {}));
  }

  String? _checkpointFromItems(List<dynamic> items) {
    if (items.isEmpty) return null;
    final last = Map<String, dynamic>.from(items.last as Map);
    final createdAt = last['createdAt'];
    final id = last['id'];
    if (createdAt is! String || id is! String) return null;
    final raw = utf8.encode(jsonEncode({'createdAt': createdAt, 'id': id}));
    return base64Url.encode(raw).replaceAll('=', '');
  }

  Future<int> restoreReminderStates(ReminderStateService states) async {
    var cursor = await store.syncCursor();
    var applied = 0;

    while (true) {
      final query = cursor == null ? '/sync/pull?limit=100' : '/sync/pull?limit=100&cursor=${Uri.encodeQueryComponent(cursor)}';
      final page = await api.getObject(query);
      final items = page['items'] as List<dynamic>? ?? const [];
      final latest = <String, Map<String, dynamic>>{};

      for (final raw in items) {
        final event = Map<String, dynamic>.from(raw as Map);
        if ((event['entityType'] as String?)?.toLowerCase() != 'reminderstate') continue;
        final payload = event['payload'];
        if (payload is! Map) continue;
        final map = Map<String, dynamic>.from(payload);
        final reminderId = map['reminderId'];
        final state = map['state'];
        if (reminderId is String && state is Map) latest[reminderId] = Map<String, dynamic>.from(state);
      }

      for (final entry in latest.entries) {
        final state = entry.value;
        if (state['reopened'] == true || (state['completedAt'] == null && state['snoozedUntil'] == null)) {
          await states.applyRemote(entry.key, null);
        } else {
          await states.applyRemote(entry.key, ReminderState.fromJson(state));
        }
        applied++;
      }

      final checkpoint = page['nextCursor'] as String? ?? _checkpointFromItems(items);
      if (checkpoint != null) {
        await store.saveSyncCursor(checkpoint);
        cursor = checkpoint;
      }

      final hasMore = page['hasMore'] == true;
      if (!hasMore || items.isEmpty) break;
    }

    return applied;
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
          conflicts.add(SyncConflict(event: event, reason: response['reason'] as String? ?? 'UNKNOWN_CONFLICT', serverVersion: (response['serverVersion'] as num?)?.toInt()));
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
