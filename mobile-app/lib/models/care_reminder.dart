enum CareReminderKind { vaccine, medication, followUp }

class CareReminder {
  const CareReminder({required this.id, required this.petId, required this.petName, required this.kind, required this.title, required this.dueAt, required this.sourceId, this.detail});

  final String id;
  final String petId;
  final String petName;
  final CareReminderKind kind;
  final String title;
  final DateTime dueAt;
  final String sourceId;
  final String? detail;

  bool get overdue => dueAt.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'petName': petName,
        'kind': kind.name,
        'title': title,
        'dueAt': dueAt.toIso8601String(),
        'sourceId': sourceId,
        'detail': detail,
      };

  factory CareReminder.fromJson(Map<String, dynamic> json) => CareReminder(
        id: json['id'] as String,
        petId: json['petId'] as String,
        petName: json['petName'] as String,
        kind: CareReminderKind.values.firstWhere((e) => e.name == json['kind'], orElse: () => CareReminderKind.followUp),
        title: json['title'] as String,
        dueAt: DateTime.parse(json['dueAt'] as String),
        sourceId: json['sourceId'] as String,
        detail: json['detail'] as String?,
      );
}
