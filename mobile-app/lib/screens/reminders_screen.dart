import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/offline_store.dart';
import '../models/care_reminder.dart';
import '../models/pet.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.pets});
  final List<Pet> pets;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _loading = true;
  List<CareReminder> _items = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await ReminderService(OfflineStore()).upcoming(widget.pets);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  String _date(DateTime date) => DateFormat('dd/MM/yyyy').format(date.toLocal());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cuidados e lembretes')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhum cuidado com data estruturada vence nos próximos 45 dias. Os lembretes são calculados a partir do prontuário salvo no aparelho.', textAlign: TextAlign.center)))
      : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final item = _items[index];
          return Card(child: ListTile(
            leading: CircleAvatar(child: Icon(item.kind == CareReminderKind.vaccine ? Icons.vaccines_outlined : item.kind == CareReminderKind.medication ? Icons.medication_outlined : Icons.event_outlined)),
            title: Text(item.title),
            subtitle: Text('${item.petName} • ${item.overdue ? 'atrasado desde' : 'previsto para'} ${_date(item.dueAt)}${item.detail == null ? '' : '\n${item.detail}'}'),
            isThreeLine: item.detail != null,
            trailing: item.overdue ? const Icon(Icons.priority_high) : null,
          ));
        })),
  );
}
