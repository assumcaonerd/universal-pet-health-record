import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/care_reminder.dart';

class NotificationPreferences {
  const NotificationPreferences({this.vaccines = true, this.medications = true, this.followUps = true, this.advanceHours = 24});
  final bool vaccines;
  final bool medications;
  final bool followUps;
  final int advanceHours;

  Map<String, dynamic> toJson() => {'vaccines': vaccines, 'medications': medications, 'followUps': followUps, 'advanceHours': advanceHours};
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => NotificationPreferences(
    vaccines: json['vaccines'] as bool? ?? true,
    medications: json['medications'] as bool? ?? true,
    followUps: json['followUps'] as bool? ?? true,
    advanceHours: (json['advanceHours'] as num?)?.toInt() ?? 24,
  );
}

class NotificationService {
  NotificationService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _prefsKey = 'care_notification_preferences_v1';

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<NotificationPreferences> preferences() async {
    final raw = await _storage.read(key: _prefsKey);
    if (raw == null) return const NotificationPreferences();
    return NotificationPreferences.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> savePreferences(NotificationPreferences prefs) => _storage.write(key: _prefsKey, value: jsonEncode(prefs.toJson()));

  bool _enabled(CareReminder item, NotificationPreferences prefs) {
    return switch (item.kind) {
      CareReminderKind.vaccine => prefs.vaccines,
      CareReminderKind.medication => prefs.medications,
      CareReminderKind.followUp => prefs.followUps,
    };
  }

  Future<void> reschedule(List<CareReminder> reminders) async {
    final prefs = await preferences();
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final item in reminders.take(128)) {
      if (!_enabled(item, prefs)) continue;
      final when = item.dueAt.subtract(Duration(hours: prefs.advanceHours));
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        item.id.hashCode & 0x7fffffff,
        item.petName,
        item.title,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('care_reminders', 'Cuidados do pet', channelDescription: 'Vacinas, medicamentos e retornos veterinários', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${item.petId}|${item.kind.name}|${item.sourceId}',
      );
    }
  }
}
