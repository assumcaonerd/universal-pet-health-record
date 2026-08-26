import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/offline_store.dart';

class ReminderState {
  const ReminderState({this.completedAt, this.snoozedUntil});
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  bool get completed => completedAt != null;

  Map<String, dynamic> toJson() => {'completedAt': completedAt?.toIso8601String(), 'snoozedUntil': snoozedUntil?.toIso8601String()};
  factory ReminderState.fromJson(Map<String, dynamic> json) => ReminderState(
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    snoozedUntil: DateTime.tryParse(json['snoozedUntil'] as String? ?? ''),
  );
}

class ReminderStateService {
  ReminderStateService({FlutterSecureStorage? storage, OfflineStore? offline})
      : _storage = storage ?? const FlutterSecureStorage(),
        _offline = offline ?? OfflineStore();

  final FlutterSecureStorage _storage;
  final OfflineStore _offline;
  static const _key = 'care_reminder_states_v1';

  Future<Map<String, ReminderState>> all() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return decoded.map((key, value) => MapEntry(key, ReminderState.fromJson(Map<String, dynamic>.from(value as Map))));
  }

  Future<void> complete(String reminderId) async {
    final states = await all();
    final state = ReminderState(completedAt: DateTime.now());
    states[reminderId] = state;
    await _save(states);
    await _queue(reminderId, state.toJson());
  }

  Future<void> snooze(String reminderId, Duration duration) async {
    final states = await all();
    final state = ReminderState(snoozedUntil: DateTime.now().add(duration));
    states[reminderId] = state;
    await _save(states);
    await _queue(reminderId, state.toJson());
  }

  Future<void> reopen(String reminderId) async {
    final states = await all();
    states.remove(reminderId);
    await _save(states);
    await _queue(reminderId, {'completedAt': null, 'snoozedUntil': null, 'reopened': true});
  }

  Future<void> applyRemote(String reminderId, ReminderState? state) async {
    final states = await all();
    if (state == null) {
      states.remove(reminderId);
    } else {
      states[reminderId] = state;
    }
    await _save(states);
  }

  Future<void> _queue(String reminderId, Map<String, dynamic> state) async {
    final deviceId = await _offline.deviceId();
    await _offline.enqueue(PendingSyncEvent(
      clientEventId: const Uuid().v4(),
      deviceId: deviceId,
      entityType: 'ReminderState',
      entityId: const Uuid().v4(),
      operation: 'SET',
      version: 1,
      payload: {'reminderId': reminderId, 'state': state},
    ));
  }

  Future<void> _save(Map<String, ReminderState> states) => _storage.write(
    key: _key,
    value: jsonEncode(states.map((key, value) => MapEntry(key, value.toJson()))),
  );
}
