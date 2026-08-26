import 'package:flutter/material.dart';
import '../core/api_client.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _microchip = TextEditingController();
  String _species = 'DOG';
  DateTime? _birthDate;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await widget.api.post('/pets', {
        'name': _name.text.trim(),
        'species': _species,
        if (_breed.text.trim().isNotEmpty) 'breed': _breed.text.trim(),
        if (_microchip.text.trim().isNotEmpty) 'microchip': _microchip.text.trim(),
        if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String(),
      }, authenticated: true);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _species, decoration: const InputDecoration(labelText: 'Espécie'), items: const [
              DropdownMenuItem(value: 'DOG', child: Text('Cachorro')),
              DropdownMenuItem(value: 'CAT', child: Text('Gato')),
              DropdownMenuItem(value: 'BIRD', child: Text('Ave')),
              DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
            ], onChanged: (v) => setState(() => _species = v ?? 'DOG')),
            const SizedBox(height: 16),
            TextFormField(controller: _breed, decoration: const InputDecoration(labelText: 'Raça (opcional)')),
            const SizedBox(height: 16),
            TextFormField(controller: _microchip, decoration: const InputDecoration(labelText: 'Microchip (opcional)')),
            const SizedBox(height: 16),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Nascimento'), subtitle: Text(_birthDate == null ? 'Não informado' : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'), trailing: const Icon(Icons.calendar_month), onTap: _pickDate),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.pets), label: Text(_saving ? 'Salvando...' : 'Cadastrar pet')),
          ],
        ),
      ),
    );
  }
}
