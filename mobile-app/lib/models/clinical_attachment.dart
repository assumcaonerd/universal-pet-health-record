class ClinicalAttachment {
  const ClinicalAttachment({
    required this.id,
    required this.petId,
    required this.fileName,
    required this.mimeType,
    required this.storageKey,
    required this.sha256,
    required this.sizeBytes,
    required this.createdAt,
    this.medicalRecordId,
  });

  final String id;
  final String petId;
  final String fileName;
  final String mimeType;
  final String storageKey;
  final String sha256;
  final int sizeBytes;
  final DateTime createdAt;
  final String? medicalRecordId;

  factory ClinicalAttachment.fromJson(Map<String, dynamic> json) => ClinicalAttachment(
        id: json['id'] as String,
        petId: json['petId'] as String,
        fileName: json['fileName'] as String,
        mimeType: json['mimeType'] as String,
        storageKey: json['storageKey'] as String,
        sha256: json['sha256'] as String,
        sizeBytes: json['sizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        medicalRecordId: json['medicalRecordId'] as String?,
      );
}
