import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/pet.dart';
import 'pet_edit_screen.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key, required this.api, required this.pet});
  final ApiClient api;
  final Pet pet;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _vaccinations = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final vaccinations = await widget.api.getList('/pets/${widget.pet.id}/vaccinations');
      setState(() => _vaccinations = vaccinations);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PetEditScreen(api: widget.api, pet: widget.pet)));
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Excluir pet?'),
      content: Text('Isso removerá ${widget.pet.name} e seus dados vinculados. Esta ação não pode ser desfeita.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.delete('/pets/${widget.pet.id}');
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _date(dynamic value) {
    if (value is! String) return 'Data não informada';
    final parsed = DateTime.tryParse(value);
    return parsed == null ? 'Data não informada' : DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(title: Text(pet.name), actions: [PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _edit(); if (value == 'delete') _delete(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))])]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const CircleAvatar(radius: 30, child: Icon(Icons.pets, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pet.name, style: Theme.of(context).textTheme.headlineSmall), Text([pet.species, if (pet.breed != null) pet.breed].join(' • '))]))]),
            const SizedBox(height: 20),
            _InfoRow(label: 'Microchip', value: pet.microchip ?? 'Não informado'),
            _InfoRow(label: 'Nascimento', value: pet.birthDate == null ? 'Não informado' : DateFormat('dd/MM/yyyy').format(pet.birthDate!.toLocal())),
            _InfoRow(label: 'Versão do cadastro', value: '${pet.version}'),
          ]))),
          const SizedBox(height: 20),
          Text('Carteira de vacinação', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
          else if (_vaccinations.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhuma vacina registrada ainda.')))
          else ..._vaccinations.map((raw) { final vaccine = raw as Map<String, dynamic>; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.vaccines)), title: Text(vaccine['vaccineName'] as String? ?? 'Vacina'), subtitle: Text('Aplicada em ${_date(vaccine['dateAdministered'])}${vaccine['nextDueDate'] != null ? '\nPróxima dose: ${_date(vaccine['nextDueDate'])}' : ''}'), isThreeLine: vaccine['nextDueDate'] != null)); }),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label)), Expanded(child: Text(value, textAlign: TextAlign.end))]));
}
