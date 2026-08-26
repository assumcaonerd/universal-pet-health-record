import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/offline_store.dart';
import '../models/care_reminder.dart';
import '../models/pet.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.pets});
  final List<Pet> pets;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notifications = NotificationService();
  bool _loading = true;
  List<CareReminder> _items = const [];
  NotificationPreferences _prefs = const NotificationPreferences();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await _notifications.preferences();
    final items = await ReminderService(OfflineStore()).upcoming(widget.pets);
    await _notifications.reschedule(items);
    if (mounted) setState(() { _prefs = prefs; _items = items; _loading = false; });
  }

  Future<void> _savePrefs(NotificationPreferences prefs) async {
    await _notifications.savePreferences(prefs);
    await _notifications.reschedule(_items);
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _settings() async {
    var draft = _prefs;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
      void update(NotificationPreferences value) { draft = value; setSheetState(() {}); }
      return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Preferências de lembrete', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(title: const Text('Vacinas'), value: draft.vaccines, onChanged: (v) => update(NotificationPreferences(vaccines: v, medications: draft.medications, followUps: draft.followUps, advanceHours: draft.advanceHours))),
        SwitchListTile(title: const Text('Medicamentos'), value: draft.medications, onChanged: (v) => update(NotificationPreferences(vaccines: draft.vaccines, medications: v, followUps: draft.followUps, advanceHours: draft.advanceHours))),
        SwitchListTile(title: const Text('Retornos veterinários'), value: draft.followUps, onChanged: (v) => update(NotificationPreferences(vaccines: draft.vaccines, medications: draft.medications, followUps: v, advanceHours: draft.advanceHours))),
        DropdownButtonFormField<int>(value: draft.advanceHours, decoration: const InputDecoration(labelText: 'Avisar com antecedência'), items: const [
          DropdownMenuItem(value: 1, child: Text('1 hora antes')),
          DropdownMenuItem(value: 6, child: Text('6 horas antes')),
          DropdownMenuItem(value: 24, child: Text('1 dia antes')),
          DropdownMenuItem(value: 48, child: Text('2 dias antes')),
          DropdownMenuItem(value: 168, child: Text('7 dias antes')),
        ], onChanged: (v) { if (v != null) update(NotificationPreferences(vaccines: draft.vaccines, medications: draft.medications, followUps: draft.followUps, advanceHours: v)); }),
        const SizedBox(height: 20),
        FilledButton(onPressed: () async { await _savePrefs(draft); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar preferências')),
      ])));
    }));
  }

  String _dateTime(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cuidados e lembretes'), actions: [IconButton(tooltip: 'Preferências', onPressed: _settings, icon: const Icon(Icons.tune))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhum cuidado com data estruturada vence nos próximos 45 dias. Os lembretes são calculados a partir do prontuário salvo no aparelho.', textAlign: TextAlign.center)))
      : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final item = _items[index];
          return Card(child: ListTile(
            leading: CircleAvatar(child: Icon(item.kind == CareReminderKind.vaccine ? Icons.vaccines_outlined : item.kind == CareReminderKind.medication ? Icons.medication_outlined : Icons.event_outlined)),
            title: Text(item.title),
            subtitle: Text('${item.petName} • ${item.overdue ? 'atrasado desde' : 'previsto para'} ${_dateTime(item.dueAt)}${item.detail == null ? '' : '\n${item.detail}'}'),
            isThreeLine: item.detail != null,
            trailing: item.overdue ? const Icon(Icons.priority_high) : null,
          ));
        })),
  );
}
