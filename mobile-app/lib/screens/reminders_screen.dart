import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/care_reminder.dart';
import '../models/pet.dart';
import '../services/adherence_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/reminder_state_service.dart';
import 'adherence_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.pets, required this.api});
  final List<Pet> pets;
  final ApiClient api;
  @override State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notifications = NotificationService();
  final ReminderStateService _states = ReminderStateService();
  bool _loading = true;
  List<CareReminder> _items = const [];
  Map<String, ReminderState> _stateMap = const {};
  NotificationPreferences _prefs = const NotificationPreferences();

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final prefs = await _notifications.preferences(); final items = await ReminderService(OfflineStore()).upcoming(widget.pets); final states = await _states.all(); await _notifications.reschedule(items); if (mounted) setState(() { _prefs = prefs; _items = items; _stateMap = states; _loading = false; }); }

  Future<void> _openAdherence(CareReminder item) async {
    if (item.kind != CareReminderKind.medication) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdherenceScreen(api: widget.api, petId: item.petId, prescriptionId: item.sourceId, medication: item.title.split(' • ').first)));
  }

  Future<void> _complete(CareReminder item) async {
    if (item.kind == CareReminderKind.medication) {
      try { await AdherenceService(widget.api).record(item, taken: true); } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível registrar a dose no prontuário: ${e.message}'))); return; }
    }
    await _states.complete(item.id); await _load();
  }

  Future<void> _skip(CareReminder item) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Registrar dose omitida?'), content: TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Observação (opcional)', hintText: 'Ex.: pet recusou o medicamento')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Registrar'))]));
    if (confirmed != true) return;
    try { await AdherenceService(widget.api).record(item, taken: false, note: note.text); await _states.complete(item.id); await _load(); } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível registrar a omissão: ${e.message}'))); }
  }

  Future<void> _reopen(CareReminder item) async { await _states.reopen(item.id); await _load(); }
  Future<void> _snooze(CareReminder item, Duration duration) async { await _states.snooze(item.id, duration); await _load(); }
  Future<void> _savePrefs(NotificationPreferences prefs) async { await _notifications.savePreferences(prefs); await _notifications.reschedule(_items); if (mounted) setState(() => _prefs = prefs); }

  Future<void> _settings() async { var draft = _prefs; await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) { void update(NotificationPreferences value) { draft = value; setSheetState(() {}); } return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Preferências de lembrete', style: Theme.of(context).textTheme.titleLarge), SwitchListTile(title: const Text('Vacinas'), value: draft.vaccines, onChanged: (v) => update(NotificationPreferences(vaccines: v, medications: draft.medications, followUps: draft.followUps, advanceHours: draft.advanceHours))), SwitchListTile(title: const Text('Medicamentos'), value: draft.medications, onChanged: (v) => update(NotificationPreferences(vaccines: draft.vaccines, medications: v, followUps: draft.followUps, advanceHours: draft.advanceHours))), SwitchListTile(title: const Text('Retornos veterinários'), value: draft.followUps, onChanged: (v) => update(NotificationPreferences(vaccines: draft.vaccines, medications: draft.medications, followUps: v, advanceHours: draft.advanceHours))), DropdownButtonFormField<int>(value: draft.advanceHours, decoration: const InputDecoration(labelText: 'Avisar com antecedência'), items: const [DropdownMenuItem(value: 1, child: Text('1 hora antes')), DropdownMenuItem(value: 6, child: Text('6 horas antes')), DropdownMenuItem(value: 24, child: Text('1 dia antes')), DropdownMenuItem(value: 48, child: Text('2 dias antes')), DropdownMenuItem(value: 168, child: Text('7 dias antes'))], onChanged: (v) { if (v != null) update(NotificationPreferences(vaccines: draft.vaccines, medications: draft.medications, followUps: draft.followUps, advanceHours: v)); }), const SizedBox(height: 20), FilledButton(onPressed: () async { await _savePrefs(draft); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar preferências'))]))); })); }

  String _dateTime(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

  @override Widget build(BuildContext context) { final active = _items.where((e) => _stateMap[e.id]?.completed != true).toList(); final completed = _items.where((e) => _stateMap[e.id]?.completed == true).toList(); return Scaffold(appBar: AppBar(title: const Text('Cuidados e lembretes'), actions: [IconButton(tooltip: 'Preferências', onPressed: _settings, icon: const Icon(Icons.tune))]), body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [if (active.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum cuidado pendente com data estruturada nos próximos 45 dias.', textAlign: TextAlign.center))), ...active.map((item) { final state = _stateMap[item.id]; return Card(child: ListTile(onTap: item.kind == CareReminderKind.medication ? () => _openAdherence(item) : null, leading: CircleAvatar(child: Icon(item.kind == CareReminderKind.vaccine ? Icons.vaccines_outlined : item.kind == CareReminderKind.medication ? Icons.medication_outlined : Icons.event_outlined)), title: Text(item.title), subtitle: Text('${item.petName} • ${item.overdue ? 'atrasado desde' : 'previsto para'} ${_dateTime(item.dueAt)}${state?.snoozedUntil == null ? '' : '\nAdiado até ${_dateTime(state!.snoozedUntil!)}'}${item.detail == null ? '' : '\n${item.detail}'}${item.kind == CareReminderKind.medication ? '\nToque para ver a adesão ao tratamento.' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (value) { if (value == 'done') _complete(item); if (value == 'skip') _skip(item); if (value == '1h') _snooze(item, const Duration(hours: 1)); if (value == '6h') _snooze(item, const Duration(hours: 6)); if (value == '1d') _snooze(item, const Duration(days: 1)); }, itemBuilder: (_) => [PopupMenuItem(value: 'done', child: Text(item.kind == CareReminderKind.medication ? 'Marcar dose como tomada' : item.kind == CareReminderKind.followUp ? 'Marcar retorno realizado' : 'Marcar cuidado realizado')), if (item.kind == CareReminderKind.medication) const PopupMenuItem(value: 'skip', child: Text('Registrar dose omitida')), const PopupMenuDivider(), const PopupMenuItem(value: '1h', child: Text('Adiar 1 hora')), const PopupMenuItem(value: '6h', child: Text('Adiar 6 horas')), const PopupMenuItem(value: '1d', child: Text('Adiar 1 dia'))])); }), if (completed.isNotEmpty) ExpansionTile(title: Text('Concluídos (${completed.length})'), children: completed.map((item) => ListTile(onTap: item.kind == CareReminderKind.medication ? () => _openAdherence(item) : null, leading: const Icon(Icons.check_circle_outline), title: Text(item.title), subtitle: Text(item.petName), trailing: TextButton(onPressed: () => _reopen(item), child: const Text('Reabrir')))).toList())]))); }
}
