class Prescription {
  Prescription({required this.id, required this.medication, required this.dosage, required this.frequency, this.duration, this.instructions, required this.prescribedAt});
  final String id;
  final String medication;
  final String dosage;
  final String frequency;
  final String? duration;
  final String? instructions;
  final DateTime prescribedAt;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as String,
        medication: json['medication'] as String? ?? 'Medicamento',
        dosage: json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        duration: json['duration'] as String?,
        instructions: json['instructions'] as String?,
        prescribedAt: DateTime.tryParse(json['prescribedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Allergy {
  Allergy({required this.id, required this.allergen, this.reaction, required this.severity, required this.active, required this.createdAt});
  final String id;
  final String allergen;
  final String? reaction;
  final String severity;
  final bool active;
  final DateTime createdAt;

  factory Allergy.fromJson(Map<String, dynamic> json) => Allergy(
        id: json['id'] as String,
        allergen: json['allergen'] as String? ?? 'Alergia',
        reaction: json['reaction'] as String?,
        severity: json['severity'] as String? ?? 'MODERATE',
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class MedicalRecordVersion {
  MedicalRecordVersion({required this.version, this.diagnosis, this.treatment, this.notes, this.reason, required this.createdAt});
  final int version;
  final String? diagnosis;
  final String? treatment;
  final String? notes;
  final String? reason;
  final DateTime createdAt;

  factory MedicalRecordVersion.fromJson(Map<String, dynamic> json) => MedicalRecordVersion(
        version: json['version'] as int? ?? 1,
        diagnosis: json['diagnosis'] as String?,
        treatment: json['treatment'] as String?,
        notes: json['notes'] as String?,
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class MedicalRecord {
  MedicalRecord({required this.id, required this.type, this.diagnosis, this.treatment, this.notes, required this.occurredAt, required this.currentVersion, required this.versions});
  final String id;
  final String type;
  final String? diagnosis;
  final String? treatment;
  final String? notes;
  final DateTime occurredAt;
  final int currentVersion;
  final List<MedicalRecordVersion> versions;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'Atendimento',
        diagnosis: json['diagnosis'] as String?,
        treatment: json['treatment'] as String?,
        notes: json['notes'] as String?,
        occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        currentVersion: json['currentVersion'] as int? ?? 1,
        versions: (json['versions'] as List<dynamic>? ?? const []).map((e) => MedicalRecordVersion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
