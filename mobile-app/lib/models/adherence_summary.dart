class AdherenceEvent {
  const AdherenceEvent({required this.id, required this.scheduledAt, required this.status, this.administeredAt, this.note});
  final String id;
  final DateTime scheduledAt;
  final DateTime? administeredAt;
  final String status;
  final String? note;

  Duration? get delay => administeredAt?.difference(scheduledAt);

  factory AdherenceEvent.fromJson(Map<String, dynamic> json) => AdherenceEvent(
    id: json['id'] as String,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    administeredAt: json['administeredAt'] == null ? null : DateTime.parse(json['administeredAt'] as String),
    status: json['status'] as String,
    note: json['note'] as String?,
  );
}

class AdherenceSummary {
  const AdherenceSummary({required this.prescriptionId, required this.recorded, required this.taken, required this.skipped, required this.events, this.adherencePercent});
  final String prescriptionId;
  final int recorded;
  final int taken;
  final int skipped;
  final double? adherencePercent;
  final List<AdherenceEvent> events;

  int get lateTaken => events.where((e) => e.status == 'TAKEN' && (e.delay?.inMinutes ?? 0) > 30).length;
  int get onTimeTaken => taken - lateTaken;

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) => AdherenceSummary(
    prescriptionId: json['prescriptionId'] as String,
    recorded: (json['recorded'] as num?)?.toInt() ?? 0,
    taken: (json['taken'] as num?)?.toInt() ?? 0,
    skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    adherencePercent: (json['adherencePercent'] as num?)?.toDouble(),
    events: (json['events'] as List<dynamic>? ?? const []).map((e) => AdherenceEvent.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}
