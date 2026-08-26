import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/clinical_models.dart';
import '../models/pet.dart';

class PendingSyncEvent {
  const PendingSyncEvent({required this.clientEventId, required this.deviceId, required this.entityType, required this.entityId, required this.operation, required this.version, required this.payload});
  final String clientEventId;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String operation;
  final int version;
  final Map<String, dynamic> payload;
  Map<String, dynamic> toJson() => {'clientEventId': clientEventId, 'deviceId': deviceId, 'entityType': entityType, 'entityId': entityId, 'operation': operation, 'version': version, 'payload': payload};
  factory PendingSyncEvent.fromJson(Map<String, dynamic> json) => PendingSyncEvent(clientEventId: json['clientEventId'] as String, deviceId: json['deviceId'] as String, entityType: json['entityType'] as String, entityId: json['entityId'] as String, operation: json['operation'] as String, version: (json['version'] as num).toInt(), payload: Map<String, dynamic>.from(json['payload'] as Map));
}

class ClinicalSnapshot {
  const ClinicalSnapshot({required this.petId, required this.savedAt, required this.vaccinations, required this.prescriptions, required this.allergies, required this.records});
  final String petId;
  final DateTime savedAt;
  final List<Map<String, dynamic>> vaccinations;
  final List<Prescription> prescriptions;
  final List<Allergy> allergies;
  final List<MedicalRecord> records;
  Map<String, dynamic> toJson() => {'petId': petId, 'savedAt': savedAt.toIso8601String(), 'vaccinations': vaccinations, 'prescriptions': prescriptions.map((e) => e.toJson()).toList(), 'allergies': allergies.map((e) => e.toJson()).toList(), 'records': records.map((e) => e.toJson()).toList()};
  factory ClinicalSnapshot.fromJson(Map<String, dynamic> json) => ClinicalSnapshot(petId: json['petId'] as String, savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0), vaccinations: (json['vaccinations'] as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList(), prescriptions: (json['prescriptions'] as List<dynamic>? ?? const []).map((e) => Prescription.fromJson(Map<String, dynamic>.from(e as Map))).toList(), allergies: (json['allergies'] as List<dynamic>? ?? const []).map((e) => Allergy.fromJson(Map<String, dynamic>.from(e as Map))).toList(), records: (json['records'] as List<dynamic>? ?? const []).map((e) => MedicalRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList());
}

class OfflineStore {
  OfflineStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _petsKey = 'offline_pets_v1';
  static const _queueKey = 'offline_sync_queue_v1';
  static const _deviceKey = 'offline_device_id_v1';
  static const _cursorKey = 'offline_sync_cursor_v1';
  static String _clinicalKey(String petId) => 'offline_clinical_v1_$petId';

  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null) return existing;
    final created = const Uuid().v4();
    await _storage.write(key: _deviceKey, value: created);
    return created;
  }

  Future<String?> syncCursor() => _storage.read(key: _cursorKey);
  Future<void> saveSyncCursor(String? cursor) => cursor == null ? _storage.delete(key: _cursorKey) : _storage.write(key: _cursorKey, value: cursor);
  Future<void> resetSyncCursor() => _storage.delete(key: _cursorKey);

  Future<void> clearAccountScopedData() async {
    await Future.wait([
      _storage.delete(key: _petsKey),
      _storage.delete(key: _queueKey),
      _storage.delete(key: _cursorKey),
    ]);
  }

  Future<void> savePets(List<Pet> pets) => _storage.write(key: _petsKey, value: jsonEncode(pets.map((e) => e.toJson()).toList()));

  Future<List<Pet>> loadPets() async {
    final raw = await _storage.read(key: _petsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Pet.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> upsertCachedPet(Pet pet) async {
    final pets = await loadPets();
    final index = pets.indexWhere((p) => p.id == pet.id);
    if (index >= 0) {
      pets[index] = pet;
    } else {
      pets.add(pet);
    }
    await savePets(pets);
  }

  Future<void> saveClinicalSnapshot(ClinicalSnapshot snapshot) => _storage.write(key: _clinicalKey(snapshot.petId), value: jsonEncode(snapshot.toJson()));
  Future<ClinicalSnapshot?> loadClinicalSnapshot(String petId) async { final raw = await _storage.read(key: _clinicalKey(petId)); if (raw == null || raw.isEmpty) return null; return ClinicalSnapshot.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map)); }
  Future<void> clearClinicalSnapshot(String petId) => _storage.delete(key: _clinicalKey(petId));
  Future<List<PendingSyncEvent>> queue() async { final raw = await _storage.read(key: _queueKey); if (raw == null || raw.isEmpty) return const []; final decoded = jsonDecode(raw) as List<dynamic>; return decoded.map((e) => PendingSyncEvent.fromJson(Map<String, dynamic>.from(e as Map))).toList(); }
  Future<void> enqueue(PendingSyncEvent event) async { final items = await queue(); await replaceQueue([...items, event]); }
  Future<void> removeEvent(String clientEventId) async { final items = await queue(); await replaceQueue(items.where((e) => e.clientEventId != clientEventId).toList()); }
  Future<void> replaceEvent(String clientEventId, PendingSyncEvent replacement) async { final items = await queue(); await replaceQueue(items.map((e) => e.clientEventId == clientEventId ? replacement : e).toList()); }
  Future<void> replaceQueue(List<PendingSyncEvent> items) => _storage.write(key: _queueKey, value: jsonEncode(items.map((e) => e.toJson()).toList()));
}
