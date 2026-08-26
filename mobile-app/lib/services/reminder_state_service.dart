import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  ReminderStateService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'care_reminder_states_v1';

  Future<Map<String, ReminderState>> all() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return decoded.map((key, value) => MapEntry(key, ReminderState.fromJson(Map<String, dynamic>.from(value as Map))));
  }

  Future<void> complete(String reminderId) async {
    final states = await all();
    states[reminderId] = ReminderState(completedAt: DateTime.now());
    await _save(states);
  }

  Future<void> snooze(String reminderId, Duration duration) async {
    final states = await all();
    states[reminderId] = ReminderState(snoozedUntil: DateTime.now().add(duration));
    await _save(states);
  }

  Future<void> reopen(String reminderId) async {
    final states = await all();
    states.remove(reminderId);
    await _save(states);
  }

  Future<void> _save(Map<String, ReminderState> states) => _storage.write(
    key: _key,
    value: jsonEncode(states.map((key, value) => MapEntry(key, value.toJson()))),
  );
}
